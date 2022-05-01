/* eslint-disable node/no-missing-import */
// eslint-disable-next-line strict
import chai, { expect } from 'chai';
import { ethers } from 'hardhat';
import { solidity } from 'ethereum-waffle';
// eslint-disable-next-line node/no-missing-import
import { help } from '../help';

import { App, HowToCall, KeepNetWork } from '../app';

import {
  EvabaseConfig,
  EvaFlowController,
  EvaSafesFactory,
  EvaBaseServerBot,
  EvaFlowChecker,
  EvaSafes,
  NftLimitOrderFlowProxy,
  // eslint-disable-next-line node/no-missing-import
} from '../../typechain/index';

import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { BigNumberish } from 'ethers';

chai.use(solidity);

type OrderInfo = {
  owner: string;
  assetToken: string;
  amount: BigNumberish;
  price: BigNumberish;
  expireTime: BigNumberish;
  tokenId: BigNumberish;
  salt: BigNumberish;
};

describe('NFT Limit Order', function () {
  let signers: SignerWithAddress[];
  let me: SignerWithAddress;
  let meSafes: EvaSafes;
  let app: App;

  before(async function () {
    signers = await ethers.getSigners();
    me = signers[0];

    const ownerO = await ethers.getSigners();
    console.log(`deployer owner 2: ${ownerO[0].address}`);
    app = new App();
    await app.deploy();

    // 初始化钱包
    meSafes = (await app.createOrLoadWalletSeafes(me.address)).connect(me);
  });

  describe('create order by walletSafes', function () {
    const amount = 10000;
    const bob = '0x00F113faB82626dca0eE04b126629B4577F3d5E2';
    const order: OrderInfo = {
      owner: '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266',
      assetToken: '0xed5af388653567af2f388e6224dc7c4b3241c544',
      amount: 1,
      price: 1,
      expireTime: Math.ceil(new Date().getTime() / 1000) + 60 * 60 * 24,
      tokenId: 5964,
      salt: 1649944095,
    };
    let orderId: string;
    let flowId: number;

    let keeper: SignerWithAddress;

    before(async function () {
      keeper = signers[4];

      // create order
      const gasFund = 1e18;
      const callData = await help.encodeFunctionData('NftLimitOrderFlowProxy', 'create', [
        app.controler.address,
        app.nftLimitOrderFlowProxy.address,
        1,
        200000,
        order,
      ]);
      flowId = (await app.controler.getFlowMetaSize()).toNumber();

      const _value = ethers.BigNumber.from(order.amount).mul(ethers.BigNumber.from(order.price));
      meSafes.proxy(app.nftLimitOrderFlowProxy.address, HowToCall.Delegate, callData, {
        value: help.toFullNum(gasFund + _value.toNumber()),
      });

      orderId = await app.nftLimitOrderFlowProxy.hashOrder(order);

      // set keeper
      await app.config.addKeeper(keeper.address, KeepNetWork.Evabase);
    });

    it('should be execute ok when check pass', async function () {
      const orderFlowInfo = await app.controler.getFlowMetas(flowId);
      /**
       * (Order memory order, bytes memory signature, bytes[] memory data) = abi.decode(
            executeData,
            (Order, bytes, bytes[])
        );
        // _atomicMatch(order, signature, data, _assetTokenIds);
        _atomicMatch(order, signature, data);
       */

      const signature =
        // eslint-disable-next-line max-len
        '0x36a27d513a664a02db46cf65b33ebf00a583633ec32621413508e351753ce4503bf6748152e094cd35ed5f5e11d39b127343da527c8c43a8db21a9483f6cdd5f1b';

      /**
       * (address target, bytes memory input, uint256 value) = abi.decode(_data[i], (address, bytes, uint256));
       */
      const openseaInput = ethers.utils.AbiCoder.prototype.encode(
        ['address', 'bytes', 'uint256'],
        [me.address, signature, order.price],
      );
      const arr = [openseaInput];
      const executeData = ethers.utils.AbiCoder.prototype.encode(
        ['address', 'address', 'uint256', 'uint256', 'uint256', 'uint256', 'uint256', 'bytes', 'bytes[]'],
        [
          order.owner,
          order.assetToken,
          order.amount,
          order.price,
          order.expireTime,
          order.tokenId,
          order.salt,
          signature,
          arr,
        ],
      );

      // console.log('openseaInput:', openseaInput);
      // console.log('executeData:', executeData);
      const tx = await app.controler.connect(keeper).execFlow(keeper.address, flowId, executeData);

      // await expect(tx).to.not.emit(app.controler, 'FlowExecuteFailed');
      // await expect(tx).to.emit(app.controler, 'FlowExecuteSuccess');
      // await expect(tx).to.emit(app.nftLimitOrderFlowProxy, 'OrderExecuted');
    });
  });
});
