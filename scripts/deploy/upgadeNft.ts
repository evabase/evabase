'use strict';
// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import '@openzeppelin/hardhat-upgrades';
import { ethers, upgrades } from 'hardhat';
const store = require('data-store')({
  // path: process.cwd() + "/deployInfo.json",
  path: process.cwd() + '/scripts/deploy/rinkeby.json',
});

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy

  // 6 NftLimitOrder upgrade
  const NftLimitOrderFlow = await ethers.getContractFactory('NftLimitOrderFlow');

  // console.log("NftLimitOrderFlow deployed to:", NftLimitOrderFlow.address);
  // store.set("NftLimitOrderFlow", NftLimitOrderFlow.address);

  // const factory = store.get("evaSafesFactory");
  // const upgrade = await upgrades.upgradeProxy(NftLimitOrderFlow, [
  //   factory,
  //   "EVABASE",
  //   "1",
  // ]);

  // await upgrade.deployed();
  // console.log("NftLimitOrderFlow deployed to:", upgrade.address);
  // store.set("NftLimitOrderFlow", upgrade.address);

  // const BoxV2 = await ethers.getContractFactory("BoxV2");
  await upgrades.upgradeProxy(store.get('NftLimitOrderFlow'), NftLimitOrderFlow);
  console.log('NftLimitOrderFlow upgraded');

  // await evaFlowControler.addEvabaseFlowByOwner(
  //   upgrade.address,
  //   1, // KeepNetWork.Evabase
  //   "NFTLimitOrderFlow"
  // );

  // // 7 evabase bot
  // const EvaBaseServerBot = await ethers.getContractFactory("EvaBaseServerBot");
  // const evaBaseServerBot = await EvaBaseServerBot.deploy(
  //   evabaseConfig.address,
  //   evaFlowChecker.address,
  //   evaFlowControler.address,
  //   1 // KeepNetWork.Evabase
  // );
  // await evaBaseServerBot.deployed();
  // console.log(`evaBaseServerBot: ${evaBaseServerBot.address}`);
  // store.set("evaBaseServerBot", evaBaseServerBot.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
