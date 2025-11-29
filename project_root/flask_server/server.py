from flask import Flask, request, jsonify
import subprocess
import os

app = Flask(__name__)

@app.route('/alert', methods=['POST'])
def handle_alert():
    data = request.json
    print("ATMからの通知を受信:", data)

    try:

        current_script_path = os.path.dirname(os.path.abspath(__file__))
        project_root = os.path.abspath(os.path.join(current_script_path, '..'))
        shell_script_path = os.path.join(project_root, 'generate_proof.sh')

        print(f"実行するスクリプトの絶対パス: {shell_script_path}")
        result = subprocess.run(
            ["bash", shell_script_path],
            check=True,
            capture_output=True,
            text=True,
            timeout=300
        )
        print("✅ ZKP生成成功:\n", result.stdout)
        return jsonify({"status": "zkp_success"}), 200

    except subprocess.CalledProcessError as e:
        print("❌ ZKP生成失敗 (スクリプトがエラーを返しました):")
        print("   STDOUT:", e.stdout)
        print("   STDERR:", e.stderr)
        return jsonify({"status": "zkp_failed", "error": e.stderr}), 500
    except FileNotFoundError:
        print(f"❌ 致命的エラー: シェルスクリプトが見つかりません: {shell_script_path}")
        return jsonify({"status": "script_not_found"}), 500
    except Exception as e:
        print(f"❌ 予期せぬエラーが発生しました: {e}")
        return jsonify({"status": "unknown_error", "message": str(e)}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)