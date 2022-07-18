/* eslint-disable node/no-missing-import */
'use strict';
import chai, { expect } from 'chai';
import { ethers } from 'hardhat';
import { solidity } from 'ethereum-waffle';
import { App, HowToCall, KeepNetWork } from './app';
import { BatchCall, MockERC20, EvaSafes } from '../typechain';
import { help } from '../scripts/help';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';

chai.use(solidity);

describe('BatchCall', function () {
  let app: App;
  let batchcall: BatchCall;
  let me: SignerWithAddress;
  let USDC: MockERC20;
  let meSafes: EvaSafes;

  before(async function () {
    app = new App();
    me = (await ethers.getSigners())[2];
    await app.deploy();
    meSafes = await app.createOrLoadWalletSeafes(me.address);

    batchcall = (await help.deploy('BatchCall')) as BatchCall;

    USDC = (await help.deployERC20('USDC')) as MockERC20;
  });

  it('should be call success', async function () {
    // create Task
    const beforeAmount = await USDC.totalSupply();
    const balance = await ethers.provider.getBalance(me.address);

    const mintAmount = 10000;
    const ethFund = 1e17;
    const MockERC20 = await ethers.getContractFactory('MockERC20');
    const data1 = MockERC20.interface.encodeFunctionData('approve', [USDC.address, 1000]);
    const data2 = MockERC20.interface.encodeFunctionData('mint', [mintAmount]);

    const call1 = {
      target: USDC.address,
      value: 0,
      input: data1,
    };

    const call2 = {
      target: USDC.address,
      value: 0,
      input: data2,
    };

    const data3 = MockERC20.interface.encodeFunctionData('mintEth', [mintAmount]);
    const call3 = {
      target: USDC.address,
      value: help.toFullNum(ethFund),
      input: data3,
    };

    const inputs_ = [call1, call2, call3];

    const callData = batchcall.interface.encodeFunctionData('batchCall', [inputs_]);

    await meSafes.connect(me).proxy(batchcall.address, HowToCall.Delegate, callData, {
      value: help.toFullNum(ethFund),
    });
    const afterAmount = await USDC.totalSupply();

    expect(afterAmount).to.equal(ethers.BigNumber.from(beforeAmount).add(mintAmount));
    expect(await ethers.provider.getBalance(USDC.address)).to.equal(help.toFullNum(ethFund));
  });

  it('should be call revet', async function () {
    // create Task

    const mintAmount = 10000;
    const ethFund = 1e17;
    const MockERC20 = await ethers.getContractFactory('MockERC20');
    const data1 = MockERC20.interface.encodeFunctionData('mintEth', [1000]);
    const data2 = MockERC20.interface.encodeFunctionData('mint', [mintAmount]);

    const call1 = {
      target: USDC.address,
      value: 0,
      input: data1,
    };

    const call2 = {
      target: USDC.address,
      value: 0,
      input: data2,
    };

    const inputs_ = [call1, call2];

    const callData = batchcall.interface.encodeFunctionData('batchCall', [inputs_]);

    expect(
      meSafes.connect(me).proxy(batchcall.address, HowToCall.Delegate, callData, {
        value: help.toFullNum(ethFund),
      }),
    ).to.be.revertedWith('eth amount should gt msg.value');
  });
});
