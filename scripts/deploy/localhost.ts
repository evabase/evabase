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
// const store = require('data-store')({
//   // path: process.cwd() + "/deployInfo.json",
//   path: process.cwd() + '/scripts/deploy/localhost.json',
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
  // 1 config
  const EvabaseConfig = await ethers.getContractFactory('EvabaseConfig');
  const evabaseConfig = await EvabaseConfig.deploy();

  await evabaseConfig.deployed();
  console.log(`evabaseConfig: ${evabaseConfig.address}`);
  store.set('evabaseConfig', evabaseConfig.address);
  // 2 EvaSafesFactory
  const EvaSafesFactory = await ethers.getContractFactory('EvaSafesFactory');
  const evaSafesFactory = await EvaSafesFactory.deploy(evabaseConfig.address);

  await evaSafesFactory.deployed();
  store.set('evaSafesFactory', evaSafesFactory.address);
  console.log(`evaSafesFactory: ${evaSafesFactory.address}`);

  await evaSafesFactory.create(ownerO[0].address);
  const evaSafes = await evaSafesFactory.get(ownerO[0].address);
  console.log(`safes: ${evaSafes}`);

  const EvaSafes = await ethers.getContractFactory('EvaSafes');
  const evaSafesContract = EvaSafes.attach(evaSafes);
  const safesOwner = await evaSafesContract.owner();
  console.log(`safesOwner: ${safesOwner}`);

  // 3 EvaFlowController
  const EvaFlowController = await ethers.getContractFactory('EvaFlowController');
  const evaFlowController = await EvaFlowController.deploy(evabaseConfig.address, evaSafesFactory.address);
  await evaFlowController.deployed();
  await evabaseConfig.setControl(evaFlowController.address);
  store.set('evaFlowController', evaFlowController.address);
  console.log(`evaFlowController: ${evaFlowController.address}`);
  // 4 EvaFlowChecker
  const EvaFlowChecker = await ethers.getContractFactory('EvaFlowChecker');
  const evaFlowChecker = await EvaFlowChecker.deploy(
    evabaseConfig.address,
    // evaFlowController.address
  );
  await evaFlowChecker.deployed();
  console.log(`evaFlowChecker: ${evaFlowChecker.address}`);
  store.set('evaFlowChecker', evaFlowChecker.address);
  // 5 EvaFlowChainLinkKeeperBot
  const EvaFlowChainLinkKeeperBot = await ethers.getContractFactory('EvaFlowChainLinkKeeperBot');

  const evaFlowChainLinkKeeperBot = await EvaFlowChainLinkKeeperBot.deploy(
    evabaseConfig.address,
    evaFlowChecker.address,
    // evaFlowController.address,
    // store.get("linkToken"),
    store.get('others.ChainlinkKeeperRegistry'),

    // store.get("chainlinkUpkeepRegistrationRequests")
  );
  await evaFlowChainLinkKeeperBot.deployed();
  console.log(`evaFlowChainLinkKeeperBot: ${evaFlowChainLinkKeeperBot.address}`);
  store.set('evaFlowChainLinkKeeperBot', evaFlowChainLinkKeeperBot.address);

  // 6 NftLimitOrder
  // const NftLimitOrderFlow = await ethers.getContractFactory(
  //   "NftLimitOrderFlow"
  // ); NftLimitOrderFlowProxy

  const NftLimitOrderFlowProxy = await ethers.getContractFactory('NftLimitOrderFlowProxy');
  // console.log("NftLimitOrderFlow deployed to:", NftLimitOrderFlow.address);
  // store.set("NftLimitOrderFlow", NftLimitOrderFlow.address);

  const factory = evaSafesFactory.address;
  // const upgrade = await upgrades.deployProxy(NftLimitOrderFlow, [
  //   evabaseConfig.address,
  //   factory,
  //   "EVABASE",
  //   "1",
  // ]);

  // await upgrade.deployed();
  const nftLimitOrderFlowProxy = await NftLimitOrderFlowProxy.deploy(evabaseConfig.address, factory, 'EVABASE', '1');

  await nftLimitOrderFlowProxy.deployed();

  console.log('NftLimitOrderFlow deployed to:', nftLimitOrderFlowProxy.address);
  store.set('NftLimitOrderFlow', nftLimitOrderFlowProxy.address);

  // const Order = [
  //   { name: "owner", type: "addess" },
  //   { name: "assetToken", type: "addess" },
  //   { name: "amount", type: "uint256" },
  //   { name: "price", type: "uint256" },
  //   { name: "expireTime", type: "uint256" },
  //   { name: "tokenId", type: "uint256" },
  //   { name: "salt", type: "uint256" },
  // ];

  // const order = {
  //   owner: string;
  //   assetToken: string;
  //   amount: BigNumberish;
  //   price: BigNumberish;
  //   expireTime: BigNumberish;
  //   tokenId: BigNumberish;
  //   salt: BigNumberish;
  // }

  // const order = [
  //   ownerO[0].address,
  //   ownerO[0].address,
  //   100,
  //   1,
  //   16803555107,
  //   342905,
  //   1899909,
  // ];
  const order = {
    owner: ownerO[0].address,
    assetToken: ownerO[0].address,
    amount: '1000',
    price: '1',
    expireTime: '1680355507',
    tokenId: 342905,
    salt: '1899909',
  };

  // const myStructData = ethers.utils.AbiCoder.prototype.encode(
  //   [
  //     "address",
  //     "address",
  //     "uint256",
  //     "uint256",
  //     "uint256",
  //     "uint256",
  //     "uint256",
  //   ],
  //   [ownerO[0].address, ownerO[0].address, 100, 1, 16803555107, 342905, 1899909]
  // );

  // const tx = await myContract.myFunction(myStructData, {
  //   gasLimit: ethers.utils.parseUnits("1000000", "wei"),
  // });

  // const data = ethers.utils.defaultAbiCoder.encode(["Order"], [order]);

  // console.log(`data: ${myStructData}`);

  // IEvaFlowController ser,
  // INftLimitOrder nftLimitOrder,
  // KeepNetWork network,
  // uint256 gasFee,
  // Order memory order

  // const tx = await nftLimitOrderFlowProxy.create(
  //   evaFlowController.address,
  //   nftLimitOrderFlowProxy.address,
  //   1,
  //   200000,
  //   order,
  //   {
  //     value: ethers.utils.parseEther("0.01"),
  //   }
  // );

  // console.log(`tx: ${tx}`);
  // console.log(await evaFlowController.getFlowMetas(1));
  // await nftLimitOrderFlowProxy.pauseFlow(evaFlowController.address, 1);
  // console.log(`tx1`);
  // console.log(
  //   await nftLimitOrderFlowProxy._getInfo(evaFlowController.address, 1)
  // );

  // await nftLimitOrderFlowProxy.startFlow(evaFlowController.address, 1);
  // await nftLimitOrderFlowProxy.pauseFlow(evaFlowController.address, 1);
  // console.log(`tx2`);
  // await nftLimitOrderFlowProxy.destroyFlow(evaFlowController.address, 1);
  // console.log(`tx3`);

  // bytes memory data
  /**
   * const input = contract.interface.encodeFunctionData(method, args)
    // {From:,to:,data:}
    // eslint-disable-next-line max-len
    return ethers.utils.defaultAbiCoder.encode(["address", "bytes", "uint256"], [contract.address, input,
       typeof (value) === "undefined" ? 0 : value]);
   */
  const data = nftLimitOrderFlowProxy.interface.encodeFunctionData('create', [
    evaFlowController.address,
    nftLimitOrderFlowProxy.address,
    1,
    200000,
    order,
  ]);
  await evaSafesContract.proxy(nftLimitOrderFlowProxy.address, 1, data, {
    value: ethers.utils.parseEther('0.01'),
  });
  // const an_other_bal = await ethers.provider.getBalance(acceptEther.address);
  const evaSafesContractBal = await ethers.provider.getBalance(evaSafesContract.address);
  const nftLimitOrderFlowProxyBal = await ethers.provider.getBalance(nftLimitOrderFlowProxy.address);
  const evaFlowControllerBal = await ethers.provider.getBalance(evaFlowController.address);
  console.log('evaSafesContractBal before=', evaSafesContractBal);
  console.log('nftLimitOrderFlowProxyBal before=', nftLimitOrderFlowProxyBal);
  console.log('evaFlowControllerBal=', evaFlowControllerBal);
  // pause
  const pauseData = nftLimitOrderFlowProxy.interface.encodeFunctionData('pauseFlow', [evaFlowController.address, 1]);
  await evaSafesContract.proxy(nftLimitOrderFlowProxy.address, 1, pauseData);
  // start
  const startData = nftLimitOrderFlowProxy.interface.encodeFunctionData('startFlow', [evaFlowController.address, 1]);
  await evaSafesContract.proxy(nftLimitOrderFlowProxy.address, 1, startData);
  // pause
  await evaSafesContract.proxy(nftLimitOrderFlowProxy.address, 1, pauseData);
  await evaSafesContract.proxy(nftLimitOrderFlowProxy.address, 1, startData);
  // cancel
  const cancelData = nftLimitOrderFlowProxy.interface.encodeFunctionData('destroyFlow', [evaFlowController.address, 1]);

  await evaSafesContract.proxy(nftLimitOrderFlowProxy.address, 1, cancelData);

  const evaSafesContractBal1 = await ethers.provider.getBalance(evaSafesContract.address);
  const nftLimitOrderFlowProxyBal1 = await ethers.provider.getBalance(nftLimitOrderFlowProxy.address);
  console.log('evaSafesContractBal after=', evaSafesContractBal1);
  console.log('nftLimitOrderFlowProxyBal after=', nftLimitOrderFlowProxyBal1);
  console.log(await evaFlowController.getFlowMetas(1));

  const withDrawData = evaFlowController.interface.encodeFunctionData('withdrawFundByUser', [
    '0x0000000000000000000000000000000000000000',
    ethers.utils.parseEther('0.01'),
  ]);

  const addFundByUser = evaFlowController.interface.encodeFunctionData('addFundByUser', [
    '0x0000000000000000000000000000000000000000',
    ethers.utils.parseEther('0.01'),
    evaSafes,
  ]);

  let evaFlowControllerBal1 = await ethers.provider.getBalance(evaFlowController.address);

  let userBal1 = await ethers.provider.getBalance(ownerO[0].address);
  console.log('userBal1 before=', userBal1);
  console.log('evaFlowControllerBal1 before=', evaFlowControllerBal1);
  let evaSafesBal1 = await ethers.provider.getBalance(evaSafes);
  console.log('evaSafes before=', evaSafesBal1);

  await evaSafesContract.proxy(evaFlowController.address, 0, addFundByUser, {
    value: ethers.utils.parseEther('0.01'),
  });
  evaFlowControllerBal1 = await ethers.provider.getBalance(evaFlowController.address);
  userBal1 = await ethers.provider.getBalance(ownerO[0].address);
  console.log('userBal1 mid=', userBal1);
  console.log('evaFlowControllerBal1 mid=', evaFlowControllerBal1);
  evaSafesBal1 = await ethers.provider.getBalance(evaSafes);
  console.log('evaSafes mid=', evaSafesBal1);

  await evaSafesContract.proxy(evaFlowController.address, 0, withDrawData);
  evaFlowControllerBal1 = await ethers.provider.getBalance(evaFlowController.address);
  userBal1 = await ethers.provider.getBalance(ownerO[0].address);
  console.log('userBal1 after=', userBal1);
  console.log('evaFlowControllerBal1 after=', evaFlowControllerBal1);
  evaSafesBal1 = await ethers.provider.getBalance(evaSafes);
  console.log('evaSafes after=', evaSafesBal1);
  // await evaFlowController.createFlow(
  //   "ACE",
  //   1, // evabaseKeep
  //   upgrade.address,
  //   myStructData,
  //   200000,
  //   {
  //     value: ethers.utils.parseEther("0.01"),
  //   }
  // );
  // await evaFlowController.pauseFlow(1, myStructData);
  // await evaFlowController.startFlow(1, myStructData);

  // await evaFlowController.destroyFlow(1, myStructData);
  // 7 evabase bot
  const EvaBaseServerBot = await ethers.getContractFactory('EvaBaseServerBot');
  const evaBaseServerBot = await EvaBaseServerBot.deploy(
    evabaseConfig.address,
    evaFlowChecker.address,
    // evaFlowController.address,
  );
  await evaBaseServerBot.deployed();
  console.log(`evaBaseServerBot: ${evaBaseServerBot.address}`);
  store.set('evaBaseServerBot', evaBaseServerBot.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
