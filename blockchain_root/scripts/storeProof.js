const hre = require("hardhat");
const fs = require("fs");

async function main() {
  const zkpStorageAddress = "0xf629EDbe20624d326fd3308C27F42A1C4BEBAC35";

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

  console.log("Storing proof on blockchain...");
  const tx = await zkpStorage.storeProof(a, b, c, inputValue);
  await tx.wait();

  console.log("✅ Proof stored on blockchain");

  const storedProof = await zkpStorage.getMyProof();
  console.log("✅ Stored a:", storedProof.a.map(v => v.toString()));
  console.log("✅ Stored b:", storedProof.b.map(arr => arr.map(v => v.toString())));
  console.log("✅ Stored c:", storedProof.c.map(v => v.toString()));
  console.log("✅ Stored input:", storedProof.input.map(v => v.toString()));
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});