'use strict';
import { UniswapV2 } from './shared/uniswapv2/factory';
import { ethers } from 'hardhat';
import { help, contractData, head, constData, CallWay, Operator } from '../scripts/help';
import { ERC20, IUniswapV2Router02, RequireBlock, MockERC20, AMMOracle, MockRequire } from '../typechain';
import { expect } from 'chai';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { BigNumber, BigNumberish } from 'ethers';
describe('RequireBlock', function () {
  const uni = new UniswapV2();
  let router: IUniswapV2Router02;
  let requireBlock: RequireBlock;
  let mockRequire: MockRequire;
  let user: SignerWithAddress;
  let USDC: MockERC20;
  let USDT: MockERC20;
  let ammOracle: AMMOracle;
  const amount0 = help.toFullNum(100 * 1e18);
  const amount1 = help.toFullNum(200 * 1e18);
  const amount2 = help.toFullNum(300 * 1e18);
  const totalUSDC = BigNumber.from('1000000000000000000000000000');
  before(async function () {
    const wallets = await ethers.getSigners();
    user = wallets[0];
    await uni.initApp(user);

    // 创建流动性
    router = uni.router02 as IUniswapV2Router02;
    // strategy = (await help.deploy('AMMOracle', [uni.router02!.address, 997])) as UniswapV2Strategy;

    USDC = (await help.deployERC20('USDC')) as MockERC20;
    await USDC.mint(totalUSDC);
    USDT = (await help.deployERC20('USDT', 6)) as MockERC20;
    await USDT.mint(help.toFullNum(2000000000 * 1e18));
    ammOracle = (await help.deploy('AMMOracle', [
      uni.factoryV2?.address,
      USDT.address,
      USDC.address,
      uni.WETHPartner?.address,
    ])) as AMMOracle;

    requireBlock = (await help.deploy('RequireBlock', [])) as RequireBlock;
    mockRequire = (await help.deploy('MockRequire', [])) as MockRequire;
    // 授权
    await (uni.token0! as ERC20).approve(router.address, ethers.constants.MaxUint256);
    await (uni.token1! as ERC20).approve(router.address, ethers.constants.MaxUint256);
    await (uni.WETHPartner! as ERC20).approve(router.address, ethers.constants.MaxUint256);
    await USDC.approve(router.address, ethers.constants.MaxUint256);
    await USDT.approve(router.address, ethers.constants.MaxUint256);
    // await uni.factoryV2!.createPair(uni.WETHPartner!.address, USDC.address);
    // await uni.factoryV2!.createPair(uni.WETHPartner!.address, USDT.address);

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
      USDC.address,
      uni.token0!.address,
      amount0,
      amount2,
      1,
      1,
      user.address,
      ethers.constants.MaxUint256,
    );
  });

  it('price1 > price0 is true', async function () {
    const headData = await head(Operator.Gt, CallWay.StaticCall, CallWay.StaticCall);
    const contractCallDataA = ammOracle.interface.encodeFunctionData('getUPrice', [uni.token1!.address]);
    const dataA = await contractData(ammOracle.address, contractCallDataA);
    const contractCallDataB = ammOracle.interface.encodeFunctionData('getUPrice', [uni.token0!.address]);
    const dataB = await contractData(ammOracle.address, contractCallDataB);
    const expression = ethers.utils.hexConcat([headData, dataA, dataB]);

    // const tx = await requireBlock.exec(expression);
    await expect(requireBlock.exec(expression)).to.ok;
    // console.log(tx);
  });

  it('price1 < price0 is false & revert', async function () {
    const headData = await head(Operator.Lt, CallWay.StaticCall, CallWay.StaticCall);
    const contractCallDataA = ammOracle.interface.encodeFunctionData('getUPrice', [uni.token1!.address]);
    const dataA = await contractData(ammOracle.address, contractCallDataA);
    const contractCallDataB = ammOracle.interface.encodeFunctionData('getUPrice', [uni.token0!.address]);
    const dataB = await contractData(ammOracle.address, contractCallDataB);
    const expression = ethers.utils.hexConcat([headData, dataA, dataB]);

    await expect(requireBlock.exec(expression)).to.revertedWith('!<');
  });

  it('const 100 < USDT total', async function () {
    const headData = await head(Operator.Lt, CallWay.Const, CallWay.StaticCall);
    const dataA = await constData(100, 32);
    const contractCallDataB = USDT.interface.encodeFunctionData('totalSupply');
    const dataB = await contractData(USDT.address, contractCallDataB);
    const expression = ethers.utils.hexConcat([headData, dataA, dataB]);
    // const tx = await requireBlock.exec(expression);
    await expect(requireBlock.exec(expression)).to.ok;
  });
  it('Const eq StaticCall test', async function () {
    const headData = await head(Operator.Eq, CallWay.Const, CallWay.StaticCall);
    const dataA = await constData(totalUSDC, 32);
    const contractCallDataB = USDC.interface.encodeFunctionData('totalSupply');
    const dataB = await contractData(USDC.address, contractCallDataB);
    const expression = ethers.utils.hexConcat([headData, dataA, dataB]);
    // const tx = await requireBlock.exec(expression);
    await expect(requireBlock.exec(expression)).to.ok;
  });
  it('const 123 < 124', async function () {
    const headData = await head(Operator.Lt, CallWay.Const, CallWay.Const);
    const dataA = await constData(123, 32);
    const dataB = await constData(124, 32);
    const expression = ethers.utils.hexConcat([headData, dataA, dataB]);
    // const tx = await requireBlock.exec(expression);
    await expect(requireBlock.exec(expression)).to.ok;
  });
  it('const 123 != 123 revert', async function () {
    const headData = await head(Operator.NEq, CallWay.Const, CallWay.Const);
    const dataA = await constData(123, 32);
    const dataB = await constData(123, 32);
    const expression = ethers.utils.hexConcat([headData, dataA, dataB]);
    // const tx = await requireBlock.exec(expression);
    await expect(requireBlock.exec(expression)).to.revertedWith('!!=');
  });
  it('const 123 < mockRequired.call', async function () {
    const headData = await head(Operator.Lt, CallWay.Const, CallWay.Call);
    const dataA = await constData(100, 32);
    const amount1 = 78899 as number;
    const contractCallDataB = mockRequire.interface.encodeFunctionData('mockCallWithReturnUint', [amount1]);
    const dataB = await contractData(mockRequire.address, contractCallDataB);

    // console.log(USDT.address);
    // console.log(contractCallDataB);
    const expression = ethers.utils.hexConcat([headData, dataA, dataB]);
    // const tx = await requireBlock.exec(expression);
    await expect(requireBlock.exec(expression)).to.ok;
  });
});
