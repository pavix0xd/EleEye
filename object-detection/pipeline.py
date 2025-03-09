import gi, sys, requests, re, pyds
gi.require_version('Gst','1.0')
from gi.repository import Gst, GObject
from loguru import logger

# Initialize the Gstreamer application, passing no command line arguments
Gst.init(None)

# EleEYE ascii art that is displayed across the project
def eleye_ascii_art():
    print("      @@@@@@@@@@@@@@@  @@     @@@@@@@@@@@@@                                             ")
    print("      @@@@@@@@@@@@@@@  @@     @@@@@@@@@@@@@                                             ")
    print("      @@@@@@@@@@@@@@@ @@@     @@@@@@@@@@@@@                                             ")
    print("      @@@@ @@@@@@@@@@ @@@     @@@@@@           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@       ")
    print("      @@@@@@@@@@@@@@@ @@@     @@@@@@@@@@@      @ _____ _      _______   _______ @       ")
    print("      @@@@@@@@@@@@@@@ @@@@@@  @@@@@@@@@@@      @| ____| | ___| ____\ \ / / ____|@       ")
    print("      @@@@@@@@@@@@@@@         @@@@@@@@@@@      @|  _| | |/ _ \  _|  \ V /|  _|  @       ")
    print("      @@@@@@@@@@@@@@  @@@@@@  @@@@@@           @| |___| |  __/ |___  | | | |___ @       ")
    print("      @@@@@@@@@@      @@@@@   @@@@@@           @|_____|_|\___|_____| |_| |_____|@       ")
    print("      @@@@@      @@    @@@    @@@@@@           @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@       ")
    print("      @@@@      @@@@    @@    @@@@@@@@@@@@@                                             ")
    print("      @@@@@    @@@@@    @@    @@@@@@@@@@@@@@                                            ")
    print("       @@@@@@@@@@@@     @@    @@@@@@@@@@@@@                                             ")
    print("       @@@@@@@@@@                                                                       ")

