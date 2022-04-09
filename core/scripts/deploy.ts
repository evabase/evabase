// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import { ethers } from "hardhat";
const store = require("data-store")({
  path: process.cwd() + "/deployInfo.json",
});

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  // config
  const EvabaseConfig = await ethers.getContractFactory("EvabaseConfig");
  const evabaseConfig = await EvabaseConfig.deploy();

  await evabaseConfig.deployed();
  console.log(`evabaseConfig: ${evabaseConfig.address}`);
  store.set("evabaseConfig", evabaseConfig.address);
  // 2 EvaSafesFactory
  const EvaSafesFactory = await ethers.getContractFactory("EvaSafesFactory");
  const evaSafesFactory = await EvaSafesFactory.deploy(evabaseConfig.address);

  await evaSafesFactory.deployed();
  store.set("evaSafesFactory", evaSafesFactory.address);
  console.log(`evaSafesFactory: ${evaSafesFactory.address}`);
  // 3 EvaFlowControler
  const EvaFlowControler = await ethers.getContractFactory("EvaFlowControler");
  const evaFlowControler = await EvaFlowControler.deploy(
    evabaseConfig.address,
    evaSafesFactory.address
  );
  await evaFlowControler.deployed();
  store.set("evaFlowControler", evaFlowControler.address);
  console.log(`evaFlowControler: ${evaFlowControler.address}`);
  // 4
  const EvaFlowChecker = await ethers.getContractFactory("EvaFlowChecker");
  const evaFlowChecker = await EvaFlowChecker.deploy(
    evabaseConfig.address,
    evaFlowControler.address
  );
  await evaFlowChecker.deployed();
  console.log(`evaFlowChecker: ${evaFlowChecker.address}`);
  store.set("evaFlowChecker", evaFlowChecker.address);
  // 5
  const EvaFlowChainLinkKeeperBot = await ethers.getContractFactory(
    "EvaFlowChainLinkKeeperBot"
  );

  const evaFlowChainLinkKeeperBot = await EvaFlowChainLinkKeeperBot.deploy(
    evabaseConfig.address,
    evaFlowControler.address,
    evaFlowControler.address,
    store.get("linkToken"),
    store.get("chainlinkKeeperRegistry"),
    store.get("chainlinkUpkeepRegistrationRequests")
  );
  await evaFlowChainLinkKeeperBot.deployed();
  console.log(
    `evaFlowChainLinkKeeperBot: ${evaFlowChainLinkKeeperBot.address}`
  );
  store.set("evaFlowChainLinkKeeperBot", evaFlowChainLinkKeeperBot.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
