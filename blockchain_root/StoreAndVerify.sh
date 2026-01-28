#!/bin/bash
set -euo pipefail

# このスクリプトの位置を基準にパスを計算
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BLOCKCHAIN_DIR="$SCRIPT_DIR"
PROJECT_ROOT="${PROJECT_ROOT:-$SCRIPT_DIR/../project_root}"

echo "=============================================================="
echo " Blockchain Store & Verify"
echo "--------------------------------------------------------------"
echo " Blockchain Dir: $BLOCKCHAIN_DIR"
echo " Project Root:   $PROJECT_ROOT"
echo "=============================================================="

# proof と public.json が既に blockchain_root/proof にある前提
# (generate_proof.sh からコピー済み)
PROOF_FILE="$BLOCKCHAIN_DIR/proof/proof.json"
PUBLIC_FILE="$BLOCKCHAIN_DIR/proof/public.json"

if [ ! -f "$PROOF_FILE" ] || [ ! -f "$PUBLIC_FILE" ]; then
  echo "エラー: proof.json または public.json が見つかりません"
  echo "  $PROOF_FILE"
  echo "  $PUBLIC_FILE"
  exit 1
fi

echo "ブロックチェーン上で検証＋保存中..."
cd "$BLOCKCHAIN_DIR"
npx hardhat run scripts/storeAndVerify.js --network sepolia

echo "ブロックチェーンへの保存が完了しました"
