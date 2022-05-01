'use strict';
import { config } from 'dotenv';
/* eslint-disable prettier/prettier */
// import chai, { expect } from "chai";
import { ethers } from 'hardhat';

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
  const EvaFlowChecker = await ethers.getContractFactory('EvaFlowChecker');
  const evaFlowChecker = await EvaFlowChecker.deploy(evabaseConfig.address);
  await evaFlowChecker.deployed();
  console.log(`evaFlowChecker: ${evaFlowChecker.address}`);
  // 5
  const EvaFlowChainLinkKeeperBot = await ethers.getContractFactory('EvaFlowChainLinkKeeperBot');


  const evaFlowChainLinkKeeperBot = await EvaFlowChainLinkKeeperBot.deploy(
    evabaseConfig.address,
    evaFlowChecker.address,

    // evaFlowController.address,

    // evaFlowController.address,

    // store.get("linkToken"),
    store.get('chainlinkKeeperRegistry'),
    // store.get("chainlinkUpkeepRegistrationRequests")
  );
  await evaFlowChainLinkKeeperBot.deployed();

  console.log(`evaFlowChainLinkKeeperBot: ${evaFlowChainLinkKeeperBot.address}`);

  // await config.setWalletFactory(factory.address);
  // await config.addKeeper(anyKeeper.address);

  const EvaBaseServerBot = await ethers.getContractFactory('EvaBaseServerBot');
  const evaBaseServerBot = await EvaBaseServerBot.deploy(
    evabaseConfig.address,
    evaFlowChecker.address,

  );
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
    evaFlowChainLinkKeeperBot,
    evaBaseServerBot,
    nftLimitOrderFlowProxy,
  };

};
