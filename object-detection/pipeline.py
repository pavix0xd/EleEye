import gi, sys, logging, re, time, threading, os, pyds
gi.require_version('Gst','1.0')
from gi.repository import GLib, Gst, GObject

# Setting up python logger
logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)
handler = logging.StreamHandler(sys.stdout)
formatter = logging.Formatter("%(asctime)s %(levelname)s: %(message)s")
handler.setFormatter(formatter)
logger.addHandler(handler)

# Global file containing RTSP URIs (one per line)
RTSP_CONFIG_FILE = "rtsp_config.txt"

def load_rtsp_config(file_path: str):
    """
    Loads the RTSP configuration file and returns a set of URIs.
    File structure should be one valid URI per line.
    """
    try:
        with open(file_path, "r") as f:
            uris = {line.strip() for line in f if line.strip()}
        return uris
    except Exception as e:
        logger.error(f"Failed to load config file {file_path}: {e}")
        return set()

def bus_call(bus, message, loop):
    """
    Bus handler to catch EOS, ERROR, and WARNING messages.
    Targets fatal errors from specific elements to safely shut down the pipeline.
    """
    message_type = message.type

    if message_type == Gst.MessageType.EOS:
        logger.info("End of stream reached")
        loop.quit()

    elif message_type == Gst.MessageType.ERROR:
        error, debug = message.parse_error()
        source = message.src.get_name() if message.src else "unknown"
        
        logger.error(f"ERROR from SOURCE: {source}")
        logger.error(f"ERROR MESSAGE: {error.message}")
        logger.error(f"ERROR DEBUG: {debug}")

        if "rtspsrc" in source.lower():
            if error.domain == Gst.ResourceError:
                if error.code == Gst.ResourceError.TIMEOUT:
                    logger.info("[rtspsrc error]: Connection timed out")
                elif error.code == Gst.ResourceError.NOT_FOUND:
                    logger.info("[rtspsrc error]: Connection error (resource not found)")
                elif error.code == Gst.ResourceError.NO_PERMISSION:
                    logger.info("[rtspsrc error]: Authentication error")
                else:
                    logger.error("[rtspsrc error]: Unknown resource error code")
            else:
                if "sdp" in error.message.lower():
                    logger.error("[rtspsrc error]: SDP error detected")
                else:
                    logger.error("[rtspsrc error]: Unhandled error case")
                    loop.quit()

        elif "rtph264depay" in source.lower():
            if ("malformed" in error.message.lower()) or ("depay" in error.message.lower()):
                logger.error("[rtph264parse error]: Issue depayloading RTP packets")
        
        elif "h264parse" in source.lower():
            if "parse" in error.message.lower():
                logger.error("h264parse error: Issue parsing h264 stream")
        
        elif "nvv4l2decoder" in source.lower():
            if ("decode" in error.message.lower()) or ("unsupported" in error.message.lower()):
                logger.error("[nvv4l2decoder error]: Decoding failure detected. Verify stream format or reset the decoder")
        
        elif "nvstreammux" in source.lower():
            if ("dimension" in error.message.lower()) or ("batch" in error.message.lower()):
                logger.error("[nvstreammux error]: Dimension or batch size mismatch")
                loop.quit()
            elif ("sink" in error.message.lower()):
                logger.error("[nvstreammux error]: Issue with requesting or linking sink pads")
                loop.quit()
        
        elif "nvinfer" in source.lower():
            if ("engine" in error.message.lower()) or ("config" in error.message.lower()):
                logger.error("[nvinfer error]: Inference configuration error. Verify TensorRT engine and config file")
                loop.quit()
            elif ("dimension" in error.message.lower()):
                logger.error("[nvinfer error]: Input dimensions mismatch. Check dimensions in nvinfer config and nvstreammux compatibility")
                loop.quit()
        
        loop.quit()
    
    elif message_type == Gst.MessageType.WARNING:
        warning, debug = message.parse_warning()
        source = message.src.get_name() if message.src else "Unknown"
        logger.warning(f"WARNING from SOURCE: {source}")
        logger.warning(f"WARNING MESSAGE: {warning.message}")
        logger.warning(f"WARNING DEBUG: {debug}")

        if "rtspsrc" in source.lower():
            if "latency" in warning.message.lower():
                logger.warning("[rtspsrc warning]: High latency detected")
            elif "fallback" in warning.message.lower():
                logger.warning("[rtspsrc warning]: Transport fallback occurred")
            elif "sdp" in warning.message.lower():
                logger.warning("[rtspsrc warning]: SDP information may be incomplete or incompatible")
        
        elif "rtph264depay" in source.lower():
            if "packet" in warning.message.lower():
                logger.warning("[rtph264depay warning]: Possible RTP packet issues")
            else:
                logger.warning("[rtph264depay warning]: Check for potential issues with depayloading RTP packets")
        
        elif "h264parse" in source.lower():
            if ("header" in warning.message.lower()) or ("config" in warning.message.lower()):
                logger.warning("[h264parse warning]: H264 stream header or configuration data might be missing or delayed")
            else:
                logger.warning("[h264parse warning]: Potential bitstream inconsistencies")
        
        elif "nvv4l2decoder" in source.lower():
            if ("buffer" in warning.message.lower()) or ("drop" in warning.message.lower()):
                logger.warning("[nvv4l2decoder warning]: Minor buffer issues detected")
        
        elif "nvstreammux" in source.lower():
            if ("late" in warning.message.lower()) or ("timing" in warning.message.lower()):
                logger.warning("[nvstreammux warning]: Frame timing issue detected")
        
        elif "nvinfer" in source.lower():
            if ("performance" in warning.message.lower()) or ("delay" in warning.message.lower()):
                logger.warning("[nvinfer warning]: Inference performance might be impacted")
    
    return True

