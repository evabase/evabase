/* eslint-disable camelcase */
/* eslint-disable node/no-missing-import */
'use strict';
import process from 'process';
import '@openzeppelin/hardhat-upgrades';
import { ethers } from 'hardhat';
import { store, help, KeepNetWork, HowToCall } from '../help';
import {
  LOBExchange__factory,
  EvaSafesFactory__factory,
  EvaFlowController__factory,
  EvaSafes__factory,
  EvaSafes,
  ERC20__factory,
} from '../../typechain';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';

type TokenInfo = {
  address: string;
  decimals: number;
  symbol: string;
};

async function main() {
  // 创建订单

  const [me] = await ethers.getSigners();

  const user = me;
  const inputToken = { address: help.ETH_ADDRESS, decimals: 18, symbol: 'ETH' } as TokenInfo;
  const outputToken = { address: store.get('others.DAI'), decimals: 18, symbol: 'DAI' } as TokenInfo;
  const amount0 = 0.00001;
  const price = 15870000; // 1 ETH = 15870000 DAI
  const gasFundETH = 0.1;
  await crateOrder(user, inputToken, outputToken, amount0, price, gasFundETH);
}

async function createSafes(who: SignerWithAddress): Promise<EvaSafes> {
  const factory = EvaSafesFactory__factory.connect(store.get('evaSafesFactory'), ethers.provider);

  const safes = await factory.get(who.address);

  if (safes !== ethers.constants.AddressZero) {
    console.log(`skip create when exist, your safes: ${safes}`);
    return EvaSafes__factory.connect(safes, ethers.provider);
  }

  const tx = await factory.connect(who).create(who.address);

  console.log(`wait tx: ${tx.hash}`);

  const receipt = await tx.wait();
  console.log(`used gas:  ${receipt.gasUsed}`);

  return EvaSafes__factory.connect(await factory.get(who.address), ethers.provider);
}

async function crateOrder(
  user: SignerWithAddress,
  inputToken: TokenInfo,
  outputToken: TokenInfo,
  inputAmount: number,
  price: number,
  gasFundETH: number,
) {
  console.log(`${store.get('others')}, ${store.get('evaFlowController')},\r\n ${JSON.stringify(store)}`);
  const exchange = LOBExchange__factory.connect(store.get('LOBExchange'), ethers.provider);
  const controller = EvaFlowController__factory.connect(store.get('evaFlowController'), ethers.provider);

  // 必须先创建 Safes
  const safes = await createSafes(user);

  const inputIsETH = inputToken.address === help.ETH_ADDRESS;

  const amount0 = inputAmount * inputToken.decimals;
  const rate = ((price * 1e18) / 10 ** outputToken.decimals) * 10 ** inputToken.decimals;
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

  console.log(`订单信息：${order}`);

  // 如果订单的input token 是 ERC20 则需要检查收取
  if (!inputIsETH) {
    const token = ERC20__factory.connect(inputToken.address, ethers.provider);

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
  const tx = await safes.proxy(exchange.address, HowToCall.Delegate, callData, {
    value: help.toFullNum(ethValue),
  });

  const orderId = await exchange.keyOf(order);

  console.log(`order#${orderId} 已发送: ${tx.hash},等待交易Minted`);
  await tx.wait();
  console.log(`order#${orderId}  交易已 Minted`);
}

main().catch((err) => console.log(err));
