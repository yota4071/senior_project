// scripts/deploy.js
async function main() {
  const Verifier = await ethers.getContractFactory("Groth16Verifier");
  const verifier = await Verifier.deploy();
  await verifier.waitForDeployment();

  console.log("Verifier deployed to:", await verifier.getAddress());

  const ZKPStorage = await ethers.getContractFactory("ZKPStorage");
  const zkpStorage = await ZKPStorage.deploy(await verifier.getAddress());
  await zkpStorage.waitForDeployment();

  console.log("ZKPStorage deployed to:", await zkpStorage.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});