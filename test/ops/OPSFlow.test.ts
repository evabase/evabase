'use strict';
import chai, { expect } from 'chai';
import { ethers } from 'hardhat';
import { solidity } from 'ethereum-waffle';
// eslint-disable-next-line node/no-missing-import
import { help } from '../../scripts/help';
// eslint-disable-next-line node/no-missing-import
import { App, HowToCall, KeepNetWork } from '../app';

import {
  OpsFlowProxy,
  EvaSafes,
  MockERC20,
  // eslint-disable-next-line node/no-missing-import
} from '../../typechain/index';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { BigNumberish, BytesLike } from 'ethers';
import { after } from 'mocha';
chai.use(solidity);

type TaskInfo = {
  owner: string;
  contracts: string[];
  inputs: BytesLike[];
  startTime: BigNumberish;
  deadline: BigNumberish;
  lastExecTime: BigNumberish;
  interval: BigNumberish;
};

describe('Ops Flow Task', function () {
  let opsFlowProxy: OpsFlowProxy;
  let signers: SignerWithAddress[];
  let me: SignerWithAddress;
  let meSafes: EvaSafes;
  let app: App;
  let t1: MockERC20;
  let t2: MockERC20;
  let contracts_: string[];
  let inputs_: BytesLike[];
  let blockTime: number;
  before(async function () {
    signers = await ethers.getSigners();
    me = signers[3];
    app = new App();
    await app.deploy();
    t1 = (await help.deployERC20('USDC')) as MockERC20;
    t2 = (await help.deployERC20('USDC')) as MockERC20;
    // 初始化钱包
    meSafes = (await app.createOrLoadWalletSeafes(me.address)).connect(me);

    const data = t1.interface.encodeFunctionData('approve', [app.controler.address, 1e10]);
    const data2 = t2.interface.encodeFunctionData('approve', [app.controler.address, 1e9]);
    // inputs_ = [data, data2];
    contracts_ = [t1.address, t2.address];
    opsFlowProxy = (await help.deploy('OpsFlowProxy', [app.config.address, app.safesFactory.address])) as OpsFlowProxy;
    blockTime = await help.getBlockTime();

    const myStructData1 = ethers.utils.AbiCoder.prototype.encode(
      ['address', 'uint120', 'bytes'],
      [contracts_[0], 0, data],
    );

    const myStructData2 = ethers.utils.AbiCoder.prototype.encode(
      ['address', 'uint120', 'bytes'],
      [contracts_[1], 0, data2],
    );

    inputs_ = [myStructData1, myStructData2];
  });

  describe('create task by walletSafes', function () {
    const amount = 10000;
    const bob = '0x00F113faB82626dca0eE04b126629B4577F3d5E2';
    const task: TaskInfo = {
      owner: bob,
      contracts: contracts_,
      inputs: inputs_,
      startTime: blockTime + 2,
      deadline: blockTime + 2 + 60 * 60 * 24,
      lastExecTime: 0,
      interval: 15,
    };

    let flowId: number;

    let keeper: SignerWithAddress;
    let keeper1: SignerWithAddress;
    before(async function () {
      keeper = signers[4];
      keeper1 = signers[6];
      task.owner = me.address;
      task.contracts = [t1.address, t2.address];
      // create task
      const gasFund = 1e18;
      const callData = opsFlowProxy.interface.encodeFunctionData('create', [
        app.controler.address,
        opsFlowProxy.address,
        KeepNetWork.ChainLink,
        help.toFullNum(gasFund),
        'ops',
        {
          owner: me.address,
          inputs: inputs_,
          startTime: blockTime + 2,
          deadline: blockTime + 2 + 32,
          lastExecTime: 0,
          interval: 15,
        },
      ]);
      flowId = (await app.controler.getFlowMetaSize()).toNumber();

      meSafes.proxy(opsFlowProxy.address, HowToCall.Delegate, callData, {
        value: help.toFullNum(gasFund),
      });

      // orderId = await opsFlowProxy.keyOf(task);

      // set keeper
      await app.config.addKeeper(keeper.address, KeepNetWork.ChainLink);
      await app.config.addKeeper(keeper1.address, KeepNetWork.ChainLink);
    });

    it('should be execute ok when check pass', async function () {
      const orderFlowInfo = await app.controler.getFlowMetas(flowId);

      const checkResult = await opsFlowProxy.check(orderFlowInfo.checkData);

      await expect(checkResult[0]).to.be.eq(true);
      // console.log('checkResult:', checkResult);
      console.log('blockTime:', await help.getBlockTime());
      console.log('Task:', await (await opsFlowProxy.getTask(flowId)).lastExecTime); // 1652876119
      // 1
      await help.increaseBlockTime(15);
      const tx = await app.controler.connect(keeper).execFlow(keeper.address, flowId, checkResult[1]);
      const allow = await t1.allowance(opsFlowProxy.address, app.controler.address);
      console.log('blockTime:', await help.getBlockTime());
      console.log('Task:', await (await opsFlowProxy.getTask(flowId)).lastExecTime); // 1652876119
      await expect(tx).to.not.emit(app.controler, 'FlowExecuteFailed');
      await expect(tx).to.emit(app.controler, 'FlowExecuteSuccess');
      await expect(tx).to.emit(opsFlowProxy, 'TaskExecuted');

      // 2
      await help.increaseBlockTime(15);
      const checkResult1 = await opsFlowProxy.check(orderFlowInfo.checkData);
      await expect(checkResult1[0]).to.be.eq(true);
      const tx2 = await app.controler.connect(keeper1).execFlow(keeper1.address, flowId, checkResult[1]);
      await expect(tx2).to.not.emit(app.controler, 'FlowExecuteFailed');
      await expect(tx2).to.emit(app.controler, 'FlowExecuteSuccess');
      await expect(tx2).to.emit(opsFlowProxy, 'TaskExecuted');
      console.log('blockTime:', await help.getBlockTime());
      console.log('Task:', await (await opsFlowProxy.getTask(flowId)).lastExecTime); // 1652876119

      // 3 over time
      await help.increaseBlockTime(15);
      const checkResult2 = await opsFlowProxy.check(orderFlowInfo.checkData);
      await expect(checkResult2[0]).to.be.eq(false);
      // console.log('blockTime:', await help.getBlockTime()); //     1652876150
      // console.log('Task:', await (await opsFlowProxy.getTask(flowId)).lastExecTime); // 1652876119
      // // const tx2 = await app.controler.connect(keeper).execFlow(keeper.address, flowId, checkResult[1]);
      // await expect(app.controler.connect(keeper).execFlow(keeper.address, flowId, checkResult[1])).revertedWith(
      //   'task is not active',
      // );
    });
  });
});