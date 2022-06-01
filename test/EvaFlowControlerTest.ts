'use strict';
import chai, { expect } from 'chai';
import { ethers } from 'hardhat';
import { solidity } from 'ethereum-waffle';
import {
  EvaSafes,
  EvaFlowController,
  // eslint-disable-next-line node/no-missing-import
} from '../typechain';
// eslint-disable-next-line node/no-missing-import
import { App, HowToCall } from './app';
// eslint-disable-next-line node/no-missing-import
import { help } from '../scripts/help';
// eslint-disable-next-line node/no-missing-import
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
chai.use(solidity);
// const help = require('./initEvebase.ts');

describe('EvaFlowController ', function () {
  let app: any;
  let meSafes: EvaSafes;
  let me: SignerWithAddress;
  let signers: SignerWithAddress[];
  before(async function () {
    signers = await ethers.getSigners();
    app = new App();
    await app.deploy();
    me = signers[0];
    // 初始化钱包
    meSafes = (await app.createOrLoadWalletSeafes(me.address)).connect(me);
  });

  describe('EvaFlowController 11', function () {
    it('Should return the new EvaFlowController creat', async function () {
      // const evaSafesFactory = app.evaSafesFactory;
      const evaFlowController = app.controler;
      // const evabaseConfig = app.evabaseConfig;
      // await evabaseConfig.setControl(evaFlowController.address);
      const ownerO = await ethers.getSigners();
      // await evaFlowController.createEvaSafes(ownerO[0].address);

      const flowCode =
        // eslint-disable-next-line max-len
        '0x608060405234801561001057600080fd5b50336000806101000a81548173ffffffffffffffffffffffffffffffffffffffff021916908373ffffffffffffffffffffffffffffffffffffffff160217905550610492806100606000396000f3fe608060405234801561001057600080fd5b50600436106100625760003560e01c806309c5eabe14610067578063294519591461008357806352beaaed1461009f57806383197ef0146100bd5780638da5cb5b146100c7578063c64b3bb5146100e5575b600080fd5b610081600480360381019061007c91906101fa565b610116565b005b61009d600480360381019061009891906101fa565b610119565b005b6100a761011c565b6040516100b4919061029a565b60405180910390f35b6100c5610124565b005b6100cf610142565b6040516100dc919061029a565b60405180910390f35b6100ff60048036038101906100fa91906101fa565b61016b565b60405161010d9291906102b5565b60405180910390f35b50565b50565b600033905090565b60003090508073ffffffffffffffffffffffffffffffffffffffff16ff5b60008060009054906101000a900473ffffffffffffffffffffffffffffffffffffffff16905090565b6000606060016040518060200160405280600081525091509150915091565b600061019d6101988461030a565b6102e5565b9050828152602081018484840111156101b9576101b861043c565b5b6101c4848285610395565b509392505050565b600082601f8301126101e1576101e0610437565b5b81356101f184826020860161018a565b91505092915050565b6000602082840312156102105761020f610446565b5b600082013567ffffffffffffffff81111561022e5761022d610441565b5b61023a848285016101cc565b91505092915050565b61024c81610357565b82525050565b61025b81610369565b82525050565b600061026c8261033b565b6102768185610346565b93506102868185602086016103a4565b61028f8161044b565b840191505092915050565b60006020820190506102af6000830184610243565b92915050565b60006040820190506102ca6000830185610252565b81810360208301526102dc8184610261565b90509392505050565b60006102ef610300565b90506102fb82826103d7565b919050565b6000604051905090565b600067ffffffffffffffff82111561032557610324610408565b5b61032e8261044b565b9050602081019050919050565b600081519050919050565b600082825260208201905092915050565b600061036282610375565b9050919050565b60008115159050919050565b600073ffffffffffffffffffffffffffffffffffffffff82169050919050565b82818337600083830152505050565b60005b838110156103c25780820151818401526020810190506103a7565b838111156103d1576000848401525b50505050565b6103e08261044b565b810181811067ffffffffffffffff821117156103ff576103fe610408565b5b80604052505050565b7f4e487b7100000000000000000000000000000000000000000000000000000000600052604160045260246000fd5b600080fd5b600080fd5b600080fd5b600080fd5b6000601f19601f830116905091905056fea264697066735822122018d7341841f0564584b963e1ddb519759be7f7621f9d1002f6459f658cdba58764736f6c63430008070033';

      // const flowCode = '0x';
      console.log('ownerO[0]', ownerO[0].address);
      await expect(evaFlowController.registerFlow('ace', 1, ownerO[0].address, flowCode, { value: 10000 })).to.reverted;

      const size = await evaFlowController.getAllVaildFlowSize(1);
      // const flowMetas = await evaFlowController.getFlowMetas(1);
      // console.log(flowMetas);
      expect(ethers.BigNumber.from(0)).to.eql(size);
    });

    it('Should return the new EvaFlowController update/pause', async function () {
      // const evaSafesFactory = app.evaSafesFactory;
      const evaFlowController = app.controler;
      const evabaseConfig = app.config;
      await evabaseConfig.setControl(evaFlowController.address);
      // const ownerO = await ethers.getSigners();
      // await evaFlowController.createEvaSafes(ownerO[0].address);

      // await evaFlowController.createFlow("pause", 1, flowCode);
      // evaFlowController.registerFlow('ace', 1, ownerO[0], '', { value: 10000 });
      const size = await evaFlowController.getAllVaildFlowSize(0);
      // const flowMetas = await evaFlowController.getFlowMetas(0);
      // console.log(`before: ${flowMetas}`);
      // await evaFlowController.pauseFlow(0);
      // flowMetas = await evaFlowController.getFlowMetas(0);
      // console.log(`after: ${flowMetas}`);
      expect(ethers.BigNumber.from(0)).to.eql(size);
    });

    it('Should EvaFlowController close', async function () {
      const ownerO = await ethers.getSigners();
      const gasFund = 1e18;
      const callData = app.controler.interface.encodeFunctionData('registerFlow', [
        'ace',
        0,
        ownerO[0].address,
        '0x0000000000000000000000000000000000000000000000000000000000000050',
      ]);
      const flowId = (await app.controler.getFlowMetaSize()).toNumber();

      await meSafes.proxy(app.controler.address, HowToCall.Call, callData, {
        value: help.toFullNum(gasFund),
      });

      const cancelData = app.controler.interface.encodeFunctionData('closeFlow', [flowId]);
      await meSafes.proxy(app.controler.address, HowToCall.Call, cancelData);

      // expect(ethers.BigNumber.from(0)).to.eql(flowId);
    });
  });
});
