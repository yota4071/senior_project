import json
import sys
from datetime import datetime

# ゾーン名を数値に変換
zone_map = {
    "zone_A": 1,
    "zone_B": 2,
    "zone_C": 3,
    "zone_D": 4
}

# ISO形式 → UNIX秒に変換
def iso_to_unix(timestamp_str):
    return int(datetime.fromisoformat(timestamp_str).timestamp())

# 最新の zone_D 到達者の軌跡を抽出して input.json に変換
def extract_latest_zone_d(file_path, output_path):
    with open(file_path, 'r') as f:
        all_data = json.load(f)

    latest_person = None
    latest_d_time = None

    for person_id, records in all_data.items():
        for idx, entry in enumerate(records):
            if entry["zone"] == "zone_D":
                ts = datetime.fromisoformat(entry["timestamp"])
                if latest_d_time is None or ts > latest_d_time:
                    latest_d_time = ts
                    latest_person = (person_id, records[:idx + 1])

    if latest_person is None:
        print("[!] zone_D に到達した人物がいませんでした。")
        return

    person_id, trajectory = latest_person
    zones = [zone_map[pt["zone"]] for pt in trajectory]
    timestamps = [iso_to_unix(pt["timestamp"]) for pt in trajectory]

    output = {
        "zones": zones,
        "timestamps": timestamps
    }

    with open(output_path, 'w') as f:
        json.dump(output, f, indent=2)

    print(f"[✔] {person_id} のデータを Circom 用に変換しました → {output_path}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: convert.py <input_json> <output_json>")
        sys.exit(1)

    input_json = sys.argv[1]
    output_json = sys.argv[2]

    extract_latest_zone_d(input_json, output_json)