const hre = require("hardhat");
const fs = require("fs");

async function main() {
  const zkpStorageAddress = "0xb4f4e63DF760209E0a4B470088B5268C2843B7e0";

  const [signer] = await hre.ethers.getSigners();
  console.log("Using signer:", await signer.getAddress());

  const ZKPStorage = await hre.ethers.getContractFactory("ZKPStorage", signer);
  const zkpStorage = await ZKPStorage.attach(zkpStorageAddress);

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

  const inputValue = BigInt(pub[0]);

  console.log("Verifying and storing proof...");

  const start = Date.now();

  const tx = await zkpStorage.verifyAndStoreProof(a, b, c, inputValue);
  const receipt = await tx.wait();

   const end = Date.now(); 
   const duration = end - start;

  console.log(`Verification and storage took ${duration} ms`);
  console.log("Verification and storage done. TX Hash:", receipt.transactionHash);

  const storedProof = await zkpStorage.getMyProof();
  console.log("Stored input:", storedProof.input.map(v => v.toString()));
  console.log("Verified:", storedProof.verified);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});