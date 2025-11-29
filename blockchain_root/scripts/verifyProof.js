const hre = require("hardhat");

async function main() {
  const zkpStorageAddress = "0x365F807E50C4FFB3520A823f16573E0FF3bE1a9E";


  const ZKPStorage = await hre.ethers.getContractFactory("ZKPStorage");
  const zkpStorage = await ZKPStorage.attach(zkpStorageAddress);

  const result = await zkpStorage.verifyMyProof();
  console.log("Verification result:", result);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});