def metadata_probe_callback(pad, info):
    """
    Probe callback for nvinfer's src pad. Extracts object detection metadata
    and sends it to the backend server.
    """
    gst_buffer = info.get_buffer()
    if not gst_buffer:
        logger.warning("Unable to get GstBuffer for inference metadata")
        return Gst.PadProbeReturn.OK

    batch_meta = pyds.gst_buffer_get_nvds_batch_meta(hash(gst_buffer))
    if not batch_meta:
        logger.warning("Unable to get NvDsBatchMeta")
        return Gst.PadProbeReturn.OK

    l_frame = batch_meta.frame_meta_list
    while l_frame is not None:
        frame_meta = pyds.NvDsFrameMeta.cast(l_frame.data)
        frame_num = frame_meta.frame_num
        detections = []
        l_obj = frame_meta.obj_meta_list
        while l_obj is not None:
            obj_meta = pyds.NvDsObjectMeta.cast(l_obj.data)
            if obj_meta.class_id == 0:
                detection = {
                    "frame": frame_num,
                    "object_id": int(obj_meta.object_id),
                    "class_id": int(obj_meta.class_id),
                    "confidence": float(obj_meta.confidence),
                    "bbox": {
                        "left": float(obj_meta.rect_params.left),
                        "top": float(obj_meta.rect_params.top),
                        "width": float(obj_meta.rect_params.width),
                        "height": float(obj_meta.rect_params.height)
                    }
                }
                detections.append(detection)
            try:
                l_obj = l_obj.next
            except StopIteration:
                break

        location_data = None
        l_user_meta = frame_meta.frame_user_meta_list
        while l_user_meta is not None:
            user_meta = pyds.NvDsUserMeta.cast(l_user_meta.data)
            if user_meta.base_meta.meta_type == pyds.NvDsMetaType.NVDS_USER_META:
                location_data = user_meta.user_meta_data
                logger.info(f"Frame {frame_num} location metadata: {location_data}")
                break
            try:
                l_user_meta = l_user_meta.next
            except StopIteration:
                break

        if detections:
            payload = {
                "frame": frame_num,
                "detections": detections,
                "location": location_data
            }
            try:
                logger.info(f"POST sent for frame {frame_num}: Payload {payload}")
            except Exception as e:
                logger.error(f"Error sending POST request: {e}")

        try:
            l_frame = l_frame.next
        except StopIteration:
            break

    return Gst.PadProbeReturn.OK

def on_pad_added(src, new_pad, depay):
    """
    Callback to handle dynamic pads from the rtspsrc element.
    Links new pads from rtspsrc to the static sink pad of rtph264depay.
    """
    sink_pad = depay.get_static_pad("sink")
    if sink_pad.is_linked():
        return
    ret = new_pad.link(sink_pad)
    if ret == Gst.PadLinkReturn.OK:
        logger.info(f"[{src.get_name()}] Successfully linked rtspsrc to rtph264depay")
    else:
        logger.warning(f"[{src.get_name()}] Failed to link pad: {ret}")

