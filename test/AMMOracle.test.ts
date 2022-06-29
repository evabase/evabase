'use strict';
import { UniswapV2 } from './shared/uniswapv2/factory';
import { ethers } from 'hardhat';
import { help } from '../scripts/help';
import { ERC20, IUniswapV2Router02, MockERC20, AMMOracle } from '../typechain';
import { expect } from 'chai';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { BigNumber } from 'ethers';
describe('AMMOracle', function () {
  const uni = new UniswapV2();
  let router: IUniswapV2Router02;
  let user: SignerWithAddress;
  let USDC: MockERC20;
  let USDT: MockERC20;
  let ammOracle: AMMOracle;
  before(async function () {
    const wallets = await ethers.getSigners();
    user = wallets[0];
    await uni.initApp(user);

    // 创建流动性
    router = uni.router02 as IUniswapV2Router02;
    // strategy = (await help.deploy('AMMOracle', [uni.router02!.address, 997])) as UniswapV2Strategy;

    USDC = (await help.deployERC20('USDC')) as MockERC20;
    await USDC.mint(help.toFullNum(1000000000 * 1e18));
    USDT = (await help.deployERC20('USDT', 6)) as MockERC20;
    await USDT.mint(help.toFullNum(2000000000 * 1e18));
    ammOracle = (await help.deploy('AMMOracle', [
      uni.factoryV2?.address,
      USDT.address,
      USDC.address,
      uni.WETHPartner?.address,
    ])) as AMMOracle;
    // 授权
    await (uni.token0! as ERC20).approve(router.address, ethers.constants.MaxUint256);
    await (uni.token1! as ERC20).approve(router.address, ethers.constants.MaxUint256);
    await (uni.WETHPartner! as ERC20).approve(router.address, ethers.constants.MaxUint256);
    await USDC.approve(router.address, ethers.constants.MaxUint256);
    await USDT.approve(router.address, ethers.constants.MaxUint256);
    // await uni.factoryV2!.createPair(uni.WETHPartner!.address, USDC.address);
    // await uni.factoryV2!.createPair(uni.WETHPartner!.address, USDT.address);
  });

  it('getUPrice', async function () {
    const amount0 = help.toFullNum(100 * 1e18);
    const amount1 = help.toFullNum(200 * 1e18);
    // 添加流动性
    await router.addLiquidity(
      USDC.address,
      uni.token1!.address,
      amount0,
      amount1,
      1,
      1,
      user.address,
      ethers.constants.MaxUint256,
    );

    const resut = (await ammOracle.getUPrice(uni.token1!.address)) as BigNumber;
    // console.log(resut);
    expect(resut).to.equal(ethers.BigNumber.from(amount0).mul(ethers.BigNumber.from(10).pow(18)).div(amount1));
  });

  it('getBatchUPrice', async function () {
    const amount0 = help.toFullNum(100 * 1e10);
    const amount1 = help.toFullNum(200 * 1e10);

    const amount2 = help.toFullNum(500 * 1e10);
    const amount3 = help.toFullNum(600 * 1e10);
    // 添加流动性
    await router.addLiquidity(
      USDC.address,
      uni.token1!.address,
      amount0,
      amount1,
      1,
      1,
      user.address,
      ethers.constants.MaxUint256,
    );

    await router.addLiquidity(
      uni.WETHPartner!.address,
      uni.token1!.address,
      amount0,
      amount1,
      1,
      1,
      user.address,
      ethers.constants.MaxUint256,
    );

    await router.addLiquidity(
      USDT.address,
      uni.token0!.address,
      amount2,
      amount3,
      1,
      1,
      user.address,
      ethers.constants.MaxUint256,
    );

    const tokens = [uni.token1!.address, uni.token0!.address, uni.WETHPartner!.address];

    const resut = await ammOracle.getBatchUPrice(tokens);
    // console.log(resut);
    // 500000000000000000
    // 500000000000000000
    expect(resut[0]).to.equal(ethers.BigNumber.from(amount0).mul(ethers.BigNumber.from(10).pow(18).div(amount1)));
    expect(resut[2]).to.equal(ethers.BigNumber.from(0));
  });
});
