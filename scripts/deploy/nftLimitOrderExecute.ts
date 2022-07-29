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

  const order = {
    owner: ownerO[0].address,
    assetToken: ownerO[0].address,
    amount: '1000',
    price: '1',
    deadline: Math.ceil(new Date().getTime() / 1000) + 60 * 60 * 1,
    tokenId: 342905,
    salt: '18992909',
  };

  const evaSafes = await evaSafesFactoryContract.get(ownerO[0].address);
  console.log(`safes: ${evaSafes}`);

  const EvaSafes = await ethers.getContractFactory('EvaSafes');
  const evaSafesContract = EvaSafes.attach(evaSafes);
  const safesOwner = await evaSafesContract.owner();
  console.log(`safesOwner: ${safesOwner}`);
  const nftLimitOrderFlowProxy = await ethers.getContractFactory('NftLimitOrderFlowProxy');
  const data = nftLimitOrderFlowProxy.interface.encodeFunctionData('create', [
    store.get('evaFlowController'),
    store.get('NftLimitOrderFlow'),
    1,
    200000,
    'buy 1 NFT',
    order,
  ]);
  // await evaSafesContract.proxy(store.get('NftLimitOrderFlow'), 1, data, {
  //   value: ethers.utils.parseEther('0.01'),
  // });
  // const an_other_bal = await ethers.provider.getBalance(acceptEther.address);
  const evaSafesContractBal = await ethers.provider.getBalance(evaSafesContract.address);
  const nftLimitOrderFlowProxyBal = await ethers.provider.getBalance(store.get('NftLimitOrderFlow'));
  const evaFlowControllerBal = await ethers.provider.getBalance(store.get('evaFlowController'));
  console.log('evaSafesContractBal before=', evaSafesContractBal);
  console.log('nftLimitOrderFlowProxyBal before=', nftLimitOrderFlowProxyBal);
  console.log('evaFlowControllerBal=', evaFlowControllerBal);
  // pause
  // const pauseData = nftLimitOrderFlowProxy.interface.encodeFunctionData('pauseFlow', [
  //   store.get('evaFlowController'),
  //   1,
  // ]);
  // await evaSafesContract.proxy(store.get('NftLimitOrderFlow'), 1, pauseData);
  // start
  // const startData = nftLimitOrderFlowProxy.interface.encodeFunctionData('startFlow', [
  //   store.get('evaFlowController'),
  //   1,
  // ]);
  // await evaSafesContract.proxy(store.get('NftLimitOrderFlow'), 1, startData);
  // pause
  // await evaSafesContract.proxy(store.get('NftLimitOrderFlow'), 1, pauseData);
  // cancel
  const cancelNftData = nftLimitOrderFlowProxy.interface.encodeFunctionData('closeFlow', [
    store.get('evaFlowController'),
    '1',
  ]);

  // await evaSafesContract.proxy(store.get('NftLimitOrderFlow'), 1, cancelNftData);

  const evaSafesContractBal1 = await ethers.provider.getBalance(evaSafesContract.address);
  const nftLimitOrderFlowProxyBal1 = await ethers.provider.getBalance(store.get('NftLimitOrderFlow'));
  console.log('evaSafesContractBal after=', evaSafesContractBal1);
  console.log('nftLimitOrderFlowProxyBal after=', nftLimitOrderFlowProxyBal1);
  // console.log(await evaFlowController.getFlowMetas(1));
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

  // await evaFlowController.closeFlow(1, myStructData);
  // task
  const usdtAdd = '0xC272e20C2d0F8fb7B9B05B9F2Ba4407E95928CbF';
  const MockERC20 = await ethers.getContractFactory('MockERC20');
  const data1 = MockERC20.interface.encodeFunctionData('mint', [1000]);
  const data2 = MockERC20.interface.encodeFunctionData('mint', [1000]);
  // const data1 = MockERC20.interface.encodeFunctionData('approve', [store.get('evaFlowController'), 1e10]);
  // const data2 = MockERC20.interface.encodeFunctionData('approve', [store.get('evaFlowController'), 1e10]);

  const myStructData1 = ethers.utils.AbiCoder.prototype.encode(['address', 'uint120', 'bytes'], [usdtAdd, 0, data1]);
  const myStructData2 = ethers.utils.AbiCoder.prototype.encode(['address', 'uint120', 'bytes'], [usdtAdd, 0, data2]);
  const inputs_ = [myStructData1, myStructData2];

  const opsFlowProxy = await ethers.getContractFactory('OpsFlowProxy');
  // const opsFlowProxyContract = opsFlowProxy.attach(store.get('opsFlowProxy'));
  // const tx1 = await opsFlowProxyContract.enableERC1820();
  // console.log('tx1', tx1.hash);
  const gasFund = 1e17;
  const callData = opsFlowProxy.interface.encodeFunctionData('create', [
    // app.controler.address,
    store.get('evaFlowController'),
    // opsFlowProxy.address,
    store.get('opsFlowProxy'),
    KeepNetWork.ChainLink,
    help.toFullNum(gasFund),
    'Erc20Mint1',
    {
      owner: ownerO[0].address,
      inputs: inputs_,
      startTime: 1653403979,
      deadline: Math.ceil(new Date().getTime() / 1000) + 60 * 60 * 1,
      lastExecTime: 0,
      interval: 60,
    },
  ]);

  const EvaFlowController = await ethers.getContractFactory('EvaFlowController');
  const evaFlowController = EvaFlowController.attach(store.get('evaFlowController'));
  const flowId = (await evaFlowController.getFlowMetaSize()).toNumber();

  await evaSafesContract.proxy(store.get('opsFlowProxy'), HowToCall.Delegate, callData, {
    value: help.toFullNum(gasFund),
  });

  // await evaSafesContract.withdraw('0x0000000000000000000000000000000000000000', '1000000000000000000');

  // eslint-disable-next-line max-len
  const cancelData = opsFlowProxy.interface.encodeFunctionData('closeFlow', [store.get('evaFlowController'), 12]);

  // const tx = await evaSafesContract.proxy(store.get('opsFlowProxy'), 1, cancelData);

  // console.log('tx=', tx);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
