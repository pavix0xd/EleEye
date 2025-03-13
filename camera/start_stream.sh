#!/bin/bash

# Sets the Maximum number of restarts for MediaMTX
MAX_RESTARTS=3
restart_count=0

start_mediamtx()
{
    echo "Starting MediaMTX"
    ./mediamtx & mediamtx_pid=$!
    echo "MediaMTX started with PID $mediamtx_pid"
}

start_mediamtx

sleep 3

echo "Starting python script"
python3 camera.py & 
python_pid=$!
echo "Python script started with PID $python_pid"

cleanup()
{
    echo "Cleaning up"
    if kill -0 "$mediamtx_pid" 2>/dev/null; then
        kill "$mediamtx_pid"
    fi

    if kill -0 "$python_pid" 2>/dev/null; then
        kill "$python_pid"
    fi

    exit 1
}

trap cleanup SIGINT SIGTERM

while true; do

    if ! kill -0 "$mediamtx_pid" 2>/dev/null; then
        echo "MediaMTX process ($mediamtx_pid) died."
        restart_count=$((restart_count+1))

        if [ "$restart_count" -gt "$MAX_RESTARTS" ]; then
            echo "Exceeded maximum restart attempts ($MAX_RESTARTS). Terminating python script and exiting"
            kill "$python_pid"
            exit 1
        fi

        echo "Attempting restart $restart_count of MediaMTX. . ."
        start_mediamtx
    fi

    if ! kill -0 "$python_pid" 2>/dev/null; then
        echo "Python script ($python_pid) has stopped. Exiting monitoring loop"
        exit 0
    
    fi
    sleep 5

done