'use strict';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import '@openzeppelin/hardhat-upgrades';
import { ethers } from 'hardhat';
// eslint-disable-next-line node/no-missing-import
import { store, help } from '../help';

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy

  // const ownerO = (await help.admin()) as SignerWithAddress;
  // const evaFlowController = await ethers.getContractAt('EvaFlowController', store.get('evaFlowController'), ownerO);

  const ownerO = await ethers.getSigners();
  console.log(`deployer owner : ${ownerO[0].address}`);
  const EvaFlowController = await ethers.getContractFactory('EvaFlowController');
  const evaFlowController = EvaFlowController.attach(store.get('evaFlowController'));

  const _minConfig = {
    feeRecived: ownerO[0].address,
    feeToken: '0x0000000000000000000000000000000000000000',
    minGasFundForUser: 0,
    minGasFundOneFlow: 0,
    ppb: 1,
    blockCountPerTurn: 0,
  };
  const tx = await evaFlowController.setMinConfig(_minConfig);
  // tx.wait();
  console.log(tx.hash);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