# bus handler callback, to recieve and read messages from the 
# pipeline bus
def bus_call(bus,message,loop):

    message_type = message.type

    if (message_type == Gst.MessageType.EOS):
        logger.info("End-of-Stream reached")
        loop.quit()

    elif (message_type == Gst.MessageType.ERROR):

        # obtaining error, debug and source information, alongside the message
        error, debug = message.parse_error()
        source = message.src.get_name() if message.src else "Unknown"

        # logging the error source, message and debug statements with a severity of ERROR
        logger.error(f"ERROR from SOURCE: {source}")
        logger.error(f"ERROR MESSAGE: {error.message}")
        logger.error(f"ERROR DEBUG: {debug}")

        # identifying what source element caused the error and handling the element
        # accordingly

        if ("rtspsrc" in source.lower()):

            if (error.domain == Gst.ResourceError):

                if (error.code == Gst.ResourceError.TIMEOUT):
                    logger.info("[rtspsrc error]: Connection timed out")
            
                elif (error.code == Gst.ResourceError.NOT_FOUND):
                    logger.error("[rtspsrc error]: Connection error (resource not found)")
            
                elif (error.code ==  Gst.ResourceError.NO_PERMISSION):
                    logger.error("[rtspsrc error]: Authentication error")
                
                else:

                    logger.error("[rtspsrc error]: Unknown resourc error code")
            
            else:

                if ("sdp" in error.message.lower()):
                    logger.error("[rtspsrc error]: SDP error detected")
                
                else:
                    logger.error("[rtspsrc error]: Unhandled error case.")
            
        

        elif ("rtph264depay" in source.lower()):

            if ("malformed" in error.message.lower() or "depay" in error.message.lower()):
                logger.error("rtph264depay error: Issue depayloading RTP packets")
            
        
        elif ("h264parse" in source.lower()):

            if ("parse" in error.message.lower()):
                logger.error("h264parse error: Issue parsing h264 stream")
        
        elif ("nvv4l2decoder" in source.lower()):

            if ("decode" in error.message.lower() or "unsupported" in error.message.lower()):
                logger.error("nvv4l2decoder error: Decoding failure detected. Verify stream format or reset the decoder")
            
        elif ("nvstreammux" in source.lower()):

            if ("dimension" in error.message.lower() or "batch" in error.message.lower()):
                logger.error("nvstreammux error: Dimension or batch-size mismatch. Check resolution settings and parameters")
            
            elif ("sink" in error.message.lower()):
                logger.error("nvstreammux error: Issue with requesting or linking sink pads")
            
        elif ("nvinfer" in source.lower()):

            if ("engine" in error.message.lower() or "config" in error.message.lower()):
                logger.error("nvinfer error: Inference configuration error. Verify your TensorRT engine and config file")
            
            elif ("dimension" in error.message.lower()):
                logger("nvinfer error: Input dimensions mismatch. Check the dimensions in your config file and from nvstreammux")
        
    
    elif (message_type == Gst.MessageType.WARNING):

        warning, debug = message.parse_warning()
        source = message.src.get_name() if message.src else "Unknown"

        logger.warning(f"WARNING from SOURCE: {source}")
        logger.warning(f"WARNING MESSAGE: {warning.message}")
        logger.warning(f"WARNING DEBUG: {debug}")

        
        # Handling warnings for all elements in the pipeline
        if ("rtspsrc" in source.lower()):

            if ("latency" in warning.message.lower()):
                logger.warning("rtspsrc warning: High latency detected")
            
            elif ("fallback" in warning.message.lower()):
                logger.warning("rtspsrc warning: Transport fallback occured")
            
            elif ("sdp" in warning.message.lower()):
                logger.warning("rtspsrc warning: SDP information may be incomplete or incompatible")
            
        
        elif ("rtph264depay" in source.lower()):

            if ("packet" in warning.message.lower()):
                logger.warning("rtph264depay warning: Possible RTP packet issues")

            else:
                logger.warning("rtph264depay warning: Check for potential issues with depayloading RTP packets")
            
        
        elif ("h264parse" in source.lower()):

            if ("header" in warning.message.lower() or "config" in warning.message.lower()):
                logger.warning("h264parse warning: H264 stream header or configuration data might be missing or delayed")
            
            else:
                logger.warning("h264parse wanrning: Potential bitstream inconsistencies")
        
        elif ("nvv4l2decoder" in source.lower()):

            if ("buffer" in warning.message.lower() or "drop" in warning.message.lower()):
                logger.warning("nvv4l2decoder warning: Minor buffer issues detected")
            
        
        elif ("nvstreammux" in source.lower()):

            if ("late" in warning.message.lower() or "timing" in warning.message.lower()):
                logger.warning("nvstreammux warning: Frame timing issue detected")
        
        elif ("nvinfer" in source.lower()):

            if ("performance" in warning.message.lower() or "delay" in warning.message.lower()):
                logger.warning("nvinfer warning: Inference performance might be impacted.")

