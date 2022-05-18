'use strict';
import { UniswapV2 } from './shared/uniswapv2/factory';
import { ethers } from 'hardhat';
import { help } from '../scripts/help';
import { ERC20, IUniswapV2Router02, UniswapV2Strategy } from '../typechain';
import { expect } from 'chai';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
describe('UniswapV2Strategy', function () {
  const uni = new UniswapV2();
  let router: IUniswapV2Router02;
  let strategy: UniswapV2Strategy;
  let user: SignerWithAddress;
  before(async function () {
    const wallets = await ethers.getSigners();
    user = wallets[0];
    await uni.initApp(user);

    // 创建流动性
    router = uni.router02 as IUniswapV2Router02;
    strategy = (await help.deploy('UniswapV2Strategy', [uni.router02!.address, 997])) as UniswapV2Strategy;

    // 授权
    await (uni.token0! as ERC20).approve(router.address, ethers.constants.MaxUint256);
    await (uni.token1! as ERC20).approve(router.address, ethers.constants.MaxUint256);
  });

  it('swap ERC20', async function () {
    const amount0 = help.toFullNum(1000 * 1e18);
    const amount1 = help.toFullNum(1000 * 1e18);
    // 添加流动性
    await router.addLiquidity(
      uni.token0!.address,
      uni.token1!.address,
      amount0,
      amount1,
      1,
      1,
      user.address,
      ethers.constants.MaxUint256,
    );

    const amount = help.toFullNum(1e18);
    const rate = help.toFullNum(0.8 * 1e18);
    const resut = await strategy.getRouter(uni.token0!.address, uni.token1!.address, amount, rate);
    expect(resut.input).to.gt(0);
    expect(resut.output).to.gt(resut.input.mul(rate).div(help.toFullNum(1e18)));

    // 模拟将资产放入到 strategy
    await (uni.token0 as ERC20).transfer(strategy.address, resut.input);
    const tx = await strategy.execute(uni.token0!.address, uni.token1!.address, resut.execData);

    await expect(tx)
      .to.emit(uni.token1 as ERC20, 'Transfer')
      .withArgs(strategy.address, tx.from, resut.output);
  });

  it('swap ETH to ERC20', async function () {
    const amount0 = help.toFullNum(1000 * 1e18);
    const amount1 = help.toFullNum(1000 * 1e18);
    const token1 = uni.token0! as ERC20;
    // 添加流动性
    await router.addLiquidityETH(token1.address, amount1, 1, 1, user.address, ethers.constants.MaxUint256, {
      value: amount0,
    });

    const amount = help.toFullNum(1e18);
    const rate = help.toFullNum(0.8 * 1e18);

    const ETH = help.ETH_ADDRESS;

    const resut = await strategy.getRouter(ETH, token1.address, amount, rate);
    expect(resut.input).to.gt(0);
    expect(resut.output).to.gt(resut.input.mul(rate).div(help.toFullNum(1e18)));
    console.log(
      resut.input.toString(),
      resut.output.toString(),
      resut.input.mul(rate).div(help.toFullNum(1e18)).toString(),
    );
    // 模拟将资产放入到 strategy
    await user.sendTransaction({ to: strategy.address, value: resut.input });
    const tx = await strategy.execute(ETH, token1.address, resut.execData);

    await expect(tx).to.emit(token1, 'Transfer').withArgs(strategy.address, tx.from, resut.output);
  });

  it('swap ERC20 to ETH', async function () {
    const amount0 = help.toFullNum(1000 * 1e18);
    const amount1 = help.toFullNum(1000 * 1e18);
    const token1 = uni.token0! as ERC20;
    // 添加流动性
    await router.addLiquidityETH(token1.address, amount1, 0, 0, user.address, ethers.constants.MaxUint256, {
      value: amount0,
    });

    const amount = help.toFullNum(1000 * 1e18);
    const rate = help.toFullNum(0.8 * 1e18);

    const ETH = help.ETH_ADDRESS;

    const resut = await strategy.getRouter(token1.address, ETH, amount, rate);
    const outInfo = await router.getAmountsOut(resut.input, [token1.address, uni.WETH!.address]);

    expect(resut.input).to.gt(0).lte(amount);
    expect(resut.output).to.gte(resut.input.mul(rate).div(help.toFullNum(1e18)));

    // 模拟将资产放入到 strategy
    await token1.transfer(strategy.address, resut.input);
    const tx = await strategy.execute(token1.address, ETH, resut.execData);

    await expect(tx).to.changeEtherBalance(user, resut.output);
  });
});
