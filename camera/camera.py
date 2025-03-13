import time, errno, sys, subprocess, signal, os, gc, psutil, socket, logging
from picamera2 import Picamera2
from picamera2.outputs import FfmpegOutput
from picamera2.encoders import H264Encoder

# Configure top-level logger using Python's built-in logger.
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S"
)
logger = logging.getLogger(__name__)

# --- FFmpeg error handler callback ---

def ffmpeg_error_handler(error):

    logger.error(f"[FFmpeg Error handler], Error : {error}")
    
    if isinstance(error, BrokenPipeError):
        logger.info("[FFmpeg Error handler] Detected BrokenPipeError - FFmpeg likely crashed")
        # TODO: restart FFmpeg pipeline

    elif isinstance(error, OSError):
        if error.errno == errno.EPIPE:
            logger.info("[FFmpeg Error Handler] EPIPE (broken pipe)")
            # TODO: restart FFmpeg

        else:
            logger.info(f"[FFmpeg Error Handler] OSError with errno={error.errno}")
            # TODO: restart FFmpeg
    else:
        logger.info("[FFmpeg Error Handler] Unhandled exception type, forcing camera pipeline restart")
        # TODO: restart the camera pipeline


# --- Recovery functions ---

def check_connection(host="0.0.0.0", port=54, timeout=3) -> bool:
    """Returns True if an internet connection is available,
    checks if theres a connection on port 54, which is the default
    port using for the RTSP stream
    """

    try:
        socket.create_connection((host, port), timeout=timeout)
        return True
    
    except OSError:
        return False

def kill_conflicting_processes(device='/dev/video0'):

    """Find and kill any processes using the specified camera device."""

    logger.info("Hunting down conflicting processes")

    try:
        output = subprocess.check_output(["lsof", device]).decode("utf-8")

    except subprocess.CalledProcessError:
        logger.info(f"No processes currently using {device}.")
        return
    
    lines = output.strip().split("\n")

    # Prevents the current process which is attempting to use the device
    # from being killed
    if len(lines) <= 1:
        logger.info(f"No process found using {device}")
        return
    
    for line in lines[1:]:

        parts = line.split()
        if len(parts) < 2: 
            continue

        pid_str = parts[1]
        if pid_str == str(os.getpid()): 
            continue

        try:
            pid = int(pid_str)
            logger.info(f"Killing conflicting process {pid} using {device}")
            os.kill(pid, signal.SIGTERM)

        except (ValueError, ProcessLookupError):
            pass

        except PermissionError:
            logger.warning(f"Permission denied trying to kill conflicting PID {pid_str}")

def free_memory():
    """Attempt to free up memory by forcing garbage collection and dropping caches."""

    logger.info("[Recovery] Attempting to free memory")
    collected = gc.collect()

    logger.info(f"[Recovery] Garbage collection complete: collected {collected} objects")

    mem = psutil.virtual_memory()
    logger.info(f"[Recovery] Memory before cache drop: {mem.percent}% used, {mem.available / (1024 * 1024):.2f} MB available")

    try:
        os.system("sync")
        os.system("echo 3 | sudo tee /proc/sys/vm/drop_caches")
        logger.info("[Recovery] Successfully dropped file system caches")

    except Exception as e:
        logger.info("[Recovery] Failed to drop caches")

    mem = psutil.virtual_memory()
    logger.info(f"Memory after cache drop: {mem.percent}% used, {mem.available / (1024 * 1024):.2f} MB available")
    time.sleep(2)

def handle_disk_full(picam: Picamera2, ffmpeg_output: FfmpegOutput, e):
    logger.info("[Recovery] Attempting to clear disk")
    try:

        try:
            picam.stop_recording()

        except Exception:
            pass

        try:
            picam.stop()

        except Exception:
            pass

        try:
            ffmpeg_output.stop()
            
        except Exception:
            pass

        logger.info("[Recovery] Recording stopped due to full disk. Attempting to free disk space")
        while True:
            disk_usage = psutil.disk_usage("/")
            free_mb = disk_usage.free() / (1024 * 1024)

            logger.info(f"[Recovery] Free disk space: {free_mb:.2f} MB")

            if free_mb > 100: break

            time.sleep(2)

        logger.info("[Recovery] Sufficient disk space available. Restarting camera pipeline")
        restart_recording(picam, ffmpeg_output)

    except Exception as e:
        logger.error(f"[Recovery] Exception while handling disk full: {e}")

