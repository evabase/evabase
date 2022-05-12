/* eslint-disable node/no-missing-import */
'use strict';
import chai, { expect } from 'chai';
import { ethers } from 'hardhat';
import { solidity } from 'ethereum-waffle';
import { App, HowToCall, KeepNetWork } from './app';
import { MockTimeFlow, EvaFlowStatusUpkeep } from '../typechain';
import { help } from '../scripts/help';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { VoidSigner } from 'ethers';

chai.use(solidity);

describe('EvaFlowController', function () {
  let app: App;
  let flow: MockTimeFlow;
  let me: SignerWithAddress;
  let upkeep: EvaFlowStatusUpkeep;
  let voidSigner: VoidSigner;
  let admin: SignerWithAddress;

  before(async function () {
    app = new App();
    me = (await ethers.getSigners())[2];
    admin = (await ethers.getSigners())[0];
    await app.deploy();
    voidSigner = new ethers.VoidSigner(ethers.constants.AddressZero, ethers.provider);

    flow = (await help.deploy('MockTimeFlow')) as MockTimeFlow;
    upkeep = app.flowStatusUpKeep.connect(admin);
  });

  const createTask = async function (network: KeepNetWork) {
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
    return { flowId, orderId };
  };

  it('should be close after order has expired', async function () {
    const o1 = await createTask(KeepNetWork.ChainLink);
    const o2 = await createTask(KeepNetWork.ChainLink);
    const o3 = await createTask(KeepNetWork.Evabase);
    const o4 = await createTask(KeepNetWork.Evabase);

    const checkNet1 = ethers.utils.defaultAbiCoder.encode(['uint8', 'uint'], [KeepNetWork.ChainLink, 100]);
    const checkNet2 = ethers.utils.defaultAbiCoder.encode(['uint8', 'uint'], [KeepNetWork.Evabase, 100]);

    // set expired
    (await flow.setExpire(o1.orderId, true)).wait();
    (await flow.setExpire(o3.orderId, true)).wait();

    // close o1
    const result1 = await upkeep.connect(voidSigner).callStatic.checkUpkeep(checkNet1);
    expect(result1.upkeepNeeded).to.eq(true);
    const tx1 = await upkeep.performUpkeep(result1.performData);

    console.log('--1');
    await tx1.wait();
    await expect(tx1).to.emit(flow, 'Closed').withArgs(o1.orderId);
    expect(upkeep.performUpkeep(result1.performData)).revertedWith('all failed');
    console.log('--2');

    // close 03
    const result3 = await upkeep.connect(voidSigner).callStatic.checkUpkeep(checkNet2);
    expect(result3.upkeepNeeded).to.eq(true);
    const tx3 = await upkeep.performUpkeep(result3.performData);
    await expect(tx3).to.emit(flow, 'Closed').withArgs(o3.orderId);

    // // empty
    expect((await upkeep.connect(voidSigner).callStatic.checkUpkeep(checkNet1)).upkeepNeeded).to.eq(false);
    expect((await upkeep.connect(voidSigner).callStatic.checkUpkeep(checkNet2)).upkeepNeeded).to.eq(false);
  });

  it('should be call success when some flow check failed', async function () {
    const badFlow = app.config.address;

    const data = app.controler.interface.encodeFunctionData('registerFlow', [
      'MY',
      KeepNetWork.ChainLink,
      badFlow,
      '0x01',
    ]);
    const meSafes = await app.createOrLoadWalletSeafes(me.address);
    await meSafes.connect(me).proxy(app.controler.address, HowToCall.Call, data);

    const checkData = ethers.utils.defaultAbiCoder.encode(['uint8', 'uint'], [KeepNetWork.ChainLink, 100]);

    // not revted
    await upkeep.connect(voidSigner).callStatic.checkUpkeep(checkData);
  });
});
