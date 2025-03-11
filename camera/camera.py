import time, errno, sys, subprocess, signal, os, gc, psutil, socket, logging
from picamera2 import Picamera2, FfmpegOutput


# Configuring top level logger, which uses Python's built in
# logger
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S"
)
logger = logging.getLogger(__name__)


def ffmpeg_error_handler(error):
    
    logger.error(f"[FFmpeg Error handler], Error : {error}")


    if isinstance(error, BrokenPipeError):

        logger.info("[FFmpeg Error handler] Detected BrokenPipeError - FFmpeg likely crashed")
        # -- TODO: restart FFmpeg pipeline --


    elif isinstance(error, OSError):

        if (error.errno == errno.EPIPE):

            logger.info("[FFmpeg Error Handler] EPIPE (broken pipe)")
            # -- TODO: restart FFmpeg --
        
        else:

            logger.info(f"[FFmpeg Error Handler] OSError with errno={error.errno}")
            # -- TODO: restart FFmpeg --
    
    else:

        logger.info("[FFmpeg Error Handler] Unhandled exception type, forcing camera pipeline restart")
        # -- TODO: restart the camera pipeline --

# -- Part of the offline functionality
def check_connection(host="0.0.0.0", port=53, timeout=3) -> bool:

    """
    Returns True if an internet connection is available
    """

    try:
        socket.create_connection((host,port), timeout=timeout)
        return True
    
    except OSError:
        return False


# --- Recovery functions ---
def kill_conflicting_processes(device='/dev/video0'):

    """
    Find and kill any processes currently using the specified camera
    device. 

    :param device: Path to the camera device node
    """

    logger.info("Hunting down conflicting processes")

    try:
        output = subprocess.check_output(["lsof",device]).decode("utf-8")
    
    except subprocess.CalledProcessError:
        logger.info(f"No processes currently using {device}.")
        return
    
    lines = output.strip().split("\n")

    if len(lines) <= 1:
        logger.info(f"No process found using {device}")
        return

    for line in lines[1:]:

        parts = line.split()

        if len(parts) < 2: continue # malformed lines

        pid_str = parts[1]

        # make sure this current process is not killed
        if pid_str == str(os.getpid()): continue

        try:

            pid = int(pid_str)

            logger.info(f"Killing conflicting process {pid} using {device}")
            os.kill(pid, signal.SIGTERM)


        except ValueError: pass

        except ProcessLookupError: pass

        except PermissionError:
            logger.warning(f"Permission denied trying to kill conflicting PID {pid_str}")

def free_memory():

    """
    Attempt to free up memory by forcing garbage collection and dropping
    caches. 
    """

    logger.info("[Recovery] Attempting to free memory")
    collected = gc.collect()
    logger.info(f"[Recovery] Garbage collection complete: collected {collected} objects")

    mem = psutil.virtual_memory()
    logger.info(f"[Recovery] memory usage before cache drop : {mem.percent}% used, {mem.available / (1024 * 1024):.2f} MB available")


    try:
        os.system("sync")
        os.system("echo 3 | sudo tee /proc/sys/vm/drop_caches")
        logger.info("[Recovery] successfully dropped file system caches")
    
    except Exception as e:
        logger.info("[Recovery] Failed to drop caches")
    
    mem = psutil.virtual_memory()
    logger.info(f"Memory usage after cache drop: {mem.percent}% used, {mem.available / (1024 * 1024):.2f} MB available")

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
            
            if free_mb > 100:
                break
            time.sleep(2)
        
        logger.info("[Recovery] Sufficient disk space available. Restarting camera pipeline")
        restart_recording(picam, ffmpeg_output)
    
    except Exception as e:
        logger.error(f"[Recovery] Exception while handling disk full : {e}")

def handle_file_overflow(picam: Picamera2, ffmpeg_output: FfmpegOutput, e):

    logger.error(f"[Recovery] File table overflow : {e}")

    try:
        logger.info("[Recovery] Restarting camera pipeline to clean up file descriptors")
        restart_recording(picam, ffmpeg_output)
    
    except Exception as e:
        logger.error(f"[Recovery] Exception while handling file table overflow : {e}")


# --- FFmpeg output creation ---
def create_ffmpeg_output() -> FfmpegOutput:

    ffmpeg_command = "-f rtsp rtsp://0.0.0.0:8554/stream"
    ffmpeg_output = FfmpegOutput(ffmpeg_command, audio=False)
    ffmpeg_output.error_callback = ffmpeg_error_handler
    return ffmpeg_output

def create_ffmpeg_output_file(file_path: str) -> FfmpegOutput:

    """
    Create an FfmpegOutput that writes to a local file
    """
    ffmepg_command = f"-f mp4 -y {file_path}"
    ffmepg_output = FfmpegOutput(ffmepg_command, audio=False)
    return FfmpegOutput