def handle_file_overflow(picam: Picamera2, ffmpeg_output: FfmpegOutput, e):

    logger.error(f"[Recovery] File table overflow: {e}")

    try:
        logger.info("[Recovery] Restarting camera pipeline to clean up file descriptors")
        restart_recording(picam, ffmpeg_output)

    except Exception as e:
        logger.error(f"[Recovery] Exception while handling file table overflow: {e}")

# --- Location metadata functions ---
def read_location_metadata(file_path: str):
    """
    Read latitude and longitude from the configuration file.
    The file should contain latitude on the first line and longitude on the second.
    """
    try:
        with open(file_path, 'r') as f:

            lines = f.readlines()

            if len(lines) != 2:
                raise ValueError("Configuration file must contain exactly two lines (latitude and longitude)")
            
            latitude = float(lines[0].strip())
            longitude = float(lines[1].strip())
            logger.info(f"Location metadata read: latitude={latitude}, longitude={longitude}")

            return latitude, longitude
        
    except Exception as e:
        logger.error(f"Failed to read configuration file: {e}")
        return None

# --- FFmpeg Output Creation ---

def create_ffmpeg_output() -> FfmpegOutput:
    """
    Create an FfmpegOutput for live RTSP streaming.
    """

    BASE_URL = "rtsp://192.168.1.8:8554/test"

    # Read location metadata from the file
    lat, lon = read_location_metadata("location.txt")

    if lat and lon:
        RTSP_URL = f"{BASE_URL}?lat={lat}&lon={lon}"
    else:
        RTSP_URL = BASE_URL

    ffmpeg_command = f"-rtsp_transport tcp -f rtsp {RTSP_URL}"
    ffmpeg_output = FfmpegOutput(ffmpeg_command, audio=False)
    ffmpeg_output.error_callback = ffmpeg_error_handler
    return ffmpeg_output


def create_ffmpeg_output_file(file_path: str) -> FfmpegOutput:
    """
    Create an FfmpegOutput for offline file recording.
    Location metadata is not needed in this mode.
    Instead, after recording, we will push the file to MediaMTX RTSP server
    which has this location metadata attached via query parameters
    """
    ffmpeg_command = f"-f h264 -y {file_path}"
    ffmpeg_output = FfmpegOutput(ffmpeg_command, audio=False)
    return ffmpeg_output

# --- Camera Initialization Functions ---

def start_camera(max_tries=3, config_params=None) -> tuple[Picamera2, FfmpegOutput]:

    if max_tries == 0:
        logger.critical("[Recovery]: Could not repair camera pipeline. Shutting down")
        sys.exit(1)

    try:
        picamera = Picamera2()
        if not config_params:
            config_params = picamera.create_video_configuration(
                encode="h264",
                main={"size": (640, 480)},
                controls={"FrameRate": 30}
            )

        picamera.configure(config_params)
        ffmpeg_output = create_ffmpeg_output()
        return picamera, ffmpeg_output
    
    except OSError as e:

        # If the device is not recognized, this would be an irrecoverable 
        # fatal error. The camera could have been damaged or removed when in 
        # the production environment. To preserve the camera, the script is killed. 
        if e.errno == errno.ENODEV:
            logger.critical(f"[Camera initialization error]: {e}")
            sys.exit(1)

        # if, for whatever reason, another process is also using the camera device
        # which is not supposed to happen, the conflicting process is killed so the 
        # device is solely used for initialization and usage of the camera.
        elif e.errno == errno.EBUSY:
            logger.error(f"[Camera initialization error] Device or resource busy: {e}")
            kill_conflicting_processes()
            return start_camera(max_tries-1, config_params)
        
        # if the raspberry Pi runs out of memory during initialization, a free_memory 
        # recovery function is run in an attempt to free some memory from the raspberry pi.
        elif e.errno == errno.ENOMEM:
            logger.error(f"[Camera initialization error] Out of memory: {e}")
            free_memory()
            return start_camera(max_tries-1, config_params)
        
        elif e.errno == errno.EINVAL:
            video_config = Picamera2.create_video_configuration(encode="h264")
            picamera.configure(video_config)

        elif e.errno == errno.EIO:
            logger.error(f"[Camera initialization error] I/O error while initializing: {e}")
            time.sleep(2)
            return start_camera(max_tries-1, config_params)
        
        else:
            logger.critical(f"[Camera initialization error] Error: {e}")
            return start_camera(max_tries-1, config_params)
        
    except RuntimeError as re:

        runtime_error = str(re).lower()

        if "buffer" in runtime_error:
            logger.error("[Camera initialization error] Buffer related issue detected. Freeing memory and reducing quality")
            free_memory()
            config_params["main"]["size"] = (480, 480)
            config_params["controls"]["FrameRate"] = 15
            return start_camera(max_tries-1, config_params)
        
        else:
            logger.critical(f"[Camera initialization error] Unrecoverable runtime error: {re}")
            return start_camera(max_tries-1, config_params)

