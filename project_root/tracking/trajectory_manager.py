import json
import os

# ゾーン履歴（ゾーン＋タイムスタンプ）を記録
trajectories = {}

# 座標は描画用のみ
temp_coords = {}

def get_trajectory(track_id):
    return temp_coords.get(track_id, [])

def save_trajectory(extra_filepath: str | None = None):
    """
    常に data/trajectories.json（ZKP用の既存パス）に保存する。
    extra_filepath が指定されているときは、
    そのパスにも同じ内容を追加で保存する。
    """
    canonical_path = "data/trajectories.json"
    os.makedirs(os.path.dirname(canonical_path), exist_ok=True)
    with open(canonical_path, "w") as f:
        json.dump(trajectories, f, indent=2)

    if extra_filepath is not None:
        os.makedirs(os.path.dirname(extra_filepath), exist_ok=True)
        with open(extra_filepath, "w") as f:
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