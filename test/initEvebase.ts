'use strict';
import { config } from 'dotenv';
/* eslint-disable prettier/prettier */
// import chai, { expect } from "chai";
import { ethers } from 'hardhat';
import { help } from '../scripts/help';
import { EvaFlowRandomChecker } from '../typechain';

export const initEvebase = async function initEvebase(debug: boolean = false) {
  // Hardhat always runs the compile task when running scripts with its command
  const EvabaseConfig = await ethers.getContractFactory('EvabaseConfig');
  const evabaseConfig = await EvabaseConfig.deploy();
  const ownerO = await ethers.getSigners();
  debug && console.log(`deployer owner : ${ownerO[0].address}`);
  await evabaseConfig.deployed();
  debug && console.log(`evabaseConfig: ${evabaseConfig.address}`);

  const EvaSafesFactory = await ethers.getContractFactory('EvaSafesFactory');
  const evaSafesFactory = await EvaSafesFactory.deploy(evabaseConfig.address);

  await evaSafesFactory.deployed();

  debug && console.log(`evaSafesFactory: ${evaSafesFactory.address}`);

  // 3 EvaFlowController
  const EvaFlowController = await ethers.getContractFactory('EvaFlowController');
  const evaFlowController = await EvaFlowController.deploy();
  await evaFlowController.deployed();
  await evaFlowController.initialize(evabaseConfig.address, evaSafesFactory.address);

  const flowExecutor = await help.deploy('EvaFlowExecutor', [evaFlowController.address], ownerO[0]);
  debug && console.log(`flowExecutor: ${flowExecutor.address}`);

  // 4
  const evaFlowChecker = (await help.deploy('EvaFlowRandomChecker', [evabaseConfig.address])) as EvaFlowRandomChecker;
  debug && console.log(`evaFlowChecker: ${evaFlowChecker.address}`);
  // 5

  const EvaFlowChainLinkKeeperBot = await ethers.getContractFactory('EvaFlowChainLinkKeeperBot');
  // eslint-disable-next-line max-len
  const evaFlowChainLinkKeeperBot = await EvaFlowChainLinkKeeperBot.deploy(
    evabaseConfig.address,
    evaFlowChecker.address,
    evaFlowController.address,
  );
  await evaFlowChainLinkKeeperBot.deployed();
  debug && console.log(`evaFlowChainLinkKeeperBot: ${evaFlowChainLinkKeeperBot.address}`);

  const EvaBaseServerBot = await ethers.getContractFactory('EvaBaseServerBot');
  const evaBaseServerBot = await EvaBaseServerBot.deploy(evabaseConfig.address, evaFlowChecker.address);
  await evaBaseServerBot.deployed();
  debug && console.log(`evaBaseServerBot: ${evaBaseServerBot.address}`);

  await evabaseConfig.setControl(evaFlowController.address);

  await evabaseConfig.setBytes32Item(
    ethers.utils.keccak256(ethers.utils.toUtf8Bytes('FLOW_EXECUTOR')),
    ethers.utils.hexZeroPad(flowExecutor.address, 32),
  );

  const NftLimitOrderFlowProxy = await ethers.getContractFactory('NftLimitOrderFlowProxy');
  const factory = evaSafesFactory.address;
  const nftLimitOrderFlowProxy = await NftLimitOrderFlowProxy.deploy(evabaseConfig.address, factory, 'EVABASE', '1');
  await nftLimitOrderFlowProxy.deployed();
  debug && console.log('NftLimitOrderFlowProxy:', nftLimitOrderFlowProxy.address);
  return {
    evabaseConfig,
    evaSafesFactory,
    evaFlowController,
    evaFlowChecker,
    evaBaseServerBot,
    evaFlowChainLinkKeeperBot,
    nftLimitOrderFlowProxy,
    flowExecutor,
  };
};
