import os, subprocess, time
from picamera2 import Picamera2

# Define fifo path for first-in first-out file buffering
# create it if it doesnt exist

fifo_path = "/tmp/video_pipe"

if not os.path.exists(fifo_path):
    os.mkfifo(fifo_path)

# Start separate FFmpeg process to read the H264 stream from the
# FIFO, written into by the Raspberry Pi camera, and serve it over RTSP

ffmpeg_cmd = [
    'ffmpeg',
    '-re',
    '-f', 'h264',
    '-i', fifo_path,
    '-c:v', 'copy',
    '-f', 'rtsp',
    'rtps://0.0.0.0:8554/stream'
]

ffmpeg_process = subprocess.Popen(ffmpeg_cmd)

# Configure the Raspberry Pi camera for H264 encoding 
picam = Picamera2()
video_config = picam.create_video_configuration(encode="h264", raw={})
picam.configure(video_config)

# Set the Raspberry Pi camera's output to the FIFO file for
# writing

with open(fifo_path, "wb") as fifo:
    picam.start_recording(fifo, format="h264")
    picam.start()

    print("RTSP stream available at rtsp://0.0.0.0:8554/stream")