# --- Camera Initialization Functions ---
def start_camera(max_tries=3, config_params=None) -> tuple[Picamera2, FfmpegOutput]:


    # If the recursive retries did not work, the camera is in an unrepairable
    # state, and must be shutdown. 
    if (max_tries == 0):
        logger.critical("[Recovery]: Could not repair camera pipeline. Shutting down")
        sys.exit(1)


    try:
        picamera = Picamera2()
        
        if not config_params:
            config_params = picamera.create_video_configuration(
                encode="h264",
                main={"size": (640,480)},
                controls={"FrameRate" : 30}
            )
        
        picamera.configure(config_params)
        ffmpeg_output = create_ffmpeg_output()
        return picamera, ffmpeg_output


    except OSError as e:
        
        # No such device OS Error, such an error is usually unrecoverable 
        # as there is no Camera device / sensor to read from. This should
        # kill the script. 
        if (e.errno == errno.ENODEV):
            logger.critical(f"[Camera initialization error] : {e}")
            sys.exit(1)

        # Although very unlikely, if other processes are using the Raspberry Pi 
        # camera, other than this script, an OS error of EBUSY will be raised. 
        # the kill_conflicting_processes hunts down conflicting processes so the resource
        # becomes available for the script, and tries to start the camera again. 
        elif (e.errno == errno.EBUSY):
            logger.error(f"[Camera initialization error], Device or resource busy : {e}")
            kill_conflicting_processes()
            return start_camera(max_tries-1, config_params)
        

        # If there is no memory to allocate camera buffers, this OS level
        # error may occur. Recovery involves freeing up memory by removing 
        # uneeded processes. if this doesnt work, the process stops. 
        elif (e.errno == errno.ENOMEM):
            logger.error(f"[Camera initialization error], Out of memory : {e}")
            free_memory()
            return start_camera(max_tries-1, config_params)

        # Configuration parameters passed to the camera may be invalid 
        # or unsupported, causing an OS level error. To recover, use the 
        # default configuration and log a warning. 
        elif (e.errno == errno.EINVAL):
            video_config = Picamera2.create_video_configuration(encode="h264")
            picamera.configure(video_config)
        
        # Low-level I/O error while initializing. Could possibly be related to 
        # hardware or driver communication issues. A few attempts to re-initialize
        # after a few seconds might work, but this type of error is typically 
        # unrecoverable
        elif (e.errno == errno.EIO):
            logger.error(f"[Camera initialization error], I/O error while initializing : {e}")
            time.sleep(2)
            return start_camera(max_tries-1, config_params)

        # If none of the errors are handled explicitly, it is logged, but 
        # a retry is still done. 
        else:
            logger.critical(f"[Camera initialization error], Error : {e}")
            return start_camera(max_tries-1, config_params)

    except RuntimeError as re:

        runtime_error = str(re).lower()

        # Any buffer related error during initialization due to 
        # memory resources or hefty video stream could cause this 
        # error. Attempt to reduce the video stream quality or free
        # resources
        if ("buffer" in runtime_error):

            logger.error("[Camera initialization error] Buffer related issue detected. Attempting to free memory and reduce video stream quality")
            free_memory()
            config_params["main"]["size"] = (480,480)
            config_params["controls"]["FrameRate"] = 15
            return start_camera(max_tries-1, config_params)
        

        # If none of the runtime errors are handled explicitly, it is logged but
        # a retry is still done. 
        else:
            logger.critical(f"[Camera initialization error], Unrecoverable runtime error: {re}")
            return start_camera(max_tries-1, config_params)

def start_file_recording(file_path: str, max_tries=3, config_params=None) -> tuple[Picamera2, FfmpegOutput]:

    """
    Start the camera with an output directed to a file (offline mode)
    """

    if (max_tries == 0):

        logger.critical("[Recovery] Could not start the file recording. Shutting down")
        sys.exit(1)
    
    try:

        picamera = Picamera2()
        if not config_params:

            config_params = picamera.create_video_configuration(
                encode="h264",
                main={"size" : (640,480)},
                controls={"FrameRate" : 30}
            )

            picamera.configure(config_params)
            file_output = create_ffmpeg_output_file(file_path)
            return picamera, file_output
    
    except Exception as e:
        logger.error(f"[File recording error]: {e}")
        return start_file_recording(file_path, max_tries-1, config_params)

# --- Mode functions --
def live_mode(picam: Picamera2, ffmpeg_output: FfmpegOutput):

    """
    Start Live RTSP streaming
    """

    logger.info("[Live mode] Starting live RTSP stream")
    picam.star()
    picam.start_recording(ffmpeg_output, format="h264")

    while True:

        if not check_connection():
            logger.warning("[Live mode] Internet connection lost. Switching to offline mode")
            picam.stop_recording()
            picam.stop()
            break
        
        time.sleep(1)

