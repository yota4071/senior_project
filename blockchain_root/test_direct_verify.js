const hre = require("hardhat");
const fs = require("fs");

async function main() {
  // Verifierコントラクトに直接接続
  const verifierAddress = "0x8A791620dd6260079BF849Dc5567aDC3F2FdC318";
  const Verifier = await hre.ethers.getContractFactory("Groth16Verifier");
  const verifier = await Verifier.attach(verifierAddress);

  // proof.json と public.json を読み込み
  const proof = JSON.parse(fs.readFileSync("./proof/proof.json"));
  const pub = JSON.parse(fs.readFileSync("./proof/public.json"));

  const a = [
    BigInt(proof.pi_a[0]),
    BigInt(proof.pi_a[1])
  ];

  const b = [
    [BigInt(proof.pi_b[0][1]), BigInt(proof.pi_b[0][0])],
    [BigInt(proof.pi_b[1][1]), BigInt(proof.pi_b[1][0])]
  ];

  const c = [
    BigInt(proof.pi_c[0]),
    BigInt(proof.pi_c[1])
  ];

  const input = [BigInt(pub[0])]; // public.jsonの値を使用

  console.log("Calling Verifier directly...");
  console.log("Input:", input);
  const result = await verifier.verifyProof(a, b, c, input);
  console.log("Direct verification result:", result);
}

main().catch(console.error);