def on_sdp_callback(rtspsrc, sdp):
    """
    Callback for the RTSPSRC's ON-SDP signal.
    Extracts GPS metadata from the SDP if present.
    """
    sdp_text = sdp.sdp.as_text()
    lat_match = re.search(r"a=latitude:(\S+)", sdp_text)
    lon_match = re.search(r"a=longitude:(\S+)", sdp_text)
    if lat_match and lon_match:
        latitude = lat_match.group(1)
        longitude = lon_match.group(1)
        # Access the custom attribute set on rtspsrc
        stream_index = getattr(rtspsrc, "stream_index", "unknown")
        logger.info(f"Extracted GPS metadata for stream {stream_index}: lat={latitude}, lon={longitude}")
    else:
        logger.warning("SDP did not contain GPS metadata")

def attach_location_metadata(pad, info):
    """
    Pad probe that attaches location metadata (if available) to each decoded frame.
    """
    buffer = info.get_buffer()
    if not buffer:
        return Gst.PadProbeReturn.OK
    batch_meta = pyds.gst_buffer_get_nvds_batch_meta(hash(buffer))
    if not batch_meta:
        return Gst.PadProbeReturn.OK

    l_frame = batch_meta.frame_meta_list
    while l_frame is not None:
        frame_meta = pyds.NvDsFrameMeta.cast(l_frame.data)
        # Here you could attach additional metadata if needed.
        l_frame = l_frame.next
    return Gst.PadProbeReturn.OK

def rtsp_sub_pipeline(url, sub_pipeline_id):
    """
    Creates a sub-pipeline (as a Gst.Bin) for an RTSP stream.
    Sub-pipeline: rtspsrc -> rtph264depay -> h264parse -> nvv4l2decoder.
    Returns a dictionary containing the sub-pipeline elements.
    """
    sub_pipeline = {}
    rtspsrc = Gst.ElementFactory.make("rtspsrc", f"rtspsrc_{sub_pipeline_id}")
    if not rtspsrc:
        logger.critical("rtspsrc element was not created")
        return None

    # Instead of using set_property for "stream-index", assign a Python attribute.
    rtspsrc.stream_index = sub_pipeline_id

    rtspsrc.set_property("location", url)
    rtspsrc.set_property("is-live", True)
    rtspsrc.set_property("connection-speed", 0)
    rtspsrc.set_property("drop-on-latency", False)
    rtspsrc.connect("pad-added", on_pad_added, None)
    rtspsrc.connect("on-sdp", on_sdp_callback)

    rtph264depay = Gst.ElementFactory.make("rtph264depay", f"rtph264depay_{sub_pipeline_id}")
    if not rtph264depay:
        logger.critical("rtph264depay element was not created")
        return None

    h264parse = Gst.ElementFactory.make("h264parse", f"h264parse_{sub_pipeline_id}")
    if not h264parse:
        logger.critical("h264parse element was not created")
        return None

    nvv4l2decoder = Gst.ElementFactory.make("nvv4l2decoder", f"nvv4l2decoder_{sub_pipeline_id}")
    if not nvv4l2decoder:
        logger.critical("nvv4l2decoder element was not created")
        return None

    h264parse.set_property("config-interval", 1)
    h264parse.set_property("disable-passthrough", True)

    # Attach a pad probe on nvv4l2decoder's src pad to attach location metadata.
    src_pad = nvv4l2decoder.get_static_pad("src")
    if src_pad:
        src_pad.add_probe(Gst.PadProbeType.BUFFER, attach_location_metadata)

    if not rtph264depay.link(h264parse):
        logger.error("Failed to link rtph264depay and h264parse")
    if not h264parse.link(nvv4l2decoder):
        logger.error("Failed to link h264parse and nvv4l2decoder")

    sub_pipeline["rtspsrc"] = rtspsrc
    sub_pipeline["rtph264depay"] = rtph264depay
    sub_pipeline["h264parse"] = h264parse
    sub_pipeline["nvv4l2decoder"] = nvv4l2decoder

    return sub_pipeline