def start_file_recording(file_path: str, max_tries=3, config_params=None) -> tuple[Picamera2, FfmpegOutput]:

    if max_tries == 0:
        logger.critical("[Recovery] Could not start file recording. Shutting down")
        sys.exit(1)

    try:

        picamera = Picamera2()
        if not config_params:
            config_params = picamera.create_video_configuration(
                encode="h264",
                main={"size": (640, 480)},
                controls={"FrameRate": 30}
            )
        picamera.configure(config_params)
        file_output = create_ffmpeg_output_file(file_path)
        return picamera, file_output
    
    except Exception as e:
        logger.error(f"[File recording error]: {e}")
        return start_file_recording(file_path, max_tries-1, config_params)

# --- Mode Functions ---

def live_mode(picam: Picamera2, ffmpeg_output: FfmpegOutput):

    logger.info("[Live mode] Starting live RTSP stream")
    picam.start()
    encoder = H264Encoder()
    picam.start_recording(encoder, ffmpeg_output)

    while True:
        if not check_connection():
            logger.warning("[Live mode] Internet connection lost. Switching to offline mode")
            picam.stop_recording()
            picam.stop()
            break
        time.sleep(1)

def offline_mode(picam: Picamera2, file_output: FfmpegOutput, file_path: str, offline_timeout=300):

    start_time_val = time.time()
    logger.info("[Offline Mode] Starting file recording mode")

    picam.start()
    encoder = H264Encoder()
    picam.start_recording(encoder, file_output)

    while True:

        if check_connection():
            elapsed = time.time() - start_time_val
            logger.info(f"[Offline Mode] Internet returned after {elapsed:.2f} seconds")
            picam.stop_recording()
            picam.stop()

            if elapsed < offline_timeout:
                logger.info("[Offline Mode] Replaying buffered footage to RTSP stream")
                stream_buffer_to_rtsp(file_path)

            else:
                logger.info("[Offline Mode] Buffer exceeded timeout. Discarding stored footage")

                try:
                    os.remove(file_path)

                except Exception as e:
                    logger.error(f"[Offline Mode] Error deleting file: {e}")
            break

        if (time.time() - start_time_val) > offline_timeout:

            logger.info("[Offline Mode] Offline timeout reached. Stopping recording and discarding buffer")
            picam.stop_recording()
            picam.stop()

            try:
                os.remove(file_path)

            except Exception as e:
                logger.error(f"[Offline Mode] Error deleting file: {e}")

            break

        time.sleep(1)

def stream_buffer_to_rtsp(file_path: str):

    """
    Function that streams the buffer video accumulated in the offline mode, back to the RTSP
    URL (MediaMTX), with location query parameters attached. 
    """

    logger.info(f"[Stream buffer] Streaming stored file {file_path} to RTSP")

    command = [
        "ffmpeg",
        "-re",
        "-i", file_path,
        "-c", "copy",
        "-rtsp_transport", "tcp",
        "-f", "rtsp",
        "rtsp://192.168.1.8:8554/stream"
    ]

    try:
        subprocess.run(command, check=True)

    except Exception as e:
        logger.error(f"[Stream Buffer] Error streaming buffer: {e}")

