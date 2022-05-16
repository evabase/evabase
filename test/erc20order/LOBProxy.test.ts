'use strict';
import chai, { expect } from 'chai';
import { ethers } from 'hardhat';
import { solidity } from 'ethereum-waffle';
// eslint-disable-next-line node/no-missing-import
import { help } from '../../scripts/help';
// eslint-disable-next-line node/no-missing-import
import { App, HowToCall, KeepNetWork } from '../app';

// eslint-disable-next-line node/no-missing-import
import {
  MockSwapStrategy,
  MockERC20,
  LOBExchange,
  EvaSafes,
  // eslint-disable-next-line node/no-missing-import
} from '../../typechain/index';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { BigNumberish } from 'ethers';
chai.use(solidity);

type OrderInfo = {
  owner: string;
  inputAmount: BigNumberish;
  inputToken: string;
  minRate: BigNumberish;
  outputToken: string;
  deadline: number;
  receiptor: string;
  minInputPer: number;
};

describe('ERC20 Limit Order', function () {
  let strategy: MockSwapStrategy;
  let USDC: MockERC20;
  let WBTC: MockERC20;
  let exchange: LOBExchange;
  let signers: SignerWithAddress[];
  let me: SignerWithAddress;
  let meSafes: EvaSafes;
  let app: App;
  const exchangeConfig = {
    paused: false,
    basisPointsRate: 0.001 * 10000,
    feeTo: '0x00F113faB82626dca0eE04b126629B4577F3d5E2',
  };

  before(async function () {
    signers = await ethers.getSigners();
    me = signers[3];
    strategy = (await help.deploy('MockSwapStrategy')) as MockSwapStrategy;
    exchange = (await help.deploy('LOBExchange', [strategy.address, exchangeConfig])) as LOBExchange;
    USDC = (await help.deployERC20('USDC')) as MockERC20;
    WBTC = (await help.deployERC20('WBTC', 8)) as MockERC20;

    app = new App();
    await app.deploy();

    // 初始化钱包
    meSafes = (await app.createOrLoadWalletSeafes(me.address)).connect(me);
  });

  describe('create order by walletSafes', function () {
    const amount = 10000;
    const bob = '0x00F113faB82626dca0eE04b126629B4577F3d5E2';
    const order: OrderInfo = {
      owner: bob,
      inputAmount: amount,
      inputToken: help.ETH_ADDRESS,
      minRate: ethers.utils.parseUnits('1', 18),
      outputToken: '',
      deadline: Math.ceil(new Date().getTime() / 1000) + 60 * 60 * 24,
      receiptor: bob,
      minInputPer: 1,
    };

    before(async function () {
      order.owner = meSafes.address;
      order.outputToken = USDC.address;
      order.receiptor = bob;
    });

    it('shouled be support ETH', async function () {
      const gasFund = 1e18;
      const callData = exchange.interface.encodeFunctionData('create', [
        app.controler.address,
        exchange.address,
        KeepNetWork.ChainLink,
        help.toFullNum(gasFund),
        order,
      ]);

      const tx = meSafes.proxy(exchange.address, HowToCall.Delegate, callData, {
        value: help.toFullNum(gasFund + (order.inputAmount as number)),
      });

      const orderId = await exchange.keyOf(order);
      const fee = (order.inputAmount as number) * 0.001;
      await expect(tx).to.emit(exchange, 'OrderCreated').withArgs(orderId, order.owner, help.toFullNum(fee));

      const orderInfo = await exchange.getOrderInfo(orderId);
      await expect(orderInfo[0].owner).to.eq(order.owner);
    });

    it('shouled be failed when walletsafe approve mising', async function () {
      order.inputToken = USDC.address;
      order.outputToken = WBTC.address;

      const gasFund = 1e18;
      const callData = exchange.interface.encodeFunctionData('create', [
        app.controler.address,
        exchange.address,
        KeepNetWork.ChainLink,
        help.toFullNum(gasFund),
        order,
      ]);

      const tx = meSafes.proxy(exchange.address, HowToCall.Delegate, callData, {
        value: help.toFullNum(gasFund),
      });

      await expect(tx).to.revertedWith('STF');
    });
    it('shouled be support ERC20', async function () {
      order.inputToken = USDC.address;
      order.outputToken = WBTC.address;
      order.deadline += 1;

      const gasFund = 1e18;
      const callData = exchange.interface.encodeFunctionData('create', [
        app.controler.address,
        exchange.address,
        KeepNetWork.ChainLink,
        help.toFullNum(gasFund),
        order,
      ]);
      const orderId = await exchange.keyOf(order);
      const fee = (order.inputAmount as number) * 0.001;

      // approve first
      await USDC.connect(me).approve(meSafes.address, order.inputAmount);
      // and mint USDT
      await USDC.connect(me).mint(order.inputAmount);

      // send order
      const tx = meSafes.proxy(exchange.address, HowToCall.Delegate, callData, { value: help.toFullNum(gasFund) });
      await expect(tx).to.emit(exchange, 'OrderCreated').withArgs(orderId, order.owner, help.toFullNum(fee));

      const orderInfo = await exchange.getOrderInfo(orderId);
      await expect(orderInfo[0].owner).to.eq(order.owner);
    });

    it('restart order', async function () {
      order.inputToken = USDC.address;
      order.outputToken = WBTC.address;
      order.deadline += 1;

      const gasFund = 1e18;
      const callData = exchange.interface.encodeFunctionData('create', [
        app.controler.address,
        exchange.address,
        KeepNetWork.ChainLink,
        help.toFullNum(gasFund),
        order,
      ]);
      const orderId = await exchange.keyOf(order);

      // approve first
      await USDC.connect(me).approve(meSafes.address, order.inputAmount);
      // and mint USDT
      await USDC.connect(me).mint(order.inputAmount);

      // send order
      const flowId = await app.controler.getFlowMetaSize();
      await meSafes.proxy(exchange.address, HowToCall.Delegate, callData, { value: help.toFullNum(gasFund) });

      // pause order
      const callData2 = exchange.interface.encodeFunctionData('pauseFlow', [app.controler.address, flowId]);

      const tx = meSafes.proxy(exchange.address, HowToCall.Delegate, callData2);
      // expect get paused event
      await expect(tx)
        .to.emit(exchange, 'OrderPaused')
        .withArgs(orderId, true)
        .to.emit(app.controler, 'FlowPaused')
        .withArgs(meSafes.address, flowId);

      // restart
      const tx2 = meSafes.proxy(
        exchange.address,
        HowToCall.Delegate,
        exchange.interface.encodeFunctionData('startFlow', [app.controler.address, flowId]),
      );

      // expect get restart event
      await expect(tx2)
        .to.emit(exchange, 'OrderPaused')
        .withArgs(orderId, false)
        .to.emit(app.controler, 'FlowStart')
        .withArgs(meSafes.address, flowId);

      const tx3 = meSafes.proxy(
        exchange.address,
        HowToCall.Delegate,
        exchange.interface.encodeFunctionData('closeFlow', [app.controler.address, flowId]),
      );
      // expect get cancel event
      await expect(tx3)
        .to.emit(exchange, 'OrderCancelled')
        .withArgs(orderId, '9990')
        .to.emit(app.controler, 'FlowClosed') //
        .withArgs(meSafes.address, flowId);
    });
  });
});
