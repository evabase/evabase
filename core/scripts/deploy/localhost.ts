// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import "@openzeppelin/hardhat-upgrades";
import { ethers, upgrades } from "hardhat";
// import { ethers } from "hardhat";
const store = require("data-store")({
  // path: process.cwd() + "/deployInfo.json",
  // process.argv;
  // console.log(`process.argv: ${process.argv}`);

  path: process.cwd() + "/scripts/deploy/localhost.json",
});

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  // console.log(process.argv);
  console.log(`process.argv: ${process.argv}`);
  console.log(`process: ${process}`);
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
  const evaFlowChecker = await EvaFlowChecker.deploy(evabaseConfig.address);
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
    // store.get("linkToken"),
    store.get("chainlinkKeeperRegistry"),
    1
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

  // const nftLimitOrderFlow = await NftLimitOrderFlow.deploy(
  //   evaSafesFactory.address
  // );

  // console.log("NftLimitOrderFlow deployed to:", nftLimitOrderFlow.address);
  // store.set("NftLimitOrderFlow", nftLimitOrderFlow.address);

  const factory = evaSafesFactory.address;
  const upgrade = await upgrades.deployProxy(NftLimitOrderFlow, [
    factory,
    "EVABASE",
    "1",
  ]);

  await upgrade.deployed();
  console.log("Upgrade NftLimitOrderFlow deployed to:", upgrade.address);
  store.set("Upgrade NftLimitOrderFlow", upgrade.address);

  await evaFlowControler.addEvabaseFlowByOwner(
    upgrade.address,
    // nftLimitOrderFlow.address,
    1, // KeepNetWork.Evabase
    "NFTLimitOrderFlow"
  );

  // 7 evabase bot
  const EvaBaseServerBot = await ethers.getContractFactory("EvaBaseServerBot");
  const evaBaseServerBot = await EvaBaseServerBot.deploy(
    evabaseConfig.address,
    evaFlowChecker.address,
    1 // KeepNetWork.Evabase
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
