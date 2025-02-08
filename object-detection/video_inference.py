from ultralytics import YOLO
import matplotlib.pyplot as plt
import numpy as np
import cv2

# Load the pretrained YOLOv8 model
model = YOLO("yolov8n.pt")

# Load testing video for inference
video_path = ""
cap = cv2.VideoCapture(video_path)

# Get the framerate of the video and the duration of a single frame.
# This will be used to plot the number of detections made every 100
# miliseconds
fps = cap.get(cv2.CAP_PROP_FPS)
frame_duration = 1 / fps

duration_split = 0.1
current_time = 0
start_time = 0.0
detection_count = 0

detection_timestamps = []
detection_counts = []

# Create a named, resizable window and optionally set its initial position
cv2.namedWindow("Video inference test", cv2.WINDOW_NORMAL)
cv2.moveWindow("Video inference test", 0, 0)

while cap.isOpened():
    ret, frame = cap.read()
    if not ret:
        break

    # Run YOLO prediction on current frame
    results = model(frame)

    frame_detection_count = 0
    for box in results[0].boxes:
        coords = box.xyxy.cpu().numpy()[0]
        x1, y1, x2, y2 = map(int, coords)
        confidence = box.conf.cpu().numpy()[0]
        cls = int(box.cls.cpu().numpy()[0])
        label = model.names[cls]
        text = f"{label} {confidence:.2f}"

        # Draw bounding box
        cv2.rectangle(frame, (x1, y1), (x2, y2), (0, 255, 0), 1)
        (text_width, text_height), baseline = cv2.getTextSize(text, cv2.FONT_HERSHEY_SIMPLEX, 0.5, 1)
        cv2.rectangle(frame, (x1, y1 - text_height - baseline),
                      (x1 + text_width, y1), (0, 255, 0), -1)
        cv2.putText(frame, text, (x1, y1 - baseline),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 0, 0), 1, cv2.LINE_AA)
        
        frame_detection_count += 1

    detection_count += frame_detection_count
    current_time += frame_duration

    if (current_time - start_time) >= duration_split:

        detection_timestamps.append(start_time)
        detection_counts.append(detection_count)
        start_time = current_time
        detection_count = 0

    cv2.imshow("Video inference test", frame)

    if cv2.waitKey(1) & 0xFF == ord('q'):
        break

cap.release()
cv2.destroyAllWindows()

plt.figure(figsize=(10,4))
plt.plot(detection_timestamps, detection_counts, marker='o', linestyle='-')
plt.xlabel('Time (s)')
plt.ylabel(f'Detections made every {duration_split} s')
plt.title('Detections made over time')
plt.grid(True)
plt.savefig('detections.png')