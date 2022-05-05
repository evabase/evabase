/* eslint-disable strict */
import chai, { expect } from 'chai';
import { ethers } from 'hardhat';
import { solidity } from 'ethereum-waffle';
// eslint-disable-next-line node/no-missing-import
import { help } from '../../scripts/help';

// eslint-disable-next-line node/no-missing-import
import {
  NftLimitOrderFlowProxy,
  EvaFlowController,
  EvaSafes,
  EvaSafesFactory,
  EvabaseConfig,
  // eslint-disable-next-line node/no-missing-import
} from '../../typechain/index';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
// import { BigNumberish } from 'ethers';

chai.use(solidity);

// type OrderInfo = {
//   owner: string;
//   assetToken: string;
//   amount: BigNumberish;
//   price: BigNumberish;
//   expireTime: BigNumberish;
//   tokenId: BigNumberish;
//   salt: BigNumberish;
// };

describe('NFTLimitOrder', function () {
  let nftLimitOrderFlowProxy: NftLimitOrderFlowProxy;
  let evaFlowController: EvaFlowController;
  let evabaseConfig: EvabaseConfig;
  let evaSafesFactory: EvaSafesFactory;
  let signers: SignerWithAddress[];
  let me: SignerWithAddress;
  let evaSafes: EvaSafes;
  // let evaSafesContract;

  before(async function () {
    signers = await ethers.getSigners();
    me = signers[0];
    evabaseConfig = (await help.deploy('EvabaseConfig')) as EvabaseConfig;
    evaSafesFactory = (await help.deploy('EvaSafesFactory', [evabaseConfig.address])) as EvaSafesFactory;

    nftLimitOrderFlowProxy = (await help.deploy('NftLimitOrderFlowProxy', [
      evabaseConfig.address,
      evaSafesFactory.address,
      'EVABASE',
      '1',
    ])) as NftLimitOrderFlowProxy;
    evaFlowController = (await help.deploy('EvaFlowController', [
      evabaseConfig.address,
      evaSafesFactory.address,
    ])) as EvaFlowController;

    await evaSafesFactory.create(me.address);

    const evaSafesAddress = await evaSafesFactory.get(me.address);
    const EvaSafes = await ethers.getContractFactory('EvaSafes');
    evaSafes = EvaSafes.attach(evaSafesAddress);
  });

  describe('createOrder', function () {
    it('check order hash', async function () {
      // 任何属性的变更都会使得Order哈希变化
      const orders = [
        {
          owner: '0x0000000000000000000000000000000000000002',
          assetToken: '0x0000000000000000000000000000000000000002',
          amount: 100,
          price: 12,
          expireTime: 1681,
          tokenId: 12,
          salt: 80912,
        },
        {
          owner: '0x0000000000000000000000000000000000000002',
          assetToken: '0x0000000000000000000000000000000000000003',
          amount: '100',
          price: '12',
          expireTime: '16897001',
          tokenId: '12',
          salt: '809887712',
        },
        {
          owner: '0x0000000000000000000000000000000000000002',
          assetToken: '0x0000000000000000000000000000000000000002',
          amount: '101',
          price: '12',
          expireTime: '16897001',
          tokenId: '12',
          salt: '809887712',
        },
        {
          owner: '0x0000000000000000000000000000000000000002',
          assetToken: '0x0000000000000000000000000000000000000002',
          amount: '100',
          price: '13',
          expireTime: '16897001',
          tokenId: '12',
          salt: '809887712',
        },
        {
          owner: '0x0000000000000000000000000000000000000002',
          assetToken: '0x0000000000000000000000000000000000000002',
          amount: '100',
          price: '12',
          expireTime: '16897002',
          tokenId: '12',
          salt: '809887712',
        },
        {
          owner: '0x0000000000000000000000000000000000000002',
          assetToken: '0x0000000000000000000000000000000000000002',
          amount: '100',
          price: '12',
          expireTime: '16897001',
          tokenId: '13',
          salt: '809887712',
        },
        {
          owner: '0x0000000000000000000000000000000000000002',
          assetToken: '0x0000000000000000000000000000000000000002',
          amount: '100',
          price: '12',
          expireTime: '16897001',
          tokenId: '12',
          salt: '809887713',
        },
      ];

      const keys = new Set<string>();

      for (const item of orders) {
        const key = await nftLimitOrderFlowProxy.hashOrder(item);
        expect(keys.has(key)).to.eq(false);
        keys.add(key);
      }
    });

    it('failed when owner not equal msg.sender', async function () {
      const order = {
        owner: signers[2].address,
        assetToken: '0x0000000000000000000000000000000000000002',
        amount: '100',
        price: '12',
        expireTime: '16897001',
        tokenId: '12',
        salt: '809887713',
      };
      await expect(nftLimitOrderFlowProxy.connect(me).createOrder(order, 1)).to.revertedWith(
        'only safes can creat order',
      );
    });
    it('failed when expireTime over', async function () {
      const order = {
        owner: signers[0].address,
        assetToken: '0x0000000000000000000000000000000000000002',
        amount: '100',
        price: '12',
        expireTime: 1000000,
        tokenId: '12',
        salt: '809887713',
      };

      // 正常
      order.expireTime = (await help.getBlockTime()) + 60 * 60 * 24 * 90 + 60;

      const dataBefore = await help.encodeFunctionData('NftLimitOrderFlowProxy', 'create', [
        evaFlowController.address,
        nftLimitOrderFlowProxy.address,
        1,
        200000,
        order,
      ]);

      await evaSafes.proxy(nftLimitOrderFlowProxy.address, 1, dataBefore, {
        value: ethers.utils.parseEther('0.01'),
      });
      order.expireTime = (await help.getBlockTime()) - 1;

      const dataAfter = await help.encodeFunctionData('NftLimitOrderFlowProxy', 'create', [
        evaFlowController.address,
        nftLimitOrderFlowProxy.address,
        1,
        200000,
        order,
      ]);

      await expect(
        evaSafes.proxy(nftLimitOrderFlowProxy.address, 1, dataAfter, {
          value: ethers.utils.parseEther('0.01'),
        }),
      ).to.revertedWith('invalid order.expireTime');
    });
    it('failed when exist', async function () {
      const order = {
        owner: me.address,
        assetToken: '0x0000000000000000000000000000000000000002',
        amount: '100',
        price: '12',
        expireTime: 98899999,
        tokenId: '12',
        salt: '809887713',
      };
      order.expireTime = (await help.getBlockTime()) + 60 * 10 - 10; // 10分钟-10秒
      const data = await help.encodeFunctionData('NftLimitOrderFlowProxy', 'create', [
        evaFlowController.address,
        nftLimitOrderFlowProxy.address,
        1,
        200000,
        order,
      ]);
      evaSafes.proxy(nftLimitOrderFlowProxy.address, 1, data, {
        value: ethers.utils.parseEther('0.01'),
      });

      await expect(
        evaSafes.proxy(nftLimitOrderFlowProxy.address, 1, data, {
          value: ethers.utils.parseEther('0.01'),
        }),
      ).to.revertedWith('order exist');
    });

    it('failed when msg.value is zero', async function () {
      const order = {
        owner: me.address,
        assetToken: '0x0000000000000000000000000000000000000002',
        amount: '100',
        price: '12',
        expireTime: 99999999,
        tokenId: '12',
        salt: '809887713',
      };

      const data = await help.encodeFunctionData('NftLimitOrderFlowProxy', 'create', [
        evaFlowController.address,
        nftLimitOrderFlowProxy.address,
        1,
        200000,
        order,
      ]);

      // 太少
      await expect(evaSafes.proxy(nftLimitOrderFlowProxy.address, 1, data)).to.reverted;
    });
  });
  describe('execute order', function () {
    const createNewOrder = async function (user: SignerWithAddress) {
      const order = {
        owner: user.address,
        assetToken: user.address,
        amount: '1000',
        price: '1',
        expireTime: '1680355507',
        tokenId: 342905,
        salt: '1899909',
      };

      const data = await help.encodeFunctionData('NftLimitOrderFlowProxy', 'create', [
        evaFlowController.address,
        nftLimitOrderFlowProxy.address,
        1,
        200000,
        order,
      ]);

      await evaSafes.proxy(nftLimitOrderFlowProxy.address, 1, data, {
        value: ethers.utils.parseEther('0.01'),
      });

      // console.log('create order:', order);
    };

    before(async function () {
      await createNewOrder(me);
    });

    it('failed when order is canceld', async function () {
      const cancelData = nftLimitOrderFlowProxy.interface.encodeFunctionData('destroyFlow', [
        evaFlowController.address,
        1,
      ]);

      await evaSafes.proxy(nftLimitOrderFlowProxy.address, 1, cancelData);
      expect(await (await evaFlowController.getFlowMetas(1)).flowStatus).to.eq(2);
    });
  });
});