def offline_mode(picam: Picamera2, 
                 file_output: FfmpegOutput, 
                 file_path: str,
                 offline_timeout=300):
    
    """
    Record to a file for offline buffering.

    :param offline_timeout: maximum seconds to buffer
    """

    start_time = time.time()
    logger.info("[Offline Mode] Starting file recording mode")
    picam.start()
    picam.start_recording(file_output, format="h264")

    while True:

        if check_connection():

            elapsed = time.time() - start_time()
            logger.info(f"[Offline Mode] Internet returned after {elapsed:.2f} seconds")
            picam.stop_recording()
            picam.stop()

            if elapsed < offline_timeout:
                logger.info("[Offline Mode] Replaying buffered footage to RTSP stream")
            
            else:
                logger.info("[Offline Mode] Buffer exceeded timeout. Discarding stored footage")
                stream_buffer_to_rtsp(file_path)

                try:
                    os.remove(file_path)
                
                except Exception as e:
                    logger.error(f"[Offline Mode] Error deleting file: {e}")
            
            break
        
        if ((time.time() - start_time) > offline_timeout):

            logger.info("[Offline Mode] Offline timeout reached. Stopping file recording and discarding buffer")
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
    Re-stream the buffered file through RTSP.
    This is a placeholder that calls FFmpeg via subprocess
    """

    logger.info(f"[Stream buffer] Streaming stored file {file_path} to RTSP")

    command = [
        "ffmpeg",
        "-re",
        "-i", file_path,
        "-c", "copy",
        "-f", "rtsp",
        "rtsp://0.0.0.0:8554/stream"
    ]

    try:
        subprocess.run(command, check=True)
    
    except Exception as e:
        logger.error(f"[Stream Buffer] Error streaming buffer: {e}")

# --- Ffmpeg and camera pipeline restart functions --
def restart_recording(picamera: Picamera2, ffmpeg_output: FfmpegOutput):

    logger.warning("[Recovery] Restarting camera pipeline")
    picamera.stop_recording()
    picamera.stop()

    # temporary wait
    time.sleep(2)
    
    picamera.start()
    picamera.start_recording(ffmpeg_output, format="h264")

def restart_ffmpeg_output(picamera: Picamera2, ffmepg_output: FfmpegOutput):

    logger.warning("[Recovery] Restarting FFmpeg process")

    picamera.stop_recording()
    picamera.stop()
    ffmepg_output.stop()

    # Give FFmpeg a moment to terminate the process
    time.sleep(2)
    ffmepg_output.start()

    picamera.start_recording(ffmepg_output, format="h264")
    picamera.start()

    logger.info("[Recovery] FFmpeg restarted sucessfully")

def mainloop():

    OFFLINE_BUFFER_FILE = "offline_buffer.mp4"
    OFFLINE_TIMEOUT = 400 # in seconds

    while True:

        # configuring and retrieving the Picam (Picamera2
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


        except RuntimeError as e:

            error_message = str(e).lower()
            logger.error(f"[Mainloop] Runtime error : {error_message}")

            if ("camera not found" in error_message) or ("not found" in error_message):

                # A camera being disconnected during runtime or not being 
                # available at the start of the mainloop is irrecoverable. 
                # The Pi will log the error and close the script.
                logger.critical(f"[Mainloop] Camera physically disconnected or not detected.")
                sys.exit(1)


            elif ("buffers" in error_message) or ("mmal error" in error_message) or ("encoder" in error_message):
                logger.error(f"[Mainloop] Encoder issue detected, restarting camera")
                restart_recording(picam, ffmpeg_output)
            
            else:
                logger.error("[Mainloop] Unhandled runtime error; attempting recovery")
                restart_recording(picam, ffmpeg_output)

        except OSError as e:

            logger.error(f"[Mainloop] OSError : {error_message}")

            if (e.errno == errno.EPIPE):
                logger.error(f"FFmpeg pipe error, restarting subproces...")
                restart_ffmpeg_output(picam,ffmpeg_output)
            
            elif (e.errno == errno.ENOSPC):
                logger.error(f"[Mainloop] Disk is full : {e}")
                handle_disk_full(picam,ffmpeg_output, e)
            
            # cleanup file descriptors
            elif ((e.errno == errno.ENFILE) or (e.errno == errno.EMFILE)):
                logger.error(f"File table overflow : {e}")
                handle_file_overflow(picam, ffmpeg_output, e)
            
            # The camera is disconnected during mainloop run. This is an irrecoverable
            # error, and the script is shutdown
            elif (e.errno == errno.ENODEV):
                logger.critical(f"[Mainloop] No such device, Camera device disconnected or unavailable : {e}")
                sys.exit(1)
            
            elif (e.errno == errno.ENOMEM):
                logger.error(f"[Mainloop] Insufficient memory : {e}")
                free_memory()
            
            else:
                logger.error("[Mainloop] Unhandled OS Error; attempting full pipeline restart")
        
        except MemoryError as e:
            logger.error(f"[Mainloop] Memory exhaustion : {e}")        
            free_memory()
            restart_recording(picam, ffmpeg_output)
        
        except (ConnectionError) as e:
            logger.error(f"[Mainloop] Network related error : {e}")
            restart_ffmpeg_output(picam, ffmpeg_output)
        
        
        time.sleep(2)
        logger.info("[Mainloop] Restarting camera pipeline")

mainloop()