def add_rtsp_stream(pipeline, nvstreammux, rtsp_url, index) -> bool:
    """
    Creates a Gst.Bin for the RTSP sub-pipeline and links it to nvstreammux's dynamic source pads.
    """
    rtsp_bin = Gst.Bin.new(f"rtsp_bin_{index}")
    sub_pipeline = rtsp_sub_pipeline(rtsp_url, index)
    if not sub_pipeline:
        logger.error(f"Failed to create sub-pipeline for {rtsp_url}")
        return False

    for element in sub_pipeline.values():
        rtsp_bin.add(element)

    # Create a ghost pad on the bin that exposes the output from nvv4l2decoder.
    decoder_src_pad = sub_pipeline["nvv4l2decoder"].get_static_pad("src")
    ghost_pad = Gst.GhostPad.new("src", decoder_src_pad)
    rtsp_bin.add_pad(ghost_pad)

    pipeline.add(rtsp_bin)
    rtsp_bin.sync_state_with_parent()

    # Request a sink pad on nvstreammux for this stream.
    sink_pad = nvstreammux.get_request_pad(f"sink_{index}")
    if not sink_pad:
        logger.error(f"Failed to obtain sink pad for stream {index}")
        return False

    ret = ghost_pad.link(sink_pad)
    if ret != Gst.PadLinkReturn.OK:
        logger.error(f"Failed to link stream {index} to nvstreammux")
        return False

    logger.info(f"RTSP stream {rtsp_url} added at index {index}")
    return True

def main():
    """
    Builds the object-detection pipeline.
    Reads RTSP URLs from the configuration file and creates RTSP sub-pipelines accordingly.
    """
    Gst.init(None)
    pipeline = Gst.Pipeline.new("object-detection-pipeline")
    if not pipeline:
        logger.critical("object-detection pipeline was not created")
        sys.exit(1)
    else:
        logger.debug("object-detection pipeline created")

    # Create DeepStream plugin elements.
    nvstreammux = Gst.ElementFactory.make("nvstreammux", "nvidia-batcher")
    if not nvstreammux:
        logger.critical("nvstreammux element was not created")
        sys.exit(1)
    else:
        logger.debug("nvstreammux created")

    nvinfer = Gst.ElementFactory.make("nvinfer", "nvidia-infer")
    if not nvinfer:
        logger.critical("nvinfer element was not created")
        sys.exit(1)
    else:
        logger.debug("nvinfer created")

    fakesink = Gst.ElementFactory.make("fakesink", "fakesink")
    if not fakesink:
        logger.critical("fakesink element was not created")
        sys.exit(1)
    else:
        logger.debug("fakesink created")

    # Set properties for nvstreammux.
    nvstreammux.set_property("width", 640)
    nvstreammux.set_property("height", 480)
    nvstreammux.set_property("batch-size", 1)
    nvstreammux.set_property("live-source", 1)

    # Set property for nvinfer (ensure the file nvinfer_config.txt is in the container or accessible path)
    nvinfer.set_property("config-file-path", "/workspace/nvinfer_config.txt")

    fakesink.set_property("sync", False)
    fakesink.set_property("async", False)

    # Add and link elements.
    pipeline.add(nvstreammux)
    pipeline.add(nvinfer)
    pipeline.add(fakesink)

    if not nvstreammux.link(nvinfer):
        logger.critical("FAILED TO LINK NVSTREAMMUX TO NVINFER")
        sys.exit(1)
    
    if not nvinfer.link(fakesink):
        logger.critical("FAILED TO LINK NVINFER TO FAKESINK")
        sys.exit(1)

    # Add pad probe on fakesink to process inference metadata.
    sink_pad = fakesink.get_static_pad("sink")
    if not sink_pad:
        logger.error("Unable to get sink pad from fakesink")
        sys.exit(1)
    sink_pad.add_probe(Gst.PadProbeType.BUFFER, metadata_probe_callback)

    # Read RTSP URLs from the configuration file.
    rtsp_urls = list(load_rtsp_config(RTSP_CONFIG_FILE))
    if not rtsp_urls:
        logger.error("No RTSP URLs found in configuration file")
        sys.exit(1)

    # Add each RTSP stream (as a sub-pipeline) to the main pipeline.
    for i, url in enumerate(rtsp_urls):
        if not add_rtsp_stream(pipeline, nvstreammux, url, i):
            logger.error(f"Failed to add RTSP stream: {url}")

    # Set up bus and main loop.
    bus = pipeline.get_bus()
    bus.add_signal_watch()
    loop = GLib.MainLoop()
    bus.connect("message", bus_call, loop)

    ret = pipeline.set_state(Gst.State.PLAYING)
    if ret == Gst.StateChangeReturn.FAILURE:
        logger.error("Unable to set the pipeline to the PLAYING state")
        sys.exit(1)

    logger.info("Pipeline running")
    try:
        loop.run()
    except KeyboardInterrupt:
        logger.info("Pipeline interrupted manually")
    finally:
        pipeline.set_state(Gst.State.NULL)

if __name__ == "__main__":
    main()