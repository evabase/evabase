// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import "@openzeppelin/hardhat-upgrades";
import { ethers, upgrades } from "hardhat";
const store = require("data-store")({
  // path: process.cwd() + "/deployInfo.json",
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
    evabaseConfig.address
    // evaFlowControler.address
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
    // evaFlowControler.address,
    // store.get("linkToken"),
    store.get("chainlinkKeeperRegistry"),
    0
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
  const upgrade = await upgrades.deployProxy(NftLimitOrderFlow, [
    evabaseConfig.address,
    factory,
    "EVABASE",
    "1",
  ]);

  await upgrade.deployed();
  console.log("NftLimitOrderFlow deployed to:", upgrade.address);
  store.set("NftLimitOrderFlow", upgrade.address);

  await evaFlowControler.createEvaSafes(ownerO[0].address);

  // const Order = [
  //   { name: "owner", type: "addess" },
  //   { name: "assetToken", type: "addess" },
  //   { name: "amount", type: "uint256" },
  //   { name: "price", type: "uint256" },
  //   { name: "expireTime", type: "uint256" },
  //   { name: "tokenId", type: "uint256" },
  //   { name: "salt", type: "uint256" },
  // ];

  const myStructData = ethers.utils.AbiCoder.prototype.encode(
    [
      "address",
      "address",
      "uint256",
      "uint256",
      "uint256",
      "uint256",
      "uint256",
    ],
    [ownerO[0].address, ownerO[0].address, 100, 1, 16803555107, 342905, 1899909]
  );

  // const tx = await myContract.myFunction(myStructData, {
  //   gasLimit: ethers.utils.parseUnits("1000000", "wei"),
  // });

  // const order = {
  //   owner: ownerO[0].address,
  //   assetToken: ownerO[0].address,
  //   amount: "1000",
  //   price: "1",
  //   expireTime: "1680355507",
  //   tokenId: 342905,
  //   salt: "1899909",
  // };

  // const data = ethers.utils.defaultAbiCoder.encode(["Order"], [order]);

  // console.log(`data: ${myStructData}`);

  await evaFlowControler.createFlow(
    "ACE",
    1, // evabaseKeep
    upgrade.address,
    myStructData,
    200000,
    {
      value: ethers.utils.parseEther("0.01"),
    }
  );
  await evaFlowControler.pauseFlow(1, myStructData);
  await evaFlowControler.startFlow(1, myStructData);
  // 7 evabase bot
  const EvaBaseServerBot = await ethers.getContractFactory("EvaBaseServerBot");
  const evaBaseServerBot = await EvaBaseServerBot.deploy(
    evabaseConfig.address,
    evaFlowChecker.address,
    // evaFlowControler.address,
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
