import chai, { expect } from "chai";
import { ethers } from "hardhat";
import { solidity } from "ethereum-waffle";
// eslint-disable-next-line node/no-missing-import
import { help } from "../help";

// eslint-disable-next-line node/no-missing-import
import type {
  MockSwapStrategy,
  MockERC20,
  LOBExchange,
  // eslint-disable-next-line node/no-missing-import
} from "../../typechain/index";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { BigNumberish, BytesLike } from "ethers";
chai.use(solidity);

type OrderInfo = {
  owner: string;
  inputAmount: number;
  inputToken: string;
  minRate: BigNumberish;
  outputToken: string;
  expiration: number;
  receiptor: string;
  foc: boolean;
  extraData: BytesLike;
};

describe("EvabaseConfig", function () {
  let strategy: MockSwapStrategy;
  let USDC: MockERC20;
  let WBTC: MockERC20;
  let exchange: LOBExchange;
  let signers: SignerWithAddress[];
  let me: SignerWithAddress;
  const exchangeConfig = {
    paused: false,
    basisPointsRate: 0.001 * 10000,
    feeTo: "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512",
  };
  before(async function () {
    signers = await ethers.getSigners();
    me = signers[1];
    strategy = (await help.deploy("MockSwapStrategy")) as MockSwapStrategy;
    exchange = (await help.deploy("LOBExchange", [
      strategy.address,
    ])) as LOBExchange;
    USDC = (await help.deployERC20("USDC")) as MockERC20;
    WBTC = (await help.deployERC20("WBTC", 8)) as MockERC20;

    await exchange.setConfig(exchangeConfig);
  });

  describe("createOrder", function () {
    it("failed when owner not equal msg.sender", async function () {
      const order = {
        owner: signers[2].address,
        inputAmount: 1,
        inputToken: USDC.address,
        minRate: ethers.utils.parseUnits("4800", 18),
        outputToken: WBTC.address,
        expiration: Math.ceil(new Date().getTime() / 1000) + 10 * 1000,
        receiptor: me.address,
        foc: false,
        extraData: "0x",
      };
      await expect(exchange.connect(me).createOrder(order)).to.revertedWith(
        "WRONG_INPUT_OWNER"
      );
    });
    it("failed when expiration over", async function () {
      const order = {
        owner: signers[1].address,
        inputAmount: 1,
        inputToken: USDC.address,
        minRate: ethers.utils.parseUnits("4800", 18),
        outputToken: WBTC.address,
        expiration: 0,
        receiptor: me.address,
        foc: false,
        extraData: "0x",
      };
      // 不低于10分钟
      order.expiration = (await help.getBlockTime()) + 60 * 10 - 10; // 10分钟-10秒
      await expect(exchange.connect(me).createOrder(order)).to.revertedWith(
        "WRONG_EXPIRATION"
      );
      console.log("time2:", await help.getBlockTime());

      // 不超过90天
      order.expiration = (await help.getBlockTime()) + 60 * 60 * 24 * 90 + 60;
      await expect(exchange.connect(me).createOrder(order)).to.revertedWith(
        "WRONG_EXPIRATION"
      );
    });
    it("failed when exist", async function () {
      const order = {
        owner: me.address,
        inputAmount: 2,
        inputToken: USDC.address,
        minRate: ethers.utils.parseUnits("4800", 18),
        outputToken: WBTC.address,
        expiration: Math.ceil(new Date().getTime() / 1000) + 10 * 1000,
        receiptor: me.address,
        foc: false,
        extraData: "0x",
      };
      await USDC.connect(me).mint(order.inputAmount);
      await USDC.connect(me).approve(exchange.address, order.inputAmount);

      await exchange.connect(me).createOrder(order); // ok
      await expect(exchange.connect(me).createOrder(order)).to.revertedWith(
        "ORDER_EXIST"
      );
    });

    it("failed when msg.value is zero", async function () {
      const order = {
        owner: me.address,
        inputAmount: 1000,
        inputToken: help.ETH_ADDRESS,
        minRate: ethers.utils.parseUnits("4800", 18),
        outputToken: WBTC.address,
        expiration: (await help.getBlockTime()) + 60 * 60 * 24,
        receiptor: me.address,
        foc: false,
        extraData: "0x",
      };
      await expect(exchange.connect(me).createOrder(order)).to.revertedWith(
        "WRONG_INPUT_AMOUNT"
      );

      // 太多
      await expect(
        exchange.connect(me).createOrder(order, { value: 999 })
      ).to.revertedWith("WRONG_INPUT_AMOUNT");

      // 太少
      await expect(
        exchange.connect(me).createOrder(order, { value: 1001 })
      ).to.revertedWith("WRONG_INPUT_AMOUNT");
    });
    it("normal order", async function () {

      const order = {
        owner: me.address,
        inputAmount: 10000,
        inputToken: USDC.address,
        minRate: ethers.utils.parseUnits("4800", 18),
        outputToken: WBTC.address,
        expiration: Math.ceil(new Date().getTime() / 1000) + 10 * 1000,
        receiptor: me.address,
        foc: false,
        extraData: "0x",
      };

      // approve
      await USDC.connect(me).mint(order.inputAmount);
      await USDC.connect(me).approve(exchange.address, order.inputAmount);
      const orderId = await exchange.keyOf(order);

      const fee = (order.inputAmount * exchangeConfig.basisPointsRate) / 10000;
      // 检查订单创建
      // 事件，和转账信息
      await expect(exchange.connect(me).createOrder(order))
        .to.emit(exchange, "OrderCreated") // 订单事件
        .withArgs(orderId, fee)
        .and.to.emit(USDC, "Transfer") // 从msg.sender 转Token
        .withArgs(me.address, exchange.address, order.inputAmount)
        .and.to.emit(USDC, "Transfer") // 将手续费转给 feeTo
        .withArgs(exchange.address, exchangeConfig.feeTo, fee);

      const orderInfo = await exchange.getOrderInfo(orderId);

      expect(orderInfo[0].owner).to.eq(order.owner);
      expect(orderInfo[0].inputAmount).to.eq(order.inputAmount);
      expect(orderInfo[0].inputToken).to.eq(order.inputToken);
      expect(orderInfo[0].minRate).to.eq(order.minRate);
      expect(orderInfo[0].outputToken).to.eq(order.outputToken);
      expect(orderInfo[0].expiration).to.eq(order.expiration);
      expect(orderInfo[0].receiptor).to.eq(order.receiptor);
      expect(orderInfo[0].foc).to.eq(order.foc);
      expect(orderInfo[0].extraData).to.eq(order.extraData);

      expect(orderInfo[1].balance).to.eq(order.inputAmount - fee);
      expect(orderInfo[1].paused).to.eq(false);
    });
  });
  describe("execute order", function () {
    let order: OrderInfo;
    // let fee = (order.inputAmount * exchangeConfig.basisPointsRate) / 10000;
    let orderId: string;

    const createNewOrder = async function (
      user: SignerWithAddress,
      inputAmount: number,
      maxWaitTime: number,
      price = 1
    ) {
      const order: OrderInfo = {
        owner: user.address,
        inputAmount: inputAmount,
        inputToken: USDC.address,
        minRate: ethers.utils.parseUnits(price.toString(), 18),
        outputToken: WBTC.address,
        expiration: (await help.getBlockTime()) + maxWaitTime,
        receiptor: user.address,
        foc: false,
        extraData: "0x",
      };

      // approve
      await USDC.connect(user).mint(inputAmount);
      await USDC.connect(user).approve(exchange.address, inputAmount);
      exchange.connect(user).createOrder(order);
      orderId = await exchange.keyOf(order);
      return { order, orderId };
    };

    before(async function () {
      const result = await createNewOrder(me, 10000, 60 * 60 * 24);
      order = result.order;
      orderId = result.orderId;
    });

    it("failed when order is paused", async function () {
      await exchange.connect(me).setPause(orderId, true);

      await expect(
        exchange.executeOrder(orderId, strategy.address, order.inputToken, "0x")
      ).to.revertedWith("ORDER_NOT_ACTIVE");

      await exchange.connect(me).setPause(orderId, false);
    });

    it("failed when order is expired", async function () {
      const info = await createNewOrder(me, 30, 60 * 11);

      await help.setNextBlockTimestamp(info.order.expiration + 1);
      await expect(
        exchange.executeOrder(
          info.orderId,
          strategy.address,
          info.order.inputToken,
          "0x"
        )
      ).to.revertedWith("ORDER_NOT_ACTIVE");
    });

    it("failed when order is canceld", async function () {
      const info = await createNewOrder(me, 20, 3600 * 24);

      await exchange.connect(me).cancelOrder(info.orderId);

      await expect(
        exchange.executeOrder(
          info.orderId,
          strategy.address,
          info.order.inputToken,
          "0x"
        )
      ).to.revertedWith("ORDER_NOT_ACTIVE");
    });

    it("failed when system paused", async function () {
      const info = await createNewOrder(me, 10, 3600 * 24);

      exchangeConfig.paused = true;
      await exchange.setConfig(exchangeConfig);

      try {
        await expect(
          exchange.executeOrder(
            info.orderId,
            strategy.address,
            info.order.inputToken,
            "0x"
          )
        ).to.revertedWith("LOB_PAUSED");
      } finally {
        exchangeConfig.paused = false;
        await exchange.setConfig(exchangeConfig);
      }
    });
  });
});
