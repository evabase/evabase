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
  const user = ownerO[0].address;
  console.log(`deployer owner : ${user}`);

  const evaSafesFactory = await ethers.getContractFactory('EvaSafesFactory');
  const evaSafesFactoryContract = await evaSafesFactory.attach(store.get('evaSafesFactory'));

  const evaSafes = await evaSafesFactoryContract.get(ownerO[0].address);
  console.log(`safes: ${evaSafes}`);

  const EvaSafes = await ethers.getContractFactory('EvaSafes');
  const evaSafesContract = EvaSafes.attach(evaSafes);

  // start 0.0000002weth swap usdc
  const weth = '0xc778417E063141139Fce010982780140Aa0cD5Ab';
  const SwapRouter02 = '0x68b3465833fb72A70ecDF485E0e4C7bD8665Fc45';
  const MockERC20 = await ethers.getContractFactory('MockERC20');
  const wethContract = MockERC20.attach(weth);
  // 1.user  approve weth to safes
  const tx = wethContract.approve(evaSafes, help.toFullNum(100 * 10e18));
  console.log((await tx).hash);

  // Assemble three Tasks
  // 1.1 Task one transfer weth From user to safes
  const data0 = MockERC20.interface.encodeFunctionData('transferFrom', [user, evaSafes, help.toFullNum(1 * 10e15)]);
  const encode0 = ethers.utils.AbiCoder.prototype.encode(['address', 'uint120', 'bytes'], [weth, 0, data0]);
  // 1.2 Task two safe approve weth to safes
  const data1 = MockERC20.interface.encodeFunctionData('approve', [SwapRouter02, help.toFullNum(100 * 10e18)]);
  const encode1 = ethers.utils.AbiCoder.prototype.encode(['address', 'uint120', 'bytes'], [weth, 0, data1]);

  // 1.3 Task three   sdk获得 执行Uniswap的Swap的Input
  const data2 =
    // eslint-disable-next-line max-len
    '0x5ae401dc0000000000000000000000000000000000000000000000000000000062ce7fad00000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000e404e45aaf000000000000000000000000c778417e063141139fce010982780140aa0cd5ab0000000000000000000000004dbcdf9b62e891a7cec5a2568c3f4faf9e8abe2b000000000000000000000000000000000000000000000000000000000000271000000000000000000000000000000000000000000000000000000000000000010000000000000000000000000000000000000000000000000000002e90edd000000000000000000000000000000000000000000000000000000000000c350a6a000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000';

  const encode2 = ethers.utils.AbiCoder.prototype.encode(['address', 'uint120', 'bytes'], [SwapRouter02, 0, data2]);
  const inputs_ = [encode0, encode1, encode2];

  // 2.tasks submit to opsFlow
  const opsFlowProxy = await ethers.getContractFactory('OpsFlowProxy');
  const gasFund = 1e15;
  const callData = opsFlowProxy.interface.encodeFunctionData('create', [
    store.get('evaFlowController'),
    store.get('opsFlowProxy'),
    KeepNetWork.ChainLink,
    help.toFullNum(gasFund),
    'uniswapv3-luo',
    {
      owner: ownerO[0].address,
      inputs: inputs_,
      startTime: Math.ceil(new Date().getTime() / 1000),
      deadline: Math.ceil(new Date().getTime() / 1000) + 60 * 60 * 1,
      lastExecTime: 0,
      interval: 60,
    },
  ]);

  const tx1 = await evaSafesContract.proxy(store.get('opsFlowProxy'), HowToCall.Delegate, callData, {
    value: help.toFullNum(gasFund),
  });
  console.log('proxy tx=', tx1);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
