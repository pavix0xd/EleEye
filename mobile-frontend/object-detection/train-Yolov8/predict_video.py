import os
from ultralytics import YOLO
import cv2

VIDEOS_DIR = os.path.join('.', 'videos')
MODEL_PATH = os.path.join('.', 'runs', 'detect', 'train', 'weights', 'last.pt')
MODEL = YOLO(MODEL_PATH)
threshold = 0.5

for video_file in os.listdir(VIDEOS_DIR):

    if video_file.endswith('.mp4'):

        VIDEO_PATH = os.path.join(VIDEOS_DIR, video_file)

        print(f'processing {video_file}')

        cap = cv2.VideoCapture(VIDEO_PATH)
        ret, frame = cap.read()

        if ret:
            H, W, _ = frame.shape

        else:
            print(f'could not read video: {video_file}')
            continue

        while ret:

            results = MODEL(frame)[0]

            for result in results.boxes.data.tolist():

                x1, y1, x2, y2, score, class_id = result

                if score > threshold:
                    print(f"Score of {score:.2f}")

            ret, frame = cap.read()

        cap.release()
        print(f'Finished processing {video_file}')


cv2.destroyAllWindows()
print("-------- processing done for all videos --------")
