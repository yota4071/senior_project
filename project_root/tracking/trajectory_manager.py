import json
import os

# ゾーン履歴（ゾーン＋タイムスタンプ）を記録
trajectories = {}

# 座標は描画用のみ
temp_coords = {}

def get_trajectory(track_id):
    return temp_coords.get(track_id, [])

def save_trajectory(filepath="data/trajectories.json"):
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    with open(filepath, "w") as f:
        json.dump(trajectories, f, indent=2)

def update_trajectory(track_id, x, y, zone_name, timestamp):
    if track_id not in temp_coords:
        temp_coords[track_id] = []
    temp_coords[track_id].append((x, y))

    if track_id not in trajectories:
        trajectories[track_id] = []
        last_zone = None
    else:
        last_zone = trajectories[track_id][-1]["zone"] if trajectories[track_id] else None

    if zone_name != last_zone:
        trajectories[track_id].append({
            "zone": zone_name,
            "timestamp": timestamp
        })