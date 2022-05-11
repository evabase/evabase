'use strict';
import chai, { expect } from 'chai';
import { ethers } from 'hardhat';
import { solidity } from 'ethereum-waffle';
// eslint-disable-next-line node/no-missing-import
import { help, HowToCall } from '../scripts/help';
import { App, KeepNetWork } from './app';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { EvaFlowRandomChecker, MockTimeFlow } from '../typechain';

chai.use(solidity);

const eth1 = '1000000000000000000';

describe('EvaFlowRandomChecker', function () {
  let signers: SignerWithAddress[];
  let me: SignerWithAddress;
  let app: App;
  let flow: MockTimeFlow;
  let keepers: SignerWithAddress[];
  let checker: EvaFlowRandomChecker;
  const network = KeepNetWork.ChainLink;

  before(async function () {
    signers = await ethers.getSigners();
    me = signers[1];
    app = new App();
    await app.deploy();

    flow = (await help.deploy('MockTimeFlow', [])) as MockTimeFlow;

    checker = (await help.deploy('EvaFlowRandomChecker', [app.config.address])) as EvaFlowRandomChecker;

    keepers = [signers[4], signers[5], signers[6]];
    for (const k of keepers) {
      await app.config.addKeeper(k.address, network);
    }
  });

  const createTask = async function () {
    // create order
    const gasFund = 1e18;
    const callData = flow.interface.encodeFunctionData('create', [
      app.controler.address,
      flow.address,
      network,
      help.toFullNum(gasFund),
    ]);

    const flowId = (await app.controler.getFlowMetaSize()).toNumber();

    const meSafes = await app.createOrLoadWalletSeafes(me.address);
    await meSafes.connect(me).proxy(flow.address, HowToCall.Delegate, callData, {
      value: help.toFullNum(gasFund),
    });
    return flowId;
  };

  const cancelAllTask = async function () {
    const all = (await app.controler.getAllVaildFlowSize(network)).toNumber();
    const meSafes = (await app.createOrLoadWalletSeafes(me.address)).connect(me);

    for (let i = 0; i < all; i++) {
      const flowId = await app.controler.getIndexVaildFlow(0, network);
      const callData = flow.interface.encodeFunctionData('destroyFlow', [app.controler.address, flowId]);
      await meSafes.proxy(flow.address, HowToCall.Delegate, callData);
    }
  };

  it('should be return false when flow is empty', async function () {
    const now = Math.ceil(new Date().getTime() / 1000);
    const result = await checker.callStatic.check(1, now, network);
    expect(result.needExec).to.eq(false);
  });

  it('should be run all', async function () {
    await createTask();
    await createTask();
    await createTask();
    const now = Math.ceil(new Date().getTime() / 1000);
    const result = await checker.callStatic.check(1, now, network);
    expect(result.needExec).to.eq(true);

    // await flow.create(app.controler.address, flow.address, network, eth1, { value: eth1 });
  });

  it('should be checked all flows by keepers', async function () {
    // clear all
    await cancelAllTask();

    const flows: number[] = new Array(8);
    for (let i = 0; i < 8; i++) {
      flows[i] = await createTask();
    }

    // 8个任务分配，应该是两个人三个，1个人两个
    const now = Math.ceil(new Date().getTime() / 1000);

    for (let i = 0; i < 3; i++) {
      const result = await checker.callStatic.check(i + 1, now, network);
      expect(result.needExec).to.equal(true);
      await app.controler
        .connect(keepers[0])
        .batchExecFlow(keepers[0].address, result.execData, ethers.constants.MaxUint256);
    }
    // 再次检查时 应该都为 False
    for (let i = 0; i < 3; i++) {
      const result = await checker.callStatic.check(i + 1, now, network);
      expect(result.needExec).to.equal(false);
    }
    // 增长一分钟，所有任务都可以被执行
    help.increaseBlockTime(60);
    for (let i = 0; i < 3; i++) {
      const result = await checker.callStatic.check(i + 1, now, network);
      expect(result.needExec).to.equal(true);
    }

    // 将 8 个任务中的 2 个执行完，下次则不会被检查到
    await flow.execute(ethers.utils.defaultAbiCoder.encode(['uint256'], [1]));
    await flow.execute(ethers.utils.defaultAbiCoder.encode(['uint256'], [5]));

    for (let i = 0; i < 3; i++) {
      const result = await checker.callStatic.check(i + 1, now, network);
      expect(result.needExec).to.equal(true);
      await app.controler
        .connect(keepers[1])
        .batchExecFlow(keepers[1].address, result.execData, ethers.constants.MaxUint256);
    }
    for (let i = 0; i < 3; i++) {
      const result = await checker.callStatic.check(i + 1, now, network);
      expect(result.needExec).to.equal(false);
    }
  });
  it('should be checked By Zero address', async function () {
    await cancelAllTask();
    const zero = new ethers.VoidSigner(ethers.constants.AddressZero, ethers.provider);
    await createTask();
    const now = Math.ceil(new Date().getTime() / 1000);
    await app.config.addKeeper(checker.address, network);
    const result = await checker.callStatic.check(1, now, network);
    console.log(result);
    // expect(result.needExec).to.equal(true);
  });
});
