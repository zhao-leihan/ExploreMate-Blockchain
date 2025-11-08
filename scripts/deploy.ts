import { ethers } from "hardhat";

async function main() {
  console.log("Deploying ExplorMate contract...");

  const ExplorMate = await ethers.getContractFactory("ExplorMate");
  const explorMate = await ExplorMate.deploy();

  // Tidak perlu await explorMate.deployed() di ethers v6
  await explorMate.waitForDeployment(); //

  console.log("ExplorMate deployed to:", await explorMate.getAddress());
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});