def metadata_probe_callback(pad, info):

    gst_buffer = info.get_buffer()

    if not gst_buffer:
        logger.warning("Unable to get GstBuffer for inference metadata")
        return Gst.PadProbeReturn.OK
    
    batch_meta = pyds.gst_buffer_get_nvds_batch_meta(hash(gst_buffer))
    
    if not batch_meta:
        logger.warning("Unable to get NvDsBatchMeta")
        return Gst.PadProbeReturn.OK
    
    l_frame = batch_meta.frame_meta_list

    while l_frame:

        frame_meta = pyds.NvDsFrameMeta.cast(l_frame.data)
        frame_num = frame_meta.frame_num
        detections = []

        l_obj = frame_meta.obj_meta_list

        while l_obj:

            obj_meta = pyds.NvDsObjectMeta.cast(l_obj.data)

            if obj_meta.class_id == 0:

                detection = {
                    "frame" : frame_num,
                    "object_id" : int(obj_meta.object_id),
                    "class_id" : int(obj_meta.class_id),
                    "confidence" : float(obj_meta.confidence),
                    "bbox" : {
                        "left" : float(obj_meta.rect_params.left),
                        "top" : float(obj_meta.rect_params.top),
                        "width" : float(obj_meta.rect_params.width),
                        "height" : float(obj_meta.rect_params.height)

                    }
                }

                detections.append(detection)
            
            try:
                l_obj = l_obj.next
            except StopIteration:
                break
        
        l_user_meta = frame_meta.frame_user_meta_list
        while l_user_meta:

            user_meta = pyds.NvDsUserMeta.cast(l_user_meta.data)
            if user_meta.base_meta.meta_type == pyds.NvDsMetaType.NVDS_USER_META:

                gps_data = user_meta.user_meta_data
                logger.info(f"Frame {frame_num} location metadata: {gps_data}")
            
            try:
                l_user_meta = l_user_meta.next
            
            except StopIteration:
                break

        if detections:
            
            payload = {"frame" : frame_num, "detections" : detections, "location":l_user_meta}


            # --TODO: change backend URL to production server --
            try:
                response = requests.post("backend-url", json=payload, timeout=1)
                logger.info(f"POST sent for frame {frame_num} : Status {response.status_code}")
            except Exception as e:
                logger.error(f"Error sending POST request: {e}")
        
        try:
            l_frame = l_frame.next
        except StopIteration:
            break
        
    return Gst.PadProbeReturn.OK

def on_pad_added(src, new_pad, depay):

    """
    Gstreamer callback to handle rtspsrc's dynamic sink pads, which
    may be removed or produce no output if the stream has latency or
    disconnects. 
    """

    sink_pad = depay.get_static_pad("sink")

    if sink_pad.is_linked(): return

    ret = new_pad.link(sink_pad)

    if ret == Gst.PadLinkReturn.OK:
        logger.info(f"[{src.get_name()}] Successfully linked rtspsrc to rtph264depay")

    else:
        logger.warning(f"[{src.get_name()}] Failed to link pad: {ret}")


stream_metadata = {}
def on_sdp_callback(rtspsrc, sdp):

    sdp_text = sdp.sdp.as_text()

    lat_match = re.search(r"a=latitude:(\S+)", sdp_text)
    lon_match = re.search(r"a=longitude:(\S+)", sdp_text)

    if lat_match and lon_match:

        latitude = lat_match.group(1)
        longitude = lon_match.group(1)
    
        # setting a temporary unique key. Idealy a unique key for the 
        # RTSP stream should be the RTSP URI or designated stream ID
        key = rtspsrc.get_property("location")

        stream_metadata[key] = {"latitude" : latitude, "longitude" : longitude}

        logger.info(f"Extracted metadata for stream {key} : {stream_metadata[key]}")


def attach_location_metadata(pad, info, key):

    buffer = info.get_buffer()

    if not buffer:
        return Gst.PadProbeReturn.OK

    batch_meta = pyds.gst_buffer_get_nvds_batch_meta(hash(buffer))

    if not batch_meta:
        return Gst.PadProbeReturn.OK


    frame_meta_list = batch_meta.frame_meta_list

    while frame_meta_list:

        frame_meta = pyds.NvDsFrameMeta.cast(frame_meta_list.data)
        stream_id = frame_meta.pad_id
        gps_data = stream_metadata.get(stream_id, None)

        if gps_data:
            user_meta = pyds.nvds_acquire_user_meta_from_pool(batch_meta)
            user_meta.user_meta_data = gps_data
            user_meta.base_meta.meta_type = pyds.NvDsMetaType.NVDS_USER_META
            pyds.nvds_add_user_meta_to_frame(frame_meta, user_meta)

        
        try:
            frame_meta_list = frame_meta_list.next
        
        except StopIteration:
            break
    
    return Gst.PadProbeReturn.OK


