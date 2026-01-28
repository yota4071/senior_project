#!/bin/bash
# ==============================================================
#  ZK Pipeline (preprocess + witness + prove + verify)
#  - 前処理: data/trajectories.json → circuits/input.json を生成（utils/convert.py）
#  - Witness計算（circuits/circuit_js/generate_witness.js）
#  - Proof生成（Groth16, snarkjs）
#  - 検証
#  ※ このファイルは project_root/ 直下に置く前提です
# ==============================================================

set -euo pipefail
RPI_NOTIFY_URL="http://192.168.101.9:5000/zkp-stored"

# --- 実行コマンド（必要なら環境変数で上書き可） ---
PYTHON_EXEC="${PYTHON_EXEC:-python3}"
NODE_EXEC="${NODE_EXEC:-$(command -v node || echo /usr/local/bin/node)}"
SNARKJS_EXEC="${SNARKJS_EXEC:-$(command -v snarkjs || echo /usr/local/bin/snarkjs)}"

# --- プロジェクトルート（このshの位置を基準） ---
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

# --- ディレクトリ・ファイル（あなたの構成に合わせて既定値を設定） ---
CIRCUITS_DIR="$BASE_DIR/circuits"
DATA_DIR="$BASE_DIR/data"
UTILS_DIR="$BASE_DIR/utils"

CIRCUIT_NAME="${CIRCUIT_NAME:-circuit}"  # circuits/circuit_js/circuit.wasm 等を想定

# 入出力
TRAJECTORIES_JSON="${TRAJECTORIES_JSON:-$DATA_DIR/trajectories.json}"
INPUT_JSON="${INPUT_JSON:-$CIRCUITS_DIR/input.json}"
WITNESS_WTNS="$BASE_DIR/output/witness.wtns"
PROOF_JSON="$BASE_DIR/output/proof.json"
PUBLIC_JSON="$BASE_DIR/output/public.json"

# circom 生成物
WASM_PATH="${WASM_PATH:-$CIRCUITS_DIR/${CIRCUIT_NAME}_js/${CIRCUIT_NAME}.wasm}"
GEN_WITNESS_JS="${GEN_WITNESS_JS:-$CIRCUITS_DIR/${CIRCUIT_NAME}_js/generate_witness.js}"
ZKEY_PATH="${ZKEY_PATH:-$CIRCUITS_DIR/${CIRCUIT_NAME}_final.zkey}"
VK_PATH="${VK_PATH:-$CIRCUITS_DIR/verification_key.json}"

# 前処理スクリプト（あなたの convert.py）
CONVERT_PY="${CONVERT_PY:-$UTILS_DIR/convert.py}"

# 出力ディレクトリ
OUTPUT_DIR="$BASE_DIR/output"
mkdir -p "$OUTPUT_DIR"

echo "=============================================================="
echo " Zero-Knowledge Proof Pipeline"
echo "--------------------------------------------------------------"
echo " Base Dir:     $BASE_DIR"
echo " Circuit:      $CIRCUIT_NAME"
echo " Circuits Dir: $CIRCUITS_DIR"
echo " Data Dir:     $DATA_DIR"
echo " Utils Dir:    $UTILS_DIR"
echo " Output Dir:   $OUTPUT_DIR"
echo "--------------------------------------------------------------"
echo " TRAJECTORIES: $TRAJECTORIES_JSON"
echo " INPUT JSON:   $INPUT_JSON"
echo "=============================================================="
echo

# --- 依存コマンドチェック ---
command -v "$PYTHON_EXEC" >/dev/null 2>&1 || { echo "error: $PYTHON_EXEC が見つかりません"; exit 1; }
[ -x "$NODE_EXEC" ] || { echo "error: node 実行ファイルが見つかりません: $NODE_EXEC"; exit 1; }
[ -x "$SNARKJS_EXEC" ] || { echo "error: snarkjs 実行ファイルが見つかりません: $SNARKJS_EXEC"; exit 1; }

# --- 必須ファイルチェック ---
[ -f "$TRAJECTORIES_JSON" ] || { echo "error: $TRAJECTORIES_JSON がありません"; exit 1; }
[ -f "$CONVERT_PY" ] || { echo "error: 前処理スクリプトがありません: $CONVERT_PY"; exit 1; }

[ -f "$WASM_PATH" ] || { echo "error: WASM がありません: $WASM_PATH"; exit 1; }
[ -f "$GEN_WITNESS_JS" ] || { echo "error: generate_witness.js がありません: $GEN_WITNESS_JS"; exit 1; }
[ -f "$ZKEY_PATH" ] || { echo "error: zkey がありません: $ZKEY_PATH"; exit 1; }
[ -f "$VK_PATH" ] || { echo "error: verification_key.json がありません: $VK_PATH"; exit 1; }

# ----------------------------------------------------------------
# [前処理] utils/convert.py を使って Circom 用 input.json を生成
# ----------------------------------------------------------------
echo "[前処理] $TRAJECTORIES_JSON → $INPUT_JSON を生成しています..."
"$PYTHON_EXEC" "$CONVERT_PY" "$TRAJECTORIES_JSON" "$INPUT_JSON"
[ -f "$INPUT_JSON" ] || { echo "error: 前処理で $INPUT_JSON の生成に失敗しました"; exit 1; }
echo "  => 変換完了: $INPUT_JSON"
echo

