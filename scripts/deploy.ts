import { ethers } from "hardhat";

async function main() {
  const Pop = await ethers.getContractFactory("Pop");
  const pop = await Pop.deploy();

  console.log('deploying...');

  await pop.deployed();

  console.log(`PoP deployed to ${pop.address}`);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
