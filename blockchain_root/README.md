# ZKP On-Chain Verification with Hardhat

このプロジェクトでは、**Circom + snarkjs** で生成された zk-SNARK 証明を **Ethereum（Sepolia）上で検証・保存**する仕組みを Hardhat を用いて構築します。

以下を含みます：

- `Verifier.sol`: snarkjs により生成された zk-SNARK 検証コントラクト
- `ZKPStorage.sol`: 証明の保存と検証を行う独自コントラクト
- `storeAndVerify.js`: 証明を検証し、結果をオンチェーンに保存するスクリプト
- `proof.json` / `public.json`: Circom によって生成された証明と公開入力

---

## 🧠 構成
project-root/
├── contracts/
│   ├── Verifier.sol            # snarkjsで自動生成された検証コントラクト
│   └── ZKPStorage.sol          # 証明と結果の保存コントラクト
├── proof/
│   ├── proof.json              # snarkjsで生成した証明
│   └── public.json             # 公開入力
├── scripts/
│   ├── deploy.js               # コントラクトのデプロイ
│   └── storeAndVerify.js       # 証明の検証・保存スクリプト
├── hardhat.config.js
└── README.md

---

## ⚙️ 事前準備

- Node.js & npm
- Hardhat
- Circom/snarkjs で証明生成済み
- `.env` ファイルを以下のように作成：

---

## 🚀 実行手順

### 1. コントラクトをコンパイル

```bash
npx hardhat compile

npx hardhat run scripts/deploy.js --network sepolia

proof/
├── proof.json
└── public.json

npx hardhat run scripts/storeAndVerify.js --network sepolia

Using signer: 0x1234...
Verifying and storing proof...
Verification and storage done. TX Hash: 0xa150e54315...66798b
Stored input: [ '1' ]
Verified: true
