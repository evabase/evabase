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
  const zero = new ethers.VoidSigner(ethers.constants.AddressZero, ethers.provider);

  beforeEach(async function () {
    signers = await ethers.getSigners();
    me = signers[1];
    app = new App();
    await app.deploy();

    flow = (await help.deploy('MockTimeFlow', [])) as MockTimeFlow;

    checker = (await help.deploy('EvaFlowRandomChecker', [app.config.address])) as EvaFlowRandomChecker;

    // 只允许批量执行 3 个
    await app.config.setBatchFlowNum(3);
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

    const orderId = await flow.taskCount();
    const flowId = (await app.controler.getFlowMetaSize()).toNumber();

    const meSafes = await app.createOrLoadWalletSeafes(me.address);
    await meSafes.connect(me).proxy(flow.address, HowToCall.Delegate, callData, {
      value: help.toFullNum(gasFund),
    });
    return {
      flowId,
      orderId,
    };
  };

  const cancelAllTask = async function () {
    const all = (await app.controler.getAllVaildFlowSize(network)).toNumber();
    const meSafes = (await app.createOrLoadWalletSeafes(me.address)).connect(me);

    for (let i = 0; i < all; i++) {
      const flowId = await app.controler.getIndexVaildFlow(0, network);
      const callData = flow.interface.encodeFunctionData('closeFlow', [app.controler.address, flowId]);
      await meSafes.proxy(flow.address, HowToCall.Delegate, callData);
    }
  };

  it('fix89', async function () {
    keepers = [signers[4]];
    for (const k of keepers) {
      await app.config.addKeeper(k.address, network);
    }

    // 7个任务
    const flows: any[] = new Array(7);
    for (let i = 0; i < 7; i++) {
      flows[i] = await createTask();
    }

    // 设置前 4 个任务过期，[0,1,2,3]
    for (let i = 0; i < 4; i++) {
      await flow.setExpire(flows[i].orderId, true);
    }
    // 此时，有三个任务应该被检测到可以被执行
    const zeroChecker = checker.connect(zero);
    const now = Math.ceil(new Date().getTime() / 1000);
    const result = await zeroChecker.callStatic.check(1, now, network);
    expect(result.needExec).to.equal(true);

    await expect(app.controler.connect(keepers[0]).batchExecFlow(keepers[0].address, result.execData))
      .to.emit(flow, 'Executed')
      .withArgs(flows[4].orderId, 1)
      .to.emit(flow, 'Executed')
      .withArgs(flows[5].orderId, 1)
      .to.emit(flow, 'Executed')
      .withArgs(flows[6].orderId, 1);
  });

  it('should be check and exec all task', async function () {
    // 3 个 bot ，每人最多一次执行3个任务
    keepers = [signers[4], signers[5], signers[6]];
    for (const k of keepers) {
      await app.config.addKeeper(k.address, network);
    }
    // 那么，7个有效任务可以被全部执行（注册9个任务，过期2个）
    const flows: any[] = new Array(9);
    for (let i = 0; i < 9; i++) {
      flows[i] = await createTask();
    }
    // 注销任务 1,5
    await flow.setExpire(flows[1].orderId, true);
    await flow.setExpire(flows[5].orderId, true);

    const zeroChecker = checker.connect(zero);
    const now = 1659249409;

    // 执行一次，期望剩余的7个任务都能被执行
    const execDatas: string[] = new Array(3);
    for (let i = 0; i < 3; i++) {
      console.log(`Bot:${i + 1} check`);
      const result = await zeroChecker.callStatic.check(i + 1, now, network);
      expect(result.needExec).to.equal(true);
      execDatas[i] = result.execData;
      console.log(`Bot:${i + 1} end`);
    }
    for (let i = 0; i < 3; i++) {
      console.log(`Bot:${i + 1} execute`);
      await app.controler.connect(keepers[i]).batchExecFlow(keepers[i].address, execDatas[i]);
      console.log(`Bot:${i + 1}`);
    }
    // 再次检查时，都不需要执行
    for (let i = 0; i < 3; i++) {
      console.log(`Bot:${i + 1} check again`);
      const result = await zeroChecker.callStatic.check(i + 1, now, network);
      console.log(`Bot:${i + 1} end`);

      expect(result.needExec).to.equal(false);
    }
  });
});
