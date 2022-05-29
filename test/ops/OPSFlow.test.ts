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

    // const data = t1.interface.encodeFunctionData('approve', [app.controler.address, 1e10]);
    // const data2 = t2.interface.encodeFunctionData('approve', [app.controler.address, 1e9]);

    const data = t1.interface.encodeFunctionData('mint', [2000]);
    const data2 = t1.interface.encodeFunctionData('mint', [1300]);
    // inputs_ = [data, data2];
    contracts_ = [t1.address, t1.address];
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
      lastExecTime: 1,
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

      await meSafes.proxy(opsFlowProxy.address, HowToCall.Delegate, callData, {
        value: help.toFullNum(gasFund),
      });

      // orderId = await opsFlowProxy.keyOf(task);

      // set keeper
      await app.config.addKeeper(keeper.address, KeepNetWork.ChainLink);
      await app.config.addKeeper(keeper1.address, KeepNetWork.ChainLink);
    });

    it('should be execute ok when check pass', async function () {
      await opsFlowProxy.enableERC1820();
      const total1 = await t1.totalSupply();
      console.log('------total before:', total1);
      const orderFlowInfo = await app.controler.getFlowMetas(flowId);
      await help.increaseBlockTime(15);
      const checkResult = await opsFlowProxy.check(orderFlowInfo.checkData);

      await expect(checkResult[0]).to.be.eq(true);
      // console.log('checkResult:', checkResult);
      // console.log('blockTime:', await help.getBlockTime());
      // console.log('Task:', await (await opsFlowProxy.getTask(flowId)).lastExecTime); // 1652876119
      // 1
      await help.increaseBlockTime(15);
      const tx = await app.controler.connect(keeper).execFlow(keeper.address, flowId, checkResult[1]);
      // const allow = await t1.allowance(opsFlowProxy.address, app.controler.address);
      // console.log('blockTime:', await help.getBlockTime());
      // console.log('Task:', await (await opsFlowProxy.getTask(flowId)).lastExecTime); // 1652876119
      await expect(tx).to.not.emit(app.controler, 'FlowExecuteFailed');
      await expect(tx).to.emit(app.controler, 'FlowExecuteSuccess');
      await expect(tx).to.emit(opsFlowProxy, 'TaskExecuted');
      await expect(tx).to.emit(t1, 'Transfer');
      const total = await t1.totalSupply();
      console.log('-----total after:', total);
      expect(total).to.eq(3300);
      // 2
      // await help.increaseBlockTime(15);
      // console.log('blockTime2:', await help.getBlockTime());
      // const checkResult1 = await opsFlowProxy.check(orderFlowInfo.checkData);
      // console.log('checkResult1:', checkResult1);
      // expect(checkResult1[0]).to.be.eq(true);
      // await expect(checkResult1[0]).to.be.eq(true);
      // const tx2 = await app.controler.connect(keeper1).execFlow(keeper1.address, flowId, checkResult[1]);
      // await expect(tx2).to.not.emit(app.controler, 'FlowExecuteFailed');
      // await expect(tx2).to.emit(app.controler, 'FlowExecuteSuccess');
      // await expect(tx2).to.emit(opsFlowProxy, 'TaskExecuted');
      // console.log('blockTime:', await help.getBlockTime());
      // console.log('Task:', await (await opsFlowProxy.getTask(flowId)).lastExecTime); // 1652876119

      // 3 over time

      await help.increaseBlockTime(15);
      // console.log('blockTime3:', await help.getBlockTime());
      // console.log('Task3.lastExecTime:', (await opsFlowProxy.getTask(flowId)).lastExecTime);
      // console.log('Task3.deadline:', (await opsFlowProxy.getTask(flowId)).deadline); // 1652876119
      // console.log('Task3.interval:', (await opsFlowProxy.getTask(flowId)).interval); // 1652876119
      const checkResult2 = await opsFlowProxy.check(orderFlowInfo.checkData);
      // console.log('checkResult2:', checkResult2);

      expect(checkResult2[0]).to.be.eq(false);
      // console.log('blockTime:', await help.getBlockTime()); //     1652876150
      // console.log('Task:', await (await opsFlowProxy.getTask(flowId)).lastExecTime); // 1652876119
      // // const tx2 = await app.controler.connect(keeper).execFlow(keeper.address, flowId, checkResult[1]);
      // await expect(app.controler.connect(keeper).execFlow(keeper.address, flowId, checkResult[1])).revertedWith(
      //   'task is not active',
      // );
    });

    it('should be execute ok when check pass 2', async function () {
      const gasFund = 1e18;
      blockTime = await help.getBlockTime();
      const callData1 = opsFlowProxy.interface.encodeFunctionData('create', [
        app.controler.address,
        opsFlowProxy.address,
        KeepNetWork.ChainLink,
        help.toFullNum(gasFund),
        'ops',
        {
          owner: me.address,
          inputs: inputs_,
          startTime: blockTime,
          deadline: blockTime + 32,
          lastExecTime: 0,
          interval: 1,
        },
      ]);

      flowId = (await app.controler.getFlowMetaSize()).toNumber();

      await meSafes.proxy(opsFlowProxy.address, HowToCall.Delegate, callData1, {
        value: help.toFullNum(gasFund),
      });

      const orderFlowInfo = await app.controler.getFlowMetas(flowId);
      // console.log('flowId:', flowId);
      // const checkResult = await opsFlowProxy.check(orderFlowInfo.checkData);
      // console.log('checkResult22:', checkResult);
      // console.log('before:', new Date());
      // eslint-disable-next-line promise/param-names
      // await new Promise((r) => setTimeout(r, 5000));
      // console.log('after:', new Date());
      const checkResult22 = await opsFlowProxy.check(orderFlowInfo.checkData);
      // console.log('orderFlowInfo:', orderFlowInfo);
      console.log('checkResult22:', checkResult22);
      console.log('blockTime22:', await help.getBlockTime());
      // console.log('Task:', await opsFlowProxy.getTask(flowId)); // 1652876119
      // await expect(checkResult[0]).to.be.eq(true);
      // 1
      await help.increaseBlockTime(2);

      // const data = '0x0000000000000000000000000000000000000000000000000000000000000002';
      // console.log('blockTime44:', await help.getBlockTime());
      // eslint-disable-next-line promise/param-names
      await new Promise((r) => setTimeout(r, 2000));
      // console.log('blockTime55:', await help.getBlockTime());
      const checkResult33 = await opsFlowProxy.check(orderFlowInfo.checkData);
      // console.log('checkResult33:', checkResult33);
      const tx = await app.controler.connect(keeper).execFlow(keeper.address, flowId, checkResult33[1]);
      const allow = await t1.allowance(opsFlowProxy.address, app.controler.address);
      console.log('blockTime33:', await help.getBlockTime());
      // console.log('Task22:', (await opsFlowProxy.getTask(flowId)).lastExecTime); // 1652876119
      // await expect(tx).to.not.emit(app.controler, 'FlowExecuteFailed');
      await expect(tx).to.emit(app.controler, 'FlowExecuteSuccess');
      // await expect(tx).to.emit(opsFlowProxy, 'TaskExecuted');

      // 3 over time
      // await help.increaseBlockTime(2);
      // const checkResult2 = await opsFlowProxy.check(orderFlowInfo.checkData);
      // console.log('checkResult22:', checkResult2);
    });
    it('should be execute ok when deadline =0', async function () {
      const gasFund = 1e18;
      blockTime = await help.getBlockTime();
      const callData1 = opsFlowProxy.interface.encodeFunctionData('create', [
        app.controler.address,
        opsFlowProxy.address,
        KeepNetWork.ChainLink,
        help.toFullNum(gasFund),
        'ops',
        {
          owner: me.address,
          inputs: inputs_,
          startTime: blockTime + 11,
          deadline: 0,
          lastExecTime: 0,
          interval: 1,
        },
      ]);

      flowId = (await app.controler.getFlowMetaSize()).toNumber();

      await meSafes.proxy(opsFlowProxy.address, HowToCall.Delegate, callData1, {
        value: help.toFullNum(gasFund),
      });

      let orderFlowInfo = await app.controler.getFlowMetas(flowId);

      // console.log('orderFlowInfo:', orderFlowInfo);
      const checkResult22 = await opsFlowProxy.check(orderFlowInfo.checkData);
      console.log('checkResult22:', checkResult22);
      expect(checkResult22[0]).to.be.eq(false);
      // 1
      await help.increaseBlockTime(11);

      const checkResult33 = await opsFlowProxy.check(orderFlowInfo.checkData);
      console.log('checkResult33:', checkResult33);
      expect(checkResult33[0]).to.be.eq(true);
      const tx = await app.controler.connect(keeper).execFlow(keeper.address, flowId, checkResult33[1]);
      await expect(tx).to.emit(app.controler, 'FlowExecuteSuccess');

      orderFlowInfo = await app.controler.getFlowMetas(flowId);
      // console.log('after orderFlowInfo:', orderFlowInfo);
      const checkResult44 = await opsFlowProxy.check(orderFlowInfo.checkData);
      expect(checkResult44[0]).to.be.eq(false);
    });
  });
});
