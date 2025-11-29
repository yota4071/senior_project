#!/bin/bash

echo "証明ファイルをBlockchainプロジェクトへコピー..."
cp ~/senior_project/project_root/proof.json ~/senior_project/blockchain_root/proof/
cp ~/senior_project/project_root/public.json ~/senior_project/blockchain_root/proof/

echo "ブロックチェーン上で検証＋保存中..."
cd ~/senior_project/blockchain_root
npx hardhat run scripts/storeAndVerify.js --network sepolia