def rtsp_sub_pipeline(url, sub_pipeline_id):

    """
    Creates a sub-pipeline for each rtsp stream
    Returns a dictionary containing the sub-pipeline elements

    rtspsrc -> rtph264depay -> h264parse -> nvv4l2decoder
    """

    sub_pipeline = {}

    """
    Attempts to create all elements of the sub_pipeline. if atleast one
    fails, the function is exited and returns None. One sub_pipeline not
    being built does not compromise the entire main pipeline. 
    """
    rtspsrc = Gst.ElementFactory.make("rtspsrc",f"rtspsrc_{sub_pipeline_id}")
    if not rtspsrc:
        logger.critical("rtspsrc element was not created")
        return
    else:
        logger.info("rtspsrc element created")


    rtph264depay = Gst.ElementFactory.make("rtph264depay",f"rtph264depay_{sub_pipeline_id}")
    if not rtph264depay:
        logger.critical("rtph264depay element was not created")
        return
    else:
        logger.info("rtph264depay element created")


    h264parse = Gst.ElementFactory.make("h264parse",f"h264parse_{sub_pipeline_id}")
    if not h264parse:
        logger.critical("h264parse element was not created")
        return
    else:
        logger.info("h264parse element created")
    
    nvv4l2decoder = Gst.ElementFactory.make("nvv4l2decoder",f"nvv4l2decoder_{sub_pipeline_id}")
    if not nvv4l2decoder:
        logger.critical("nvv4l2decoder element was not created")
        return
    else:
        logger.info("nvv4l2decoder element was created")
    
    # if all elements are created successfully, their properties are added
    rtspsrc.set_property("location",url) # rtsp url, set to bogus value for now
    rtspsrc.set_property("user-id","")
    rtspsrc.set_property("user-pw","")
    rtspsrc.set_property("is-live",True)
    rtspsrc.set_property("connection-speed",0) #default of 0, indicating an unknown network speed
    rtspsrc.set_property("drop-on-latency",False)
    rtspsrc.connect("pad-added", on_pad_added, None)
    rtspsrc.connect("on-sdp", on_sdp_callback)

    h264parse.set_property("config-interval",1)
    h264parse.set_property("disable-passthrough",True)

    # Attaching pad probe to the src pad of nvv4l2decoder, so latitude
    # and longitude data remain on each decoded frame before batching
    src_pad = nvv4l2decoder.get_static_pad("src")
    src_pad.add_probe(Gst.PadProbeType.BUFFER, attach_location_metadata, None)

    # Link the static elements (rtph264depay -> h264parse -> nvv4l2decoder)

    if not rtph264depay.link(h264parse):
        logger.error("Failed to link rtph264depay and h264parse")
    
    if not h264parse.link(nvv4l2decoder):
        logger.error("Failed to link h264parse and nvv4ldecoder")
    
    # adding the elements to the dictionary and returning it
    sub_pipeline["rtspsrc"] = rtspsrc
    sub_pipeline["rtph264depay"] = rtph264depay
    sub_pipeline["h264parse"] = h264parse
    sub_pipeline["nvv4l2decoder"] = nvv4l2decoder

    return sub_pipeline

