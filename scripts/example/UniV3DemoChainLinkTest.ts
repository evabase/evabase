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
  // await chainLinkCheck('0x0000000000000000000000000000000000000000000000000000000000000001');
  // await tryExec('0x0000000000000000000000000000000000000000000000000000000000000001');
  await getPerformData(148);
}

async function realExec(checkdata: string) {
  const ownerO = await ethers.getSigners();
  const user = ownerO[0].address;
  console.log(`deployer owner : ${user}`);

  const evaSafesFactory = await ethers.getContractFactory('EvaSafesFactory');
  const evaSafesFactoryContract = await evaSafesFactory.attach(store.get('evaSafesFactory'));

  const evaSafes = await evaSafesFactoryContract.get(ownerO[0].address);
  console.log(`safes: ${evaSafes}`);

  const EvaSafes = await ethers.getContractFactory('EvaSafes');
  const evaSafesContract = EvaSafes.attach(evaSafes);
  const safesOwner = await evaSafesContract.owner();
  // task
  const weth = '0xc778417e063141139fce010982780140aa0cd5ab';
  // const usdc = '0x4dbcdf9b62e891a7cec5a2568c3f4faf9e8abe2b';
  const SwapRouter02 = '0x68b3465833fb72a70ecdf485e0e4c7bd8665fc45';
  const MockERC20 = await ethers.getContractFactory('MockERC20');
  const wethContract = MockERC20.attach(weth);

  // 1.approve
  const approveWeth = MockERC20.interface.encodeFunctionData('approve', [SwapRouter02, help.toFullNum(100 * 10e18)]);
  const approvetx0 = await evaSafesContract.proxy(weth, HowToCall.Call, approveWeth);
  console.log(await approvetx0.wait());
  console.log(approvetx0.hash);
  // 2.transferFrom
  const transferFromdata = MockERC20.interface.encodeFunctionData('transferFrom', [
    user,
    evaSafes,
    help.toFullNum(10 * 10e15),
  ]);
  const tx1 = await evaSafesContract.proxy(weth, HowToCall.Call, transferFromdata);
  console.log(await tx1.wait());
  console.log(tx1.hash);
  // 3. sdk 执行Uniswap的Swap的Input
  const data2 =
    // eslint-disable-next-line max-len
    '0x5ae401dc0000000000000000000000000000000000000000000000000000000062ce3de90000000000000000000000000000000000000000000000000000000000000040000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000124b858183f000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000800000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000012309ce540000000000000000000000000000000000000000000000000000000025556ab6e050000000000000000000000000000000000000000000000000000000000000059c778417e063141139fce010982780140aa0cd5ab0001f4c7ad46e0b8a400bb3c915120d284aafba8fc4735000bb8c778417e063141139fce010982780140aa0cd5ab0027104dbcdf9b62e891a7cec5a2568c3f4faf9e8abe2b0000000000000000000000000000000000000000000000000000000000000000000000';
  const tx0 = await evaSafesContract.proxy(SwapRouter02, HowToCall.Call, data2);
  console.log(await tx0.wait());
  console.log(tx0.hash);
}

async function chainLinkCheck(checkdata: string) {
  const chainlink = await ethers.getContractAt('KeeperRegistryInterface', store.get('others.ChainlinkKeeperRegistry'));

  const keeper = '0x426a9b94ae341751cb248d81ddbe3cccd16dc493';
  const zero = new ethers.VoidSigner(ethers.constants.AddressZero, ethers.provider);
  console.log(await chainlink.connect(zero).checkUpkeep(801, keeper));
  // const config = await ethers.getContractAt('EvabaseConfig', store.get('evabaseConfig'));

  // console.log(await config.batchFlowNum());
  // console.log(await config.keepBotSizes(KeepNetWork.ChainLink));
  const bot = await ethers.getContractAt('EvaFlowChainLinkKeeperBot', store.get('evaFlowChainLinkKeeperBot'));
  // const checker = await ethers.getContractAt('EvaFlowRandomChecker', store.get('EvaFlowRandomChecker'));
  // console.log(await checker.config());
  // await checker.check(1, Math.ceil(new Date().getTime() / 1000), KeepNetWork.ChainLink);
  // console.log(await bot.evaFlowChecker());
  const result = await bot.checkUpkeep(checkdata);

  console.log(result);
}

async function tryExec(checkdata: string) {
  const chainlink = await ethers.getContractAt('KeeperRegistryInterface', store.get('others.ChainlinkKeeperRegistry'));
  const keeper = new ethers.VoidSigner('0x426a9b94ae341751cb248d81ddbe3cccd16dc493', ethers.provider);
  const zero = new ethers.VoidSigner(ethers.constants.AddressZero, ethers.provider);
  const bot = await ethers.getContractAt('EvaFlowChainLinkKeeperBot', store.get('evaFlowChainLinkKeeperBot'));
  const check = await ethers.getContractAt('EvaFlowRandomChecker', store.get('EvaFlowRandomChecker'));
  const result2 = await check.connect(zero).callStatic.check(1, 1, 0);
  console.log(result2);
  // const result = await bot.connect(zero).callStatic.checkUpkeep(checkdata);
  // const result1 = await chainlink.connect(zero).callStatic.checkUpkeep(801, keeper.address);
  // console.log(await result.wait());
  // console.log(result1);

  const perforDa =
    // eslint-disable-next-line max-len
    '0x00000000000000000000000000000000000000000000000000000000000000400000000000000000000000000000000000000000000000000000000000000080000000000000000000000000000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000940000000000000000000000000000000000000000000000000000000000000001000000000000000000000000000000000000000000000000000000000000002000000000000000000000000000000000000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000094';

  // console.log(await chainlink.connect(keeper).performUpkeep(801, result.performData));
  const info = await bot.connect(keeper).performUpkeep(perforDa);
  console.log(info);
}

async function getPerformData(flowId: number) {
  const check = await ethers.getContractAt('EvaFlowRandomChecker', store.get('EvaFlowRandomChecker'));
  const control = await ethers.getContractAt('EvaFlowController', store.get('evaFlowController'));
  const flowData = control.callStatic.getFlowMetas(flowId);
  const ops = await ethers.getContractAt('OpsFlowProxy', store.get('opsFlowProxy'));
  const checkData = await ops.callStatic.check((await flowData).checkData);
  const a = [flowId];
  const b = [checkData[1]];
  console.log(a);
  console.log(b);
  const myStructData1 = ethers.utils.AbiCoder.prototype.encode(['uint256[]', 'bytes[]'], [a, b]);
  console.log(myStructData1);

  const result2 = await control.execFlow('0x352ad3799046FdB97be9B45D2f0c89DF7f294C44', flowId, checkData[1]);
  // const result2 = await check.connect(zero).callStatic.check(1, 1, 0);
  console.log(result2);
  // const result = await bot.connect(zero).callStatic.checkUpkeep(checkdata);
  // const result1 = await chainlink.connect(zero).callStatic.checkUpkeep(801, keeper.address);
  // console.log(await result.wait());
  // console.log(result1);

  // console.log(await chainlink.connect(keeper).performUpkeep(801, result.performData));
  // const info = await bot.connect(keeper).performUpkeep(result.performData);
  // console.log(info);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
