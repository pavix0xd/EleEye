#!/bin/bash

# Configuration
LOGFILE="/var/log/eleye_startup.log"
MAX_LOG_SIZE=1048576
LOGTAG="eleye_startup"

MAX_MEDIAMTX_RESTARTS=3
MAX_CAMERA_RESTARTS=3
MAX_SERVER_RESTARTS=3

mediamtx_restart_count=0
camera_restart_count=0
server_restart_count=0

rotate_logs() {
    if [ -f "$LOGFILE" ]; then
        filesize=$(stat -c%s "$LOGFILE")
        if [ "$filesize" -ge "$MAX_LOG_SIZE" ]; then
            timestamp=$(date '+%Y%m%d%H%M%S')
            mv "$LOGFILE" "$LOGFILE.$timestamp"
            touch "$LOGFILE"
            logger -t "$LOGTAG" "Log rotated: $LOGFILE.$timestamp"
        fi
    fi
}

log() {
    rotate_logs
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%dT%H:%M:%S%z')
    
    local json_log
    json_log=$(printf '{"timestamp" : "%s", "level" : "%s", "message" : "%s"}' "$timestamp" "$level" "$message" | tr -d '\n')
    
    echo "$json_log" >> "$LOGFILE"
    logger -t "$LOGTAG" "$level: $message"
}

start_mediamtx() {
    log "INFO" "Starting MediaMTX"
    setsid ./mediamtx &
    mediamtx_pid=$!
    log "INFO" "MediaMTX started with PID $mediamtx_pid"
}

start_camera() {
    log "INFO" "Starting python camera script"
    setsid myenv/bin/python3 camera.py &
    camera_pid=$!
    log "INFO" "Python camera script started with PID $camera_pid"
}

start_server() {
    log "INFO" "Starting python HTTP web Server script"
    setsid myenv/bin/python3 server.py &
    server_pid=$!
    log "INFO" "HTTP Server process started with PID $server_pid"
}

cleanup() {
    log "INFO" "Cleaning up"
    if kill -0 "$mediamtx_pid" 2>/dev/null; then
        log "INFO" "Killing MediaMTX process group"
        kill -TERM -"$mediamtx_pid"
    fi

    if kill -0 "$camera_pid" 2>/dev/null; then
        log "INFO" "Killing Python camera script process group"
        kill -TERM -"$camera_pid"
    fi

    if kill -0 "$server_pid" 2>/dev/null; then
        log "INFO" "Killing HTTP Server process group"
        kill -TERM -"$server_pid"
    fi
    exit 1
}

restart_services() {
    log "INFO" "SIGHUP received: Restarting services..."

    if kill -0 "$mediamtx_pid" 2>/dev/null; then
        log "INFO" "Stopping MediaMTX (PID: $mediamtx_pid)"
        kill -TERM -"$mediamtx_pid"
    fi

    if kill -0 "$camera_pid" 2>/dev/null; then
        log "INFO" "Stopping Camera process (PID: $camera_pid)"
        kill -TERM -"$camera_pid"
    fi

    if kill -0 "$server_pid" 2>/dev/null; then
        log "INFO" "Stopping HTTP Server process (PID: $server_pid)"
        kill -TERM -"$server_pid"
    fi

    sleep 2

    mediamtx_restart_count=0
    camera_restart_count=0
    server_restart_count=0

    start_mediamtx
    sleep 2
    start_camera
    sleep 2
    start_server
}

trap cleanup SIGINT SIGTERM
trap restart_services SIGHUP

# Initial startup
start_mediamtx
sleep 2
start_camera
sleep 2
start_server

while true; do
    wait -n

    if ! kill -0 "$mediamtx_pid" 2>/dev/null; then
        log "CRITICAL" "MediaMTX process ($mediamtx_pid) died."
        mediamtx_restart_count=$((mediamtx_restart_count+1))
        if [ "$mediamtx_restart_count" -gt "$MAX_MEDIAMTX_RESTARTS" ]; then
            log "CRITICAL" "Exceeded maximum MediaMTX restart attempts ($MAX_MEDIAMTX_RESTARTS). Terminating other processes and exiting."
            kill -TERM -"$camera_pid"
            kill -TERM -"$server_pid"
            exit 1
        fi
        log "INFO" "Restarting MediaMTX (attempt $mediamtx_restart_count)..."
        start_mediamtx
    fi

    if ! kill -0 "$camera_pid" 2>/dev/null; then
        log "CRITICAL" "Camera process ($camera_pid) died."
        camera_restart_count=$((camera_restart_count+1))
        if [ "$camera_restart_count" -gt "$MAX_CAMERA_RESTARTS" ]; then
            log "CRITICAL" "Exceeded maximum camera restart attempts ($MAX_CAMERA_RESTARTS). Terminating other processes and exiting."
            kill -TERM -"$mediamtx_pid"
            kill -TERM -"$server_pid"
            exit 1
        fi
        log "INFO" "Restarting Python camera script (attempt $camera_restart_count)..."
        start_camera
    fi

    if ! kill -0 "$server_pid" 2>/dev/null; then
        log "CRITICAL" "HTTP Server process ($server_pid) died."
        server_restart_count=$((server_restart_count+1))
        if [ "$server_restart_count" -gt "$MAX_SERVER_RESTARTS" ]; then
            log "CRITICAL" "Exceeded maximum HTTP Server restart attempts ($MAX_SERVER_RESTARTS). Terminating other processes and exiting."
            kill -TERM -"$mediamtx_pid"
            kill -TERM -"$camera_pid"
            exit 1
        fi
        log "INFO" "Restarting HTTP Server process (attempt $server_restart_count)..."
        start_server
    fi
done