def add_rtsp_stream(pipeline, nvstreammux, rtsp_url, index):

    """
    Creates Gst.Bin for the RTSP sub-pipeline and links it to
    nvstreammux's dynamic source pads
    """   

    rtsp_bin = Gst.Bin.new(f"rtsp_bin_{index}")

    sub_pipeline = rtsp_sub_pipeline(rtsp_url, index)

    if not sub_pipeline:
        logger.error(f"Failed to create sub-pipeline for {rtsp_url}")
        return False

    for element in sub_pipeline.values():
        rtsp_bin.add(element)
    
    # Create a ghost pad on the bin that exposes the output from nvv4l2decoder
    decoder_src_pad = sub_pipeline["nvv4l2decoder"].get_static_pad("src")
    ghost_pad = Gst.GhostPad.new("src", decoder_src_pad)
    rtsp_bin.add_pad(ghost_pad)

    # Add the bin to the main pipeline
    pipeline.add(rtsp_bin)
    rtsp_bin.sync_state_with_parent()

    # Request a sink pad on nvstreammux for this new stream
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

    eleye_ascii_art()

    """
    Creating object-detection pipeline. logging on critical level and 
    halting the entire program if the pipeline cannot be built
    """
    pipeline = Gst.Pipeline.new("object-detection-pipeline")
    if not pipeline:
        logger.critical("object-detection pipeline was not created")
        sys.exit(1)
    else:
        logger.info("object detection pipeline created")

    """
    Creating top-level Nvidia Deepstream plugin elements. logging on critical
    level and halting the entire program if the elements cannot be created
    """
    nvstreammux = Gst.ElementFactory.make("nvstreammux","nvidia-batcher")
    if not nvstreammux:
        logger.critical("nvstreammux element was not created")
        sys.exit(1)
    else:
        logger.info("nvstreammux was created")

    nvinfer = Gst.ElementFactory.make("nvinfer","nvidia-infer")
    if not nvinfer:
        logger.critical("nvinfer element was not created")
        sys.exit(1)
    else:
        logger.info("nvinfer element was created")

    fakesink = Gst.ElementFactory.make("fakesink","fakesink")
    if not fakesink:
        logger.critical("fakesink element was not created")
        sys.exit(1)
    else:
        logger.info("fakesink element was created")


    """
    Setting necessary properties for all top-level Nvidia Deepstream plugin
    elements. 
    """
    nvstreammux.set_property("width",640)
    nvstreammux.set_property("height",480)
    nvstreammux.set_property("batch-size",1)
    nvstreammux.set_property("live-source",1)

    nvinfer.set_property("config-file-path","path/to/inference-configuration")

    fakesink.set_property("sync",False)
    fakesink.set_property("async",False)

    # adding sink pad probe to fakesink, in order to retrieve inference
    # metadata and user-defined location and latitude metadata

    # adding elements to the pipeline
    pipeline.add(nvstreammux)
    pipeline.add(nvinfer)
    pipeline.add(fakesink)

    # linking all elements in the pipeline together
    if not nvstreammux.link(nvinfer):
        logger.critical("FAILED TO LINK NVSTREAMMUX TO NVINFER")
        sys.exit(1)
    
    if not nvinfer.link(fakesink):
        logger.critical("FAILED TO LINK NVINFER TO FAKESINK FOR PROBING")
        sys.exit(1)

    # set sink pad probe of fakesink element (dummy element)
    sink_pad = fakesink.get_static_pad("sink")

    if not sink_pad:
        logger.error("Unable to get sink pad from fakesink")
        sys.exit(1)
    
    sink_pad.add_probe(Gst.PadProbeType.BUFFER, metadata_probe_callback)
    
    # Adding RTSP streams to the main pipeline

    # -- TODO: dont add them as lists, maybe use a configuration file of some sort
    rtsp_urls = [""]

    for i, url in enumerate(rtsp_urls):
        add_rtsp_stream(pipeline=pipeline, nvstreammux=nvstreammux, rtsp_url=url, index=i)
    

    # Set up bus and main loop.
    bus = pipeline.get_bus()
    bus.add_signal_watch()
    loop = GObject.MainLoop()

    # add bus_call handler for messages from the bus
    bus.connect("message", bus_call, loop)

    # Finally, start the pipeline
    ret = pipeline.set_state(Gst.State.PLAYING)

    if (ret == Gst.StateChangeReturn.FAILURE):
        logger.error("Unable to set the pipeline to the playing state")
        sys.exit(1)
    
    logger.info("Pipeline running")

    try:
        loop.run()
    
    except KeyboardInterrupt:
        logger.info("Pipeline interrupted manually")
    
    finally:
        pipeline.set_state(Gst.State.NULL)