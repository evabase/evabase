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

  const evaSafesFactory = await ethers.getContractFactory('EvaSafesFactory');
  const evaSafesFactoryContract = await evaSafesFactory.attach(store.get('evaSafesFactory'));

  const order = {
    owner: ownerO[0].address,
    assetToken: ownerO[0].address,
    amount: '1000',
    price: '1',
    expireTime: '1680355507',
    tokenId: 342905,
    salt: '1899909',
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
    order,
  ]);
  await evaSafesContract.proxy(store.get('NftLimitOrderFlow'), 1, data, {
    value: ethers.utils.parseEther('0.01'),
  });
  // const an_other_bal = await ethers.provider.getBalance(acceptEther.address);
  const evaSafesContractBal = await ethers.provider.getBalance(evaSafesContract.address);
  const nftLimitOrderFlowProxyBal = await ethers.provider.getBalance(store.get('NftLimitOrderFlow'));
  const evaFlowControllerBal = await ethers.provider.getBalance(store.get('evaFlowController'));
  console.log('evaSafesContractBal before=', evaSafesContractBal);
  console.log('nftLimitOrderFlowProxyBal before=', nftLimitOrderFlowProxyBal);
  console.log('evaFlowControllerBal=', evaFlowControllerBal);
  // pause
  const pauseData = nftLimitOrderFlowProxy.interface.encodeFunctionData('pauseFlow', [
    store.get('evaFlowController'),
    1,
  ]);
  await evaSafesContract.proxy(store.get('NftLimitOrderFlow'), 1, pauseData);
  // start
  const startData = nftLimitOrderFlowProxy.interface.encodeFunctionData('startFlow', [
    store.get('evaFlowController'),
    1,
  ]);
  await evaSafesContract.proxy(store.get('NftLimitOrderFlow'), 1, startData);
  // pause
  await evaSafesContract.proxy(store.get('NftLimitOrderFlow'), 1, pauseData);
  // cancel
  const cancelData = nftLimitOrderFlowProxy.interface.encodeFunctionData('destroyFlow', [
    store.get('evaFlowController'),
    1,
  ]);

  await evaSafesContract.proxy(store.get('NftLimitOrderFlow'), 1, cancelData);

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

  // await evaFlowController.destroyFlow(1, myStructData);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
