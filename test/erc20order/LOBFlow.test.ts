'use strict';
import chai, { expect } from 'chai';
import { ethers } from 'hardhat';
import { solidity } from 'ethereum-waffle';
// eslint-disable-next-line node/no-missing-import
import { help } from '../../scripts/help';
// eslint-disable-next-line node/no-missing-import
import { App, HowToCall, KeepNetWork } from '../app';

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
    let orderId: string;
    let flowId: number;

    let keeper: SignerWithAddress;

    before(async function () {
      keeper = signers[4];

      order.owner = meSafes.address;
      order.outputToken = USDC.address;
      order.receiptor = bob;

      // create order
      const gasFund = 1e18;
      const callData = exchange.interface.encodeFunctionData('create', [
        app.controler.address,
        exchange.address,
        KeepNetWork.ChainLink,
        help.toFullNum(gasFund),
        order,
      ]);
      flowId = (await app.controler.getFlowMetaSize()).toNumber();

      meSafes.proxy(exchange.address, HowToCall.Delegate, callData, {
        value: help.toFullNum(gasFund + (order.inputAmount as number)),
      });

      orderId = await exchange.keyOf(order);

      // set keeper
      await app.config.addKeeper(keeper.address, KeepNetWork.ChainLink);
    });

    it('should be execute ok when check pass', async function () {
      const orderFlowInfo = await app.controler.getFlowMetas(flowId);

      const checkResult = await exchange.check(orderFlowInfo.checkData);

      await expect(checkResult.needExecute).to.be.eq(true);

      const tx = await app.controler.connect(keeper).execFlow(keeper.address, flowId, checkResult.executeData);

      await expect(tx).to.not.emit(app.controler, 'FlowExecuteFailed');
      await expect(tx).to.emit(app.controler, 'FlowExecuteSuccess');
      await expect(tx).to.emit(exchange, 'OrderExecuted');
      await expect(tx).to.emit(app.controler, 'FlowClosed').withArgs(orderFlowInfo.admin, flowId);
    });
  });
});
