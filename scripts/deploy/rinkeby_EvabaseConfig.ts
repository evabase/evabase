// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import '@openzeppelin/hardhat-upgrades';
import { ethers } from 'hardhat';
// const store = require("data-store")({
//   // path: process.cwd() + "/deployInfo.json",
//   path: process.cwd() + "/scripts/deploy/rinkeby.json",
// });

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const ownerO = await ethers.getSigners();
  console.log(`deployer owner : ${ownerO[0].address}`);

  // 1 config
  const EvabaseConfig = await ethers.getContractFactory('EvabaseConfig');
  const evabaseConfig = await EvabaseConfig.deploy();

  await evabaseConfig.deployed();
  console.log(`evabaseConfig: ${evabaseConfig.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
