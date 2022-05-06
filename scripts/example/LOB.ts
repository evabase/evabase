/* eslint-disable node/no-missing-import */
'use strict';
import '@openzeppelin/hardhat-upgrades';
import { ethers } from 'hardhat';
import { store, help, KeepNetWork, HowToCall } from '../help';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { EvaSafes } from '../../typechain';

type TokenInfo = {
  address: string;
  decimals: number;
  symbol: string;
};

async function main() {
  // await newOrder();
  // 0x3045d749c917522c3870f08d23053d19e3d5858edca1c1bbfe6e36deb3f75d09
  // 0xb4444c235831e4fbc5b64a47daed72edd60b91d3565b14233476a18e438c1b7f
  // await exchangeCheck('0xb4444c235831e4fbc5b64a47daed72edd60b91d3565b14233476a18e438c1b7f');
  await chainLinkCheck('0x0000000000000000000000000000000000000000000000000000000000000001');
  // await tryExec('0x0000000000000000000000000000000000000000000000000000000000000001');
  // await checkAmount();
  // await cancelOrder(me, 4);
  // const admin = await help.admin();
  // const config = await ethers.getContractAt('EvabaseConfig', store.get('evabaseConfig'));
  // await config.connect(admin!).setBatchFlowNum(60);
}

async function cancelOrder(user: SignerWithAddress, flowId: number) {
  const exchange = await ethers.getContractAt('LOBExchange', store.get('LOBExchange'));

  const data = exchange.interface.encodeFunctionData('destroyFlow', [store.get('evaFlowController'), flowId]);

  const safes = await createSafes(user);
  const tx = await safes.connect(user).proxy(exchange.address, HowToCall.Delegate, data);

  console.log(`tx ${tx.hash}`);
  await tx.wait();
  console.log('cancel order done');
}

async function checkAmount() {
  const strategy = await ethers.getContractAt('UniswapV2Strategy', store.get('UniswapV2Strategy'));
  const result = await strategy.calcMaxInput(
    store.get('others.WETH'),
    store.get('others.DAI'),
    help.toFullNum(7728000 * 1e18),
  );
  console.log(result);
}

async function exchangeCheck(orderId: string) {
  const exchange = await ethers.getContractAt('LOBExchange', store.get('LOBExchange'));
  const result = await exchange.check(ethers.utils.defaultAbiCoder.encode(['bytes32'], [orderId]));
  console.log(result);
}

async function tryExec(checkdata: string) {
  const chainlink = await ethers.getContractAt('KeeperRegistryInterface', store.get('others.ChainlinkKeeperRegistry'));
  const bot = await ethers.getContractAt('EvaFlowChainLinkKeeperBot', store.get('evaFlowChainLinkKeeperBot'));
  const result = await bot.checkUpkeep(checkdata);

  const keeper = new ethers.VoidSigner('0x426a9b94ae341751cb248d81ddbe3cccd16dc493', ethers.provider);
  console.log(await chainlink.connect(keeper).callStatic.performUpkeep(314, result.performData));
  const info = await bot.connect(keeper).callStatic.performUpkeep(result.performData);
  console.log(info);
}

async function chainLinkCheck(checkdata: string) {
  const chainlink = await ethers.getContractAt('KeeperRegistryInterface', store.get('others.ChainlinkKeeperRegistry'));

  const keeper = '0x426a9b94ae341751cb248d81ddbe3cccd16dc493';
  const zero = new ethers.VoidSigner(ethers.constants.AddressZero, ethers.provider);
  console.log(await chainlink.connect(zero).checkUpkeep(314, keeper));
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

async function newOrder() {
  const user = await help.me();
  const inputToken = { address: help.ETH_ADDRESS, decimals: 18, symbol: 'ETH' } as TokenInfo;
  const outputToken = { address: store.get('others.DAI'), decimals: 18, symbol: 'DAI' } as TokenInfo;

  const amount0 = 0.00001;
  const price = 7028000;
  const gasFundETH = 0.01;
  await crateOrder(user!, inputToken, outputToken, amount0, price, gasFundETH);
}

async function createSafes(who: SignerWithAddress): Promise<EvaSafes> {
  const factory = await ethers.getContractAt('EvaSafesFactory', store.get('evaSafesFactory'));

  const safes = await factory.get(who.address);

  if (safes !== ethers.constants.AddressZero) {
    console.log(`skip create when exist, your safes: ${safes}`);
    return await ethers.getContractAt('EvaSafes', await factory.get(who.address));
  }

  const tx = await factory.connect(who).create(who.address);

  console.log(`wait tx: ${tx.hash}`);

  const receipt = await tx.wait();
  console.log(`used gas:  ${receipt.gasUsed}`);

  return await ethers.getContractAt('EvaSafes', await factory.get(who.address));
}

async function crateOrder(
  user: SignerWithAddress,
  inputToken: TokenInfo,
  outputToken: TokenInfo,
  inputAmount: number,
  price: number,
  gasFundETH: number,
) {
  const exchange = await ethers.getContractAt('LOBExchange', store.get('LOBExchange'));
  const controller = await ethers.getContractAt('EvaFlowController', store.get('evaFlowController'));

  // 必须先创建 Safes
  const safes = await createSafes(user);

  const inputIsETH = inputToken.address === help.ETH_ADDRESS;
  const u0 = 10 ** inputToken.decimals;
  const u1 = 10 ** outputToken.decimals;
  const amount0 = inputAmount * u0;
  const rate = Math.ceil((price * 1e18 * u0) / u1);
  const order = {
    owner: safes.address,
    inputAmount: help.toFullNum(amount0),
    inputToken: inputToken.address,
    minRate: help.toFullNum(rate),
    outputToken: outputToken.address,
    expiration: Math.ceil(new Date().getTime() / 1000) + 60 * 60 * 24, // 1days
    receiptor: user.address,
    minInputPer: help.toFullNum(amount0 * 0.1),
  };

  console.log(`订单信息：${JSON.stringify(order)}`);
  // 如果订单的input token 是 ERC20 则需要检查收取
  if (!inputIsETH) {
    const token = await ethers.getContractAt('ERC20', inputToken.address);

    const allowance = await token.allowance(user.address, safes.address);
    if (allowance.lt(ethers.BigNumber.from(help.toFullNum(amount0)))) {
      // 需要授权
      const tx = await token.connect(user).approve(safes.address, ethers.constants.MaxUint256);
      console.log(`需要授权，等待授权交易 ${tx.hash}`);
      await tx.wait();
      console.log('授权完成');
    }
  }

  // 创建订单的交易数据编码
  const callData = exchange.interface.encodeFunctionData('create', [
    controller.address,
    exchange.address,
    KeepNetWork.ChainLink,
    help.toFullNum(gasFundETH * 1e18),
    order,
  ]);

  // 计算用户需要发送的ETH数量
  const ethValue = (gasFundETH + (inputIsETH ? inputAmount : 0)) * 1e18;

  // 构建并发送交易
  const tx = await safes.connect(user).proxy(exchange.address, HowToCall.Delegate, callData, {
    value: help.toFullNum(ethValue),
  });

  const orderId = await exchange.keyOf(order);

  console.log(`order#${orderId} 已发送: ${tx.hash},等待交易Minted`);
  await tx.wait();
  console.log(`order#${orderId}  交易已 Minted`);
}

main().catch((err) => console.log(err));
