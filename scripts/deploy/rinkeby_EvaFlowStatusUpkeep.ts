'use strict';
// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import '@openzeppelin/hardhat-upgrades';
import { ethers } from 'hardhat';
// eslint-disable-next-line node/no-missing-import
import { help, KeepNetWork, store } from '../help';

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const admin = (await help.admin())!;
  console.log(`deployer owner : ${admin.address}`);
  const EvaFlowStatusUpkeep = await ethers.getContractFactory('EvaFlowStatusUpkeep');
  const evaFlowStatusUpkeep = await EvaFlowStatusUpkeep.deploy(store.get('evaFlowController'), 0);

  console.log(`evaFlowStatusUpkeep: ${evaFlowStatusUpkeep.address}`);
  store.set('evaFlowStatusUpkeep', evaFlowStatusUpkeep.address);
  const evaFlowController = await ethers.getContractAt('EvaFlowController', store.get('evaFlowController'), admin);
  const tx = await evaFlowController.setFlowOperators(evaFlowStatusUpkeep.address, true);
  console.log('setFlowOperators hash=', tx.hash);
}

async function removeKeepers(bot: string) {
  const ownerO = await help.admin()!;
  const config = await ethers.getContractAt('EvabaseConfig', store.get('evabaseConfig'), ownerO);
  console.log('size:', await config.keepBotSizes(KeepNetWork.ChainLink));
  const tx = await config.removeKeeper(bot, {
    nonce: undefined,
    gasPrice: 1e10,
  });
  await tx.wait();
  console.log('size:', await config.keepBotSizes(KeepNetWork.ChainLink));
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
