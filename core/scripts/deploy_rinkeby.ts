// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import "@openzeppelin/hardhat-upgrades";
import { ethers, upgrades } from "hardhat";
const store = require("data-store")({
  // path: process.cwd() + "/deployInfo.json",
  path: process.cwd() + "/scripts/deployInfo_rinkeby.json",
});

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
  await evabaseConfig.setControl(evaFlowControler.address);
  store.set("evaFlowControler", evaFlowControler.address);
  console.log(`evaFlowControler: ${evaFlowControler.address}`);
  // 4 EvaFlowChecker
  const EvaFlowChecker = await ethers.getContractFactory("EvaFlowChecker");
  const evaFlowChecker = await EvaFlowChecker.deploy(
    evabaseConfig.address,
    evaFlowControler.address
  );
  await evaFlowChecker.deployed();
  console.log(`evaFlowChecker: ${evaFlowChecker.address}`);
  store.set("evaFlowChecker", evaFlowChecker.address);
  // 5 EvaFlowChainLinkKeeperBot
  const EvaFlowChainLinkKeeperBot = await ethers.getContractFactory(
    "EvaFlowChainLinkKeeperBot"
  );

  const evaFlowChainLinkKeeperBot = await EvaFlowChainLinkKeeperBot.deploy(
    evabaseConfig.address,
    evaFlowChecker.address,
    evaFlowControler.address,
    // store.get("linkToken"),
    store.get("chainlinkKeeperRegistry")
    // store.get("chainlinkUpkeepRegistrationRequests")
  );
  await evaFlowChainLinkKeeperBot.deployed();
  console.log(
    `evaFlowChainLinkKeeperBot: ${evaFlowChainLinkKeeperBot.address}`
  );
  store.set("evaFlowChainLinkKeeperBot", evaFlowChainLinkKeeperBot.address);

  // 6 NftLimitOrder upgrade
  const NftLimitOrderFlow = await ethers.getContractFactory(
    "NftLimitOrderFlow"
  );

  // console.log("NftLimitOrderFlow deployed to:", NftLimitOrderFlow.address);
  // store.set("NftLimitOrderFlow", NftLimitOrderFlow.address);

  const factory = evaSafesFactory.address;
  const upgrade = await upgrades.deployProxy(NftLimitOrderFlow, [factory]);

  await upgrade.deployed();
  console.log("NftLimitOrderFlow deployed to:", upgrade.address);
  store.set("NftLimitOrderFlow", upgrade.address);

  await evaFlowControler.addEvabaseFlowByOwner(
    upgrade.address,
    1, // KeepNetWork.Evabase
    "NFTLimitOrderFlow"
  );

  // 7 evabase bot
  const EvaBaseServerBot = await ethers.getContractFactory("EvaBaseServerBot");
  const evaBaseServerBot = await EvaBaseServerBot.deploy(
    evabaseConfig.address,
    evaFlowChecker.address,
    evaFlowControler.address
  );
  await evaBaseServerBot.deployed();
  console.log(`evaBaseServerBot: ${evaBaseServerBot.address}`);
  store.set("evaBaseServerBot", evaBaseServerBot.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
