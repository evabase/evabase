'use strict';
// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import '@openzeppelin/hardhat-upgrades';
import { ethers } from 'hardhat';
// eslint-disable-next-line node/no-missing-import
import { store, help, HowToCall, KeepNetWork } from '../help';

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

  const evaSafesFactory = await ethers.getContractFactory('EvaSafesFactory');
  const evaSafesFactoryContract = await evaSafesFactory.attach(store.get('evaSafesFactory'));

  const evaSafes = await evaSafesFactoryContract.get(ownerO[0].address);
  console.log(`safes: ${evaSafes}`);

  const EvaSafes = await ethers.getContractFactory('EvaSafes');
  const evaSafesContract = EvaSafes.attach(evaSafes);
  const safesOwner = await evaSafesContract.owner();
  console.log(`safesOwner: ${safesOwner}`);

  // task

  const opsFlowProxy = await ethers.getContractFactory('OpsFlowProxy');

  // eslint-disable-next-line max-len
  const cancelData = opsFlowProxy.interface.encodeFunctionData('closeFlow', [store.get('evaFlowController'), 68]);

  const tx = await evaSafesContract.proxy(store.get('opsFlowProxy'), 1, cancelData);

  console.log('tx=', tx);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
