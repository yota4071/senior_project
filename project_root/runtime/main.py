import cv2
import time
import argparse
from datetime import datetime

from detectors.yolo_deepsort import YOLODeepSORTTracker
from tracking.trajectory_manager import update_trajectory, get_trajectory, save_trajectory


def build_grid_zones(width: int, height: int, cols: int, rows: int):
    """画面を cols×rows に均等分割したZONESを生成"""
    cell_w = width // cols
    cell_h = height // rows

    zones = {}
    for r in range(rows):
        for c in range(cols):
            x1 = c * cell_w
            y1 = r * cell_h
            # 端は端数吸収
            x2 = (c + 1) * cell_w if c < cols - 1 else width
            y2 = (r + 1) * cell_h if r < rows - 1 else height
            zones[f"zone_{r}_{c}"] = ((x1, y1), (x2, y2))
    return zones


def get_zone(zones, x, y):
    """座標(x,y)が属するゾーン名を返す（なければNone）"""
    for name, ((x1, y1), (x2, y2)) in zones.items():
        if x1 <= x < x2 and y1 <= y < y2:
            return name
    return None


def draw_zones(frame, zones, thickness=1):
    """ゾーン枠と名前を描画"""
    grid_color = (170, 170, 170)
    for zone_name, ((x1, y1), (x2, y2)) in zones.items():
        cv2.rectangle(frame, (x1, y1), (x2, y2), grid_color, thickness)
        cv2.putText(frame, zone_name, (x1 + 5, y1 + 18),
                    cv2.FONT_HERSHEY_SIMPLEX, 0.5, grid_color, 1, cv2.LINE_AA)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--camera", type=int, default=0)
    parser.add_argument("--width", type=int, default=640)
    parser.add_argument("--height", type=int, default=480)
    parser.add_argument("--cols", type=int, default=3)  # 横分割（今の構成：3）
    parser.add_argument("--rows", type=int, default=4)  # 縦分割（今の構成：4）
    parser.add_argument("--trial", type=str, default=None)  # 保存名
    parser.add_argument("--model", type=str, default="models/yolov8n.pt")
    parser.add_argument("--foot_mode", type=str, default="bottom",
                        choices=["bottom", "lower20"],
                        help="bottom: bboxの下端中心 / lower20: bbox下20%位置（足元が隠れる環境で安定しやすい）")
    parser.add_argument("--show_traj", action="store_true", help="軌跡線を表示する")
    args = parser.parse_args()

    trial_name = args.trial or datetime.now().strftime("%Y%m%d_%H%M%S")
    print(f"=== Trial: {trial_name} | Grid: {args.cols}x{args.rows} | Foot: {args.foot_mode} ===")

    cap = cv2.VideoCapture(args.camera)
    cap.set(cv2.CAP_PROP_FRAME_WIDTH, args.width)
    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, args.height)

    if not cap.isOpened():
        print("カメラが開けませんでした")
        return

    # 1フレーム読み、実際のサイズ確定
    ret, frame = cap.read()
    if not ret:
        print("初期フレームの取得に失敗しました")
        return

    H, W = frame.shape[:2]
    zones = build_grid_zones(W, H, args.cols, args.rows)

    tracker = YOLODeepSORTTracker(args.model)

    start_time = time.time()
    frame_count = 0
    fps_min = 9999.0

    try:
        while True:
            ret, frame = cap.read()
            if not ret:
                break

            # 1) ゾーン描画
            draw_zones(frame, zones, thickness=1)

            # 2) トラッキング更新
            tracks = tracker.update(frame)

            # 3) 追跡結果を処理（確定トラックのみ）
            for track in tracks:
                if not track.is_confirmed():
                    continue

                track_id = track.track_id
                x1, y1, x2, y2 = map(int, track.to_ltrb())

                # --- foot point の取り方（環境に応じて切替） ---
                foot_x = int((x1 + x2) / 2)
                if args.foot_mode == "bottom":
                    foot_y = y2
                else:
                    # bboxの下20%付近（机で足が隠れる・座位が混じるとき安定しやすい）
                    foot_y = int(y2 - 0.2 * (y2 - y1))

                timestamp = datetime.now().isoformat()
                zone_name = get_zone(zones, foot_x, foot_y)

                update_trajectory(f"person_{track_id}", foot_x, foot_y, zone_name, timestamp)

                # bbox描画
                cv2.rectangle(frame, (x1, y1), (x2, y2), (255, 255, 0), 2)
                cv2.circle(frame, (foot_x, foot_y), 4, (255, 0, 0), -1)
                cv2.putText(frame, f"ID: {track_id}", (x1, y1 - 10),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.6, (0, 255, 0), 2)

            # 4) 軌跡描画（オプション）
            if args.show_traj:
                for tid in tracker.active_ids():
                    traj = get_trajectory(f"person_{tid}")
                    for i in range(1, len(traj)):
                        cv2.line(frame, traj[i - 1], traj[i], (255, 0, 255), 2)

            # 5) FPS
            frame_count += 1
            elapsed = time.time() - start_time
            fps = frame_count / max(elapsed, 1e-6)
            fps_min = min(fps_min, fps)
            cv2.putText(frame, f"FPS(avg): {fps:.2f}", (10, 30),
                        cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 255), 2)

            cv2.imshow("YOLO + DeepSORT Tracking", frame)

            key = cv2.waitKey(1) & 0xFF
            if key == ord("q"):
                break

    except KeyboardInterrupt:
        print("Ctrl+C で終了しました")

    finally:
        cap.release()

        save_trajectory(filename=f"data/trajectories_{trial_name}.json")

        cv2.destroyAllWindows()
        print(f"Saved: data/trajectories_{trial_name}.json")
        print(f"FPS avg: {fps:.2f} | FPS min: {fps_min:.2f}")


if __name__ == "__main__":
    main()