'use strict';
import chai, { expect } from 'chai';
import { ethers } from 'hardhat';
import { solidity } from 'ethereum-waffle';
// eslint-disable-next-line node/no-missing-import
import { help, HowToCall } from '../scripts/help';
import { App, KeepNetWork } from './app';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { ERC20, EvaFlowRandomChecker, EvaSafes, MockERC20, MockTimeFlow } from '../typechain';

chai.use(solidity);

const eth1 = '1000000000000000000';

describe('EvaFlowExecutor', function () {
  let signers: SignerWithAddress[];
  let me: SignerWithAddress;
  let mySafes: EvaSafes;
  let app: App;
  let flow: MockTimeFlow;
  let keepers: SignerWithAddress[];
  const network = KeepNetWork.ChainLink;
  let USDT: MockERC20;

  before(async function () {
    signers = await ethers.getSigners();
    me = signers[1];
    app = new App();
    await app.deploy();

    flow = (await help.deploy('MockTimeFlow', [])) as MockTimeFlow;

    USDT = (await help.deployERC20('USDT', 18)) as MockERC20;
    USDT = USDT.connect(me);
    mySafes = await app.createOrLoadWalletSeafes(me.address);
    await USDT.mint(10000);
    await USDT.approve(mySafes.address, 10000);

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
    const orderId = (await flow.taskCount()).toNumber();

    const meSafes = await app.createOrLoadWalletSeafes(me.address);
    await meSafes.connect(me).proxy(flow.address, HowToCall.Delegate, callData, {
      value: help.toFullNum(gasFund),
    });
    return { orderId, flowId };
  };

  it('only call by controler', async function () {
    const info = await createTask();

    const flowInfo = await app.controler.getFlowMetas(info.flowId);

    await expect(app.flowExecutor.execute(flowInfo, '0x')).to.revertedWith('only for controller');
  });

  it('should be run sub task when flow is subflow', async function () {
    try {
      await flow.enableERC1820();

      const info = await createTask();
      const flowInfo = await app.controler.getFlowMetas(info.flowId);

      const bob = signers[6];
      const alice = signers[7];
      const subTasks = [
        // 1. transfer USDT to Bob 100
        {
          target: USDT.address,
          valueETH: 0,
          data: USDT.interface.encodeFunctionData('transferFrom', [me.address, bob.address, 100]),
        },
        // 2. transfer USDT to Alice 300
        {
          target: USDT.address,
          valueETH: 0,
          data: USDT.interface.encodeFunctionData('transferFrom', [me.address, alice.address, 300]),
        },
        // 3. approve USDT to Alice 500
        {
          target: USDT.address,
          valueETH: 0,
          data: USDT.interface.encodeFunctionData('approve', [alice.address, 500]),
        },
      ];
      await flow.setSubTask(info.orderId, subTasks);

      // run flow
      const checkResult = await flow.check(flowInfo.checkData);
      const tx = await app.controler
        .connect(keepers[0])
        .execFlow(keepers[0].address, info.flowId, checkResult.executeData);

      await expect(tx)
        .to.emit(USDT, 'Transfer')
        .withArgs(me.address, bob.address, 100)
        .emit(USDT, 'Transfer')
        .withArgs(me.address, alice.address, 300)
        .emit(USDT, 'Approval')
        .withArgs(mySafes.address, alice.address, 500);
      console.log('--');
    } finally {
      await flow.removeERC1820();
    }
  });

  it('should be stop run when subflow failed', async function () {
    try {
      await flow.enableERC1820();

      const info = await createTask();
      const flowInfo = await app.controler.getFlowMetas(info.flowId);

      const bob = signers[6];
      const alice = signers[7];
      const subTasks = [
        // 1. transfer USDT to Bob 100
        {
          target: USDT.address,
          valueETH: 0,
          data: USDT.interface.encodeFunctionData('transferFrom', [me.address, bob.address, 100]),
        },
        // 2. transfer USDT to Alice 300
        {
          target: USDT.address,
          valueETH: 0,
          data: USDT.interface.encodeFunctionData('transferFrom', [me.address, alice.address, 30000000000]),
        },
      ];
      await flow.setSubTask(info.orderId, subTasks);

      // run flow
      const checkResult = await flow.check(flowInfo.checkData);
      const tx = await app.controler
        .connect(keepers[1])
        .execFlow(keepers[1].address, info.flowId, checkResult.executeData);

      await expect(tx).to.not.emit(USDT, 'Transfer').withArgs(me.address, bob.address, 100);
      await expect(tx).to.emit(app.controler, 'FlowExecuteFailed');
    } finally {
      await flow.removeERC1820();
    }
  });
});
