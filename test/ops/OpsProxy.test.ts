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
  OpsFlowProxy,
  EvaSafes,
  MockERC20,
  // eslint-disable-next-line node/no-missing-import
} from '../../typechain/index';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { BigNumberish, BytesLike } from 'ethers';
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

describe('Ops Proxy Flow', function () {
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
    contracts_ = [t1.address, t2.address];
    const data = t1.interface.encodeFunctionData('approve', [app.controler.address, 1e10]);
    const data2 = t2.interface.encodeFunctionData('approve', [app.controler.address, 1e9]);
    // inputs_ = [data, data2];
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

  describe('create order by walletSafes', function () {
    const amount = 10000;
    let flowId: number;
    let keeper: SignerWithAddress;
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
    before(async function () {
      keeper = signers[4];

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
          deadline: blockTime + 2 + 16,
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
    });

    it('less blockTime should evert', async function () {
      const gasFund = 1e18;
      task.owner = me.address;
      const _startTime = blockTime - 1;
      const callData = opsFlowProxy.interface.encodeFunctionData('create', [
        app.controler.address,
        opsFlowProxy.address,
        KeepNetWork.ChainLink,
        help.toFullNum(gasFund),
        'ops2',
        {
          owner: me.address,
          inputs: inputs_,
          startTime: _startTime,
          deadline: blockTime + 2 + 16,
          lastExecTime: 0,
          interval: 15,
        },
      ]);

      await expect(
        meSafes.proxy(opsFlowProxy.address, HowToCall.Delegate, callData, {
          value: help.toFullNum(gasFund),
        }),
      );
    });

    it('less interval should evert', async function () {
      const gasFund = 1e18;
      task.owner = me.address;
      const _interval = 1;
      const callData = opsFlowProxy.interface.encodeFunctionData('create', [
        app.controler.address,
        opsFlowProxy.address,
        KeepNetWork.ChainLink,
        help.toFullNum(gasFund),
        'ops',
        {
          owner: me.address,
          inputs: inputs_,
          startTime: blockTime + 1,
          deadline: blockTime + 2 + 16,
          lastExecTime: 0,
          interval: _interval,
        },
      ]);

      await expect(
        meSafes.proxy(opsFlowProxy.address, HowToCall.Delegate, callData, {
          value: help.toFullNum(gasFund),
        }),
      );
    });

    it('deadline should over ', async function () {
      const gasFund = 1e18;
      task.owner = me.address;
      const _deadline = blockTime + 7;
      const callData = opsFlowProxy.interface.encodeFunctionData('create', [
        app.controler.address,
        opsFlowProxy.address,
        KeepNetWork.ChainLink,
        help.toFullNum(gasFund),
        'ops1',
        {
          owner: me.address,
          inputs: inputs_,
          startTime: blockTime - 1,
          deadline: _deadline,
          lastExecTime: 0,
          interval: 15,
        },
      ]);

      await expect(
        meSafes.proxy(opsFlowProxy.address, HowToCall.Delegate, callData, {
          value: help.toFullNum(gasFund),
        }),
      );
    });

    it('pause', async function () {
      const gasFund = 1e18;
      task.owner = me.address;
      const callData1 = opsFlowProxy.interface.encodeFunctionData('pauseFlow', [app.controler.address, flowId]);

      const pauseFlow = meSafes.proxy(opsFlowProxy.address, HowToCall.Delegate, callData1);

      await expect(pauseFlow).to.emit(app.controler, 'FlowPaused');
    });
    it('start', async function () {
      const gasFund = 1e18;
      task.owner = me.address;
      const callData1 = opsFlowProxy.interface.encodeFunctionData('startFlow', [app.controler.address, flowId]);

      const pauseFlow = meSafes.proxy(opsFlowProxy.address, HowToCall.Delegate, callData1);

      await expect(pauseFlow).to.emit(app.controler, 'FlowStart');
    });
    it('close', async function () {
      const gasFund = 1e18;
      task.owner = me.address;
      const callData1 = opsFlowProxy.interface.encodeFunctionData('closeFlow', [app.controler.address, flowId]);

      const pauseFlow = meSafes.proxy(opsFlowProxy.address, HowToCall.Delegate, callData1);

      await expect(pauseFlow).to.emit(app.controler, 'FlowClosed');
    });
  });
});
