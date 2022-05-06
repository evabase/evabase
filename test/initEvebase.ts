'use strict';
import { config } from 'dotenv';
/* eslint-disable prettier/prettier */
// import chai, { expect } from "chai";
import { ethers } from 'hardhat';
import { help } from '../scripts/help';
import { EvaFlowRandomChecker } from '../typechain';

const store = require('data-store')({
  path: process.cwd() + '/testInfo.json',
});

export const initEvebase = async function initEvebase() {
  // Hardhat always runs the compile task when running scripts with its command
  const EvabaseConfig = await ethers.getContractFactory('EvabaseConfig');
  const evabaseConfig = await EvabaseConfig.deploy();
  const ownerO = await ethers.getSigners();
  console.log(`deployer owner : ${ownerO[0].address}`);
  await evabaseConfig.deployed();
  console.log(`evabaseConfig: ${evabaseConfig.address}`);

  const EvaSafesFactory = await ethers.getContractFactory('EvaSafesFactory');
  const evaSafesFactory = await EvaSafesFactory.deploy(evabaseConfig.address);

  await evaSafesFactory.deployed();

  console.log(`evaSafesFactory: ${evaSafesFactory.address}`);

  // 3 EvaFlowController
  const EvaFlowController = await ethers.getContractFactory('EvaFlowController');
  const evaFlowController = await EvaFlowController.deploy(evabaseConfig.address, evaSafesFactory.address);
  await evaFlowController.deployed();
  console.log(`evaFlowController: ${evaFlowController.address}`);
  // 4
  const evaFlowChecker = (await help.deploy('EvaFlowRandomChecker', [evabaseConfig.address])) as EvaFlowRandomChecker;
  console.log(`evaFlowChecker: ${evaFlowChecker.address}`);
  // 5

  const EvaBaseServerBot = await ethers.getContractFactory('EvaBaseServerBot');
  const evaBaseServerBot = await EvaBaseServerBot.deploy(evabaseConfig.address, evaFlowChecker.address);
  await evaBaseServerBot.deployed();
  console.log(`evaBaseServerBot: ${evaBaseServerBot.address}`);
  await evabaseConfig.setControl(evaFlowController.address);

  const NftLimitOrderFlowProxy = await ethers.getContractFactory('NftLimitOrderFlowProxy');
  const factory = evaSafesFactory.address;
  const nftLimitOrderFlowProxy = await NftLimitOrderFlowProxy.deploy(evabaseConfig.address, factory, 'EVABASE', '1');
  await nftLimitOrderFlowProxy.deployed();
  console.log('NftLimitOrderFlowProxy:', nftLimitOrderFlowProxy.address);
  return {
    evabaseConfig,
    evaSafesFactory,
    evaFlowController,
    evaFlowChecker,
    evaBaseServerBot,
    nftLimitOrderFlowProxy,
  };
};
