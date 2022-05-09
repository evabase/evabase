'use strict';
// eslint-disable-next-line strict
import chai, { expect } from 'chai';
import { ethers } from 'hardhat';
import { solidity } from 'ethereum-waffle';
// eslint-disable-next-line node/no-missing-import
import { help } from '../../scripts/help';

// eslint-disable-next-line node/no-missing-import
import {
  MockSwapStrategy,
  MockERC20,
  LOBExchange,
  // eslint-disable-next-line node/no-missing-import
} from '../../typechain/index';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { BigNumberish } from 'ethers';
chai.use(solidity);

type OrderInfo = {
  owner: string;
  inputAmount: BigNumberish;
  inputToken: string;
  minRate: BigNumberish;
  outputToken: string;
  deadline: number;
  receiptor: string;
  minInputPer: number;
};

describe('ERC20 Limit Order', function () {
  let strategy: MockSwapStrategy;
  let USDC: MockERC20;
  let WBTC: MockERC20;
  let exchange: LOBExchange;
  let signers: SignerWithAddress[];
  let me: SignerWithAddress;
  const exchangeConfig = {
    paused: false,
    basisPointsRate: 0.001 * 10000,
    feeTo: '0x00F113faB82626dca0eE04b126629B4577F3d5E2',
  };
  before(async function () {
    signers = await ethers.getSigners();
    me = signers[1];
    strategy = (await help.deploy('MockSwapStrategy')) as MockSwapStrategy;
    exchange = (await help.deploy('LOBExchange', [strategy.address, exchangeConfig])) as LOBExchange;
    USDC = (await help.deployERC20('USDC')) as MockERC20;
    WBTC = (await help.deployERC20('WBTC', 8)) as MockERC20;
    console.log(WBTC.address);
  });

  describe('support ETH', function () {
    const amount = 10000;
    const bob = '0x00F113faB82626dca0eE04b126629B4577F3d5E2';
    const order: OrderInfo = {
      owner: bob,
      inputAmount: amount,
      inputToken: help.ETH_ADDRESS,
      minRate: ethers.utils.parseUnits('1', 18),
      outputToken: '',
      deadline: Math.ceil(new Date().getTime() / 1000) + 60 * 60 * 24,
      receiptor: bob,
      minInputPer: 1,
    };

    before(async function () {
      order.owner = me.address;
      order.outputToken = USDC.address;
      order.receiptor = bob;
    });
    it('failed when invalid eth amount', async function () {
      // 检查 ETH 的输入
      await expect(exchange.connect(me).createOrder(order)).to.revertedWith('WRONG_INPUT_AMOUNT');
      await expect(exchange.connect(me).createOrder(order, { value: amount - 1 })).to.revertedWith(
        'WRONG_INPUT_AMOUNT',
      );
      await expect(exchange.connect(me).createOrder(order, { value: amount + 1 })).to.revertedWith(
        'WRONG_INPUT_AMOUNT',
      );
    });
    it('should be receive ETH when cancel order', async function () {
      const tx = exchange.connect(me).createOrder(order, { value: amount });

      const feeUser = new ethers.VoidSigner(exchangeConfig.feeTo, ethers.provider);
      const receiptor = new ethers.VoidSigner(order.receiptor, ethers.provider);
      const owner = new ethers.VoidSigner(order.owner, ethers.provider);

      // 创建订单时，将分发ETH到 FEE账户和当前合约
      await expect(await tx)
        .to.changeEtherBalance(exchange, 9990) // 9990= amount * (1-0.001)
        .to.changeEtherBalance(feeUser, 10); // 10= amount * (0.001)
      const orderId = await exchange.keyOf(order);

      // 取消订单时，将返还 ETH 给 receiptor
      console.log(me.address, receiptor.address);
      await expect(await exchange.connect(me).cancelOrder(orderId))
        .to.changeEtherBalance(receiptor, 9990)
        .to.changeEtherBalance(owner, 0);
    });
  });
});