# --- Restart Functions ---

def restart_recording(picamera: Picamera2, ffmpeg_output: FfmpegOutput):

    logger.warning("[Recovery] Restarting camera pipeline")

    picamera.stop_recording()
    picamera.stop()

    time.sleep(2)

    picamera.start()
    encoder = H264Encoder()
    picamera.start_recording(encoder, ffmpeg_output)

def restart_ffmpeg_output(picamera: Picamera2, ffmpeg_output: FfmpegOutput):

    logger.warning("[Recovery] Restarting FFmpeg process")

    picamera.stop_recording()
    picamera.stop()
    ffmpeg_output.stop()

    time.sleep(2)

    ffmpeg_output.start()
    encoder = H264Encoder()
    picamera.start_recording(encoder, ffmpeg_output)
    picamera.start()

    logger.info("[Recovery] FFmpeg restarted successfully")

# --- Main Loop ---
def mainloop():

    OFFLINE_BUFFER_FILE = "offline_buffer.h264"
    OFFLINE_TIMEOUT = 400

    while True:

        try:

            if check_connection():
                logger.info("[Mainloop] Internet available. Starting live RTSP stream")
                picam, ffmpeg_output = start_camera()
                live_mode(picam, ffmpeg_output)

            else:
                logger.warning("[Mainloop] Internet not available. Switching to offline mode")
                picam, file_output = start_file_recording(OFFLINE_BUFFER_FILE)
                offline_mode(picam, file_output, OFFLINE_BUFFER_FILE, OFFLINE_TIMEOUT)

            time.sleep(2)


        # Exception handling during the mainloop run. The same exceptions that were handled in initialization
        # are also handled in the mainloop. 
        except RuntimeError as e:

            error_message = str(e).lower()
            logger.error(f"[Mainloop] Runtime error: {error_message}")

            if ("camera not found" in error_message) or ("not found" in error_message):
                logger.critical("[Mainloop] Camera physically disconnected or not detected.")
                sys.exit(1)

            elif ("buffers" in error_message) or ("mmal error" in error_message) or ("encoder" in error_message):

                logger.error("[Mainloop] Encoder issue detected, restarting camera")
                restart_recording(picam, ffmpeg_output)

            else:
                logger.error("[Mainloop] Unhandled runtime error; attempting recovery")
                restart_recording(picam, ffmpeg_output)


        except OSError as e:

            logger.error(f"[Mainloop] OSError: {e}")

            if e.errno == errno.EPIPE:
                logger.error("FFmpeg pipe error, restarting subprocess...")
                restart_ffmpeg_output(picam, ffmpeg_output)


            elif e.errno == errno.ENOSPC:
                logger.error(f"[Mainloop] Disk is full: {e}")
                handle_disk_full(picam, ffmpeg_output, e)


            elif e.errno in (errno.ENFILE, errno.EMFILE):
                logger.error(f"File table overflow: {e}")
                handle_file_overflow(picam, ffmpeg_output, e)


            elif e.errno == errno.ENODEV:
                logger.critical(f"[Mainloop] No such device, camera disconnected: {e}")
                sys.exit(1)


            elif e.errno == errno.ENOMEM:
                logger.error(f"[Mainloop] Insufficient memory: {e}")
                free_memory()


            else:
                logger.error("[Mainloop] Unhandled OS Error; attempting full pipeline restart")


        except MemoryError as e:
            logger.error(f"[Mainloop] Memory exhaustion: {e}")
            free_memory()
            restart_recording(picam, ffmpeg_output)

        except ConnectionError as e:
            logger.error(f"[Mainloop] Network related error: {e}")
            restart_ffmpeg_output(picam, ffmpeg_output)

        time.sleep(2)

if __name__ == "__main__":
    mainloop()