# -----------------------
# 1) Witness の計算
# -----------------------
echo "[ステップ 1/3] Witness を計算中..."
"$NODE_EXEC" "$GEN_WITNESS_JS" "$WASM_PATH" "$INPUT_JSON" "$WITNESS_WTNS"
echo "  => Witness: $WITNESS_WTNS"
echo

# -----------------------
# 2) Proof の生成
# -----------------------
echo "[ステップ 2/3] Proof を生成中..."
"$SNARKJS_EXEC" groth16 prove "$ZKEY_PATH" "$WITNESS_WTNS" "$PROOF_JSON" "$PUBLIC_JSON"
echo "  => Proof:  $PROOF_JSON"
echo "  => Public: $PUBLIC_JSON"
echo

# -----------------------
# 3) 検証
# -----------------------
echo "[ステップ 3/3] 生成した Proof を検証中..."
VERIFY_OUT="$("$SNARKJS_EXEC" groth16 verify "$VK_PATH" "$PUBLIC_JSON" "$PROOF_JSON" || true)"
if [[ "$VERIFY_OUT" == *"OK"* ]]; then
  echo "検証に成功しました！"
else
  echo "検証に失敗しました。出力:"
  echo "$VERIFY_OUT"
  exit 1
fi

echo
echo "全てのプロセスが正常に完了しました。"

# =======================
# (任意) ブロックチェーン連携
# =======================
# 環境変数 RUN_CHAIN=1 なら、ZK生成後に blockchain_root/StoreAndVerify.sh を実行
RUN_CHAIN="${RUN_CHAIN:-1}"  # 既定=1（実行する）。0にするとスキップ。
BLOCKCHAIN_DIR="${BLOCKCHAIN_DIR:-$BASE_DIR/../blockchain_root}"

if [[ "$RUN_CHAIN" == "1" ]]; then
  echo
  echo "ブロックチェーン連携を実行します..."
  echo "  Blockchain Dir: $BLOCKCHAIN_DIR"

  # 事前チェック
  [ -d "$BLOCKCHAIN_DIR" ] || { echo "error: blockchain_root が見つかりません: $BLOCKCHAIN_DIR"; exit 1; }
  [ -f "$PROOF_JSON" ] || { echo "error: $PROOF_JSON がありません"; exit 1; }
  [ -f "$PUBLIC_JSON" ] || { echo "error: $PUBLIC_JSON がありません"; exit 1; }

  # コピー先フォルダ作成
  mkdir -p "$BLOCKCHAIN_DIR/proof"

  # 出力物を blockchain_root/proof へコピー
  cp "$PROOF_JSON"  "$BLOCKCHAIN_DIR/proof/proof.json"
  cp "$PUBLIC_JSON" "$BLOCKCHAIN_DIR/proof/public.json"
  echo "  => proof.json / public.json を blockchain_root/proof にコピーしました"

  # StoreAndVerify.sh を呼ぶ（相対パス・権限注意）
  if [ -x "$BLOCKCHAIN_DIR/StoreAndVerify.sh" ]; then
    pushd "$BLOCKCHAIN_DIR" >/dev/null
    ./StoreAndVerify.sh
    CHAIN_STATUS=$?
    popd >/dev/null
    if [ $CHAIN_STATUS -ne 0 ]; then
      echo "StoreAndVerify.sh の実行に失敗しました (exit=$CHAIN_STATUS)"
      exit $CHAIN_STATUS
    fi
    echo "ブロックチェーン側の検証＋保存まで完了しました"
  else
    echo "$BLOCKCHAIN_DIR/StoreAndVerify.sh が実行不可 or 不在です。"
    echo "   chmod +x してから再実行するか、以下コマンドを手動で実行してください："
    echo "   cd \"$BLOCKCHAIN_DIR\" && npx hardhat run scripts/storeAndVerify.js --network sepolia"
  fi
fi

EVENT_JSON=$(cat <<'JSON'
{
  "event": "zkp_stored",
  "timestamp": "'"$(date -Is)"'",
  "note": "proof stored on chain"
}
JSON
)

# --- HTTP(Webhook) 通知 ---
if [[ -n "${RPI_NOTIFY_URL:-}" ]]; then
  echo "ラズパイへ HTTP 通知: $RPI_NOTIFY_URL"
  curl -sS -X POST "$RPI_NOTIFY_URL" \
    -H 'Content-Type: application/json' \
    -d "$EVENT_JSON" || echo "HTTP通知に失敗しました（処理は続行）"
fi

# --- SSH リモート実行 ---
if [[ -n "${RPI_SSH_HOST:-}" ]]; then
  echo "ラズパイへ SSH で検証実行: $RPI_SSH_HOST"
  # 既定コマンド（上書き可能）
  RPI_SSH_CMD="${RPI_SSH_CMD:-'/usr/bin/python3 ~/apps/blockchain_checker.py'}"
  ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new "$RPI_SSH_HOST" "$RPI_SSH_CMD" \
    || echo "SSH実行に失敗しました（処理は続行）"
fi