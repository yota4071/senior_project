# detectors/yolo_deepsort.py
from ultralytics import YOLO  
from deep_sort_realtime.deepsort_tracker import DeepSort  # DeepSORTの実装を使っているならこちらも必要

CONF_THRESHOLD = 0.8

def extract_person_boxes(results):
    boxes = []
    for box in results[0].boxes:
        if int(box.cls[0]) == 0:
            conf = float(box.conf[0])
            if conf < CONF_THRESHOLD:
                continue

            x1, y1, x2, y2 = map(int, box.xyxy[0])
            boxes.append(([x1, y1, x2 - x1, y2 - y1], conf, 'person'))
    return boxes

from deep_sort_realtime.deepsort_tracker import DeepSort

class YOLODeepSORTTracker:
    def __init__(self, yolo_model_path):
        self.model = YOLO(yolo_model_path)
        self.model.to("cuda")
        self.tracker = DeepSort()

    def update(self, frame):
        results = self.model(frame)
        person_boxes = extract_person_boxes(results)
        tracks = self.tracker.update_tracks(person_boxes, frame=frame)
        return tracks

    def active_ids(self):
        # deep_sort_realtime の track オブジェクト
        return [track.track_id for track in self.tracker.tracker.tracks if track.is_confirmed()]