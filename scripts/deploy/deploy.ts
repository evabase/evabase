'use strict';
// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import '@openzeppelin/hardhat-upgrades';
import { ethers, upgrades } from 'hardhat';
// import { EvabaseConfig } from '../../typechain';
// eslint-disable-next-line node/no-missing-import
import { store } from '../help';
// const store = require('data-store')({
//   // path: process.cwd() + "/deployInfo.json",
//   path: process.cwd() + '/scripts/deploy/rinkeby.json',
// });

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
  let tx;
  // 1 config
  let evabaseConfigAddr = store.get('evabaseConfig');
  let evabaseConfig;
  const EvabaseConfig = await ethers.getContractFactory('EvabaseConfig');
  if (typeof evabaseConfigAddr === 'undefined') {
    evabaseConfig = await EvabaseConfig.deploy();

    await evabaseConfig.deployed();
    console.log(`evabaseConfig: ${evabaseConfig.address}`);
    store.set('evabaseConfig', evabaseConfig.address);
    evabaseConfigAddr = evabaseConfig.address;
  } else {
    evabaseConfig = EvabaseConfig.attach(evabaseConfigAddr);
  }

  // 2 EvaSafesFactory
  let evaSafesFactoryAddr = store.get('evaSafesFactory');
  const EvaSafesFactory = await ethers.getContractFactory('EvaSafesFactory');
  let evaSafesFactory;
  if (typeof evaSafesFactoryAddr === 'undefined') {
    evaSafesFactory = await EvaSafesFactory.deploy(evabaseConfigAddr);

    await evaSafesFactory.deployed();
    store.set('evaSafesFactory', evaSafesFactory.address);
    console.log(`evaSafesFactory: ${evaSafesFactory.address}`);
    evaSafesFactoryAddr = evaSafesFactory.address;
  } else {
    evaSafesFactory = EvaSafesFactory.attach(evaSafesFactoryAddr);
  }

  // 3 EvaFlowController
  let evaFlowControllerAddr = store.get('evaFlowController');

  let evaFlowController;
  const EvaFlowController = await ethers.getContractFactory('EvaFlowController');
  if (typeof evaFlowControllerAddr === 'undefined') {
    // const evaFlowController = await EvaFlowController.deploy(evabaseConfigAddr, evaSafesFactoryAddr);
    // await evaFlowController.deployed();
    evaFlowController = await upgrades.deployProxy(
      EvaFlowController,
      [store.get('evabaseConfig'), store.get('evaSafesFactory')],
      { unsafeAllow: ['delegatecall'] },
    );

    store.set('evaFlowController', evaFlowController.address);
    console.log(`evaFlowController: ${evaFlowController.address}`);
    evaFlowControllerAddr = evaFlowController.address;
  } else {
    evaFlowController = EvaFlowController.attach(evaFlowControllerAddr);
  }

  tx = await evabaseConfig.setControl(evaFlowController.address);
  console.log('setControl hash=', tx.hash);

  // 4 EvaFlowChecker
  let evaFlowCheckerAddr = store.get('evaFlowChecker');
  if (typeof evaFlowCheckerAddr === 'undefined') {
    const EvaFlowChecker = await ethers.getContractFactory('EvaFlowRandomChecker');
    const evaFlowChecker = await EvaFlowChecker.deploy(evabaseConfigAddr);
    await evaFlowChecker.deployed();
    console.log(`evaFlowChecker: ${evaFlowChecker.address}`);
    store.set('EvaFlowRandomChecker', evaFlowChecker.address);
    evaFlowCheckerAddr = evaFlowChecker.address;
  }

  // 5 EvaFlowChainLinkKeeperBot
  let evaFlowChainLinkKeeperBotAddr = store.get('evaFlowChainLinkKeeperBot');
  const EvaFlowChainLinkKeeperBot = await ethers.getContractFactory('EvaFlowChainLinkKeeperBot');
  let evaFlowChainLinkKeeperBot;
  if (typeof evaFlowChainLinkKeeperBotAddr === 'undefined') {
    evaFlowChainLinkKeeperBot = await EvaFlowChainLinkKeeperBot.deploy(
      evabaseConfigAddr,
      evaFlowCheckerAddr,
      store.get('others.ChainlinkKeeperRegistry'),
    );
    await evaFlowChainLinkKeeperBot.deployed();
    console.log(`evaFlowChainLinkKeeperBot: ${evaFlowChainLinkKeeperBot.address}`);
    store.set('evaFlowChainLinkKeeperBot', evaFlowChainLinkKeeperBot.address);
    evaFlowChainLinkKeeperBotAddr = evaFlowChainLinkKeeperBot.address;
  } else {
    evaFlowChainLinkKeeperBot = EvaFlowChainLinkKeeperBot.attach(evaFlowChainLinkKeeperBotAddr);
  }

  tx = await evaFlowChainLinkKeeperBot.setEvaCheck(evaFlowCheckerAddr);
  console.log('setEvaCheck hash=', tx.hash);

  // 6 NftLimitOrder
  let nftLimitOrderFlowProxyAddr = store.get('nftLimitOrderFlowProxy');
  if (typeof nftLimitOrderFlowProxyAddr === 'undefined') {
    const NftLimitOrderFlowProxy = await ethers.getContractFactory('NftLimitOrderFlowProxy');
    const nftLimitOrderFlowProxy = await NftLimitOrderFlowProxy.deploy(
      evabaseConfigAddr,
      evaSafesFactoryAddr,
      'EVABASE',
      '1',
    );
    await nftLimitOrderFlowProxy.deployed();
    console.log('NftLimitOrderFlow deployed to:', nftLimitOrderFlowProxy.address);
    store.set('NftLimitOrderFlow', nftLimitOrderFlowProxy.address);
    nftLimitOrderFlowProxyAddr = nftLimitOrderFlowProxy.address;
  }
  await evaSafesFactory.create(ownerO[0].address);
  const evaSafes = await evaSafesFactory.get(ownerO[0].address);
  console.log(`safes: ${evaSafes}`);

  // 7 evabase bot
  let evaBaseServerBotAddr = store.get('evaBaseServerBot');
  if (typeof evaBaseServerBotAddr === 'undefined') {
    const EvaBaseServerBot = await ethers.getContractFactory('EvaBaseServerBot');
    const evaBaseServerBot = await EvaBaseServerBot.deploy(evabaseConfigAddr, evaFlowCheckerAddr);
    await evaBaseServerBot.deployed();
    console.log(`evaBaseServerBot: ${evaBaseServerBot.address}`);
    store.set('evaBaseServerBot', evaBaseServerBot.address);
    evaBaseServerBotAddr = evaBaseServerBot.address;
  }

  tx = await evabaseConfig.addKeeper(evaBaseServerBotAddr, 1);
  console.log('addKeeper evaBaseServerBot hash=', tx.hash);
  tx = await evabaseConfig.addKeeper(evaFlowChainLinkKeeperBotAddr, 0);
  console.log('addKeeper evaFlowChainLinkKeeperBot hash=', tx.hash);
  // 8 EvaFlowStatusUpkeep
  let evaFlowStatusUpkeepAddr = store.get('evaFlowStatusUpkeep');
  if (typeof evaFlowStatusUpkeepAddr === 'undefined') {
    const EvaFlowStatusUpkeep = await ethers.getContractFactory('EvaFlowStatusUpkeep');
    const evaFlowStatusUpkeep = await EvaFlowStatusUpkeep.deploy(store.get('evaFlowController'), 0);
    console.log(`evaFlowStatusUpkeep: ${evaFlowStatusUpkeep.address}`);
    store.set('evaFlowStatusUpkeep', evaFlowStatusUpkeep.address);
    evaFlowStatusUpkeepAddr = evaFlowStatusUpkeep.address;
  }

  tx = await evaFlowController.setFlowOperators(evaFlowStatusUpkeepAddr, true);
  console.log('setFlowOperators hash=', tx.hash);

  // 9 EvaFlowExecutor
  let evaFlowExecutorAddr = store.get('evaFlowExecutor');
  if (typeof evaFlowExecutorAddr === 'undefined') {
    const EvaFlowExecutor = await ethers.getContractFactory('EvaFlowExecutor');
    const evaFlowExecutor = await EvaFlowExecutor.deploy(evaFlowControllerAddr);
    console.log(`evaFlowExecutor: ${evaFlowExecutor.address}`);
    store.set('evaFlowExecutor', evaFlowExecutor.address);
    evaFlowExecutorAddr = evaFlowExecutor.address;
  }

  tx = await evabaseConfig.setBytes32Item(
    ethers.utils.keccak256(ethers.utils.toUtf8Bytes('FLOW_EXECUTOR')),
    ethers.utils.hexZeroPad(evaFlowExecutorAddr, 32),
  );
  console.log('setBytes32Item hash=', tx.hash);

  // 10 ops
  let opsFlowProxyAddr = store.get('opsFlowProxy');
  if (typeof opsFlowProxyAddr === 'undefined') {
    const OpsFlowProxy = await ethers.getContractFactory('OpsFlowProxy');
    const opsFlowProxy = await OpsFlowProxy.deploy(evabaseConfigAddr, evaSafesFactoryAddr);
    console.log(`opsFlowProxy: ${opsFlowProxy.address}`);
    store.set('opsFlowProxy', opsFlowProxy.address);
    opsFlowProxyAddr = opsFlowProxy.address;
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
