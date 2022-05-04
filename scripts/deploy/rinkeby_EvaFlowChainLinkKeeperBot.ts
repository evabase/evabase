'use strict';
// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import '@openzeppelin/hardhat-upgrades';
import { ethers } from 'hardhat';
// eslint-disable-next-line node/no-missing-import
import { store } from '../help';

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

  const EvaFlowChainLinkKeeperBot = await ethers.getContractFactory('EvaFlowChainLinkKeeperBot');

  const evaFlowChainLinkKeeperBot = await EvaFlowChainLinkKeeperBot.deploy(
    store.get('evabaseConfig'),
    store.get('evaFlowChecker'),
    // evaFlowControler.address,
    // store.get("linkToken"),
    store.get('chainlinkKeeperRegistry'),

    // store.get("chainlinkUpkeepRegistrationRequests")
  );
  await evaFlowChainLinkKeeperBot.deployed();
  console.log(`evaFlowChainLinkKeeperBot: ${evaFlowChainLinkKeeperBot.address}`);
  store.set('evaFlowChainLinkKeeperBot', evaFlowChainLinkKeeperBot.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
