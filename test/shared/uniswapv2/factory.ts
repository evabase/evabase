'use strict';
import { deployContract } from 'ethereum-waffle';
import { BigNumber, Contract, ethers, Signer, Wallet } from 'ethers';

import UniswapV2Factory from './build/UniswapV2Factory.json';
import IUniswapV2Pair from './build/IUniswapV2Pair.json';
import ERC20 from './build/ERC20.json';
import WETH9 from './build/WETH9.json';
import UniswapV2Router02 from './build/UniswapV2Router02.json';

const overrides = {
  gasLimit: 9999999,
};

function expandTo18Decimals(n: number): BigNumber {
  return ethers.BigNumber.from(n).mul(ethers.BigNumber.from(10).pow(18));
}

export class UniswapV2 {
  public token0?: Contract;
  public token1?: Contract;
  public WETH?: Contract;
  public WETHPartner?: Contract;
  public factoryV2?: Contract;
  public router02?: Contract;
  public pair?: Contract;
  public WETHPair?: Contract;

  async initApp(wallet: Signer) {
    // deploy tokens
    const tokenA = await deployContract(wallet, ERC20, [expandTo18Decimals(10000)]);
    const tokenB = await deployContract(wallet, ERC20, [expandTo18Decimals(10000)]);
    const WETH = await deployContract(wallet, WETH9);
    const WETHPartner = await deployContract(wallet, ERC20, [expandTo18Decimals(10000)]);

    const provider = tokenA.provider;

    // deploy V2
    const factoryV2 = await deployContract(wallet, UniswapV2Factory, [await wallet.getAddress()]);

    // deploy routers
    const router02 = await deployContract(wallet, UniswapV2Router02, [factoryV2.address, WETH.address], overrides);

    // initialize V2
    await factoryV2.createPair(tokenA.address, tokenB.address);
    const pairAddress = await factoryV2.getPair(tokenA.address, tokenB.address);
    const pair = new Contract(pairAddress, JSON.stringify(IUniswapV2Pair.abi), provider).connect(wallet);

    const token0Address = await pair.token0();
    const token0 = tokenA.address === token0Address ? tokenA : tokenB;
    const token1 = tokenA.address === token0Address ? tokenB : tokenA;

    await factoryV2.createPair(WETH.address, WETHPartner.address);
    const WETHPairAddress = await factoryV2.getPair(WETH.address, WETHPartner.address);
    const WETHPair = new Contract(WETHPairAddress, JSON.stringify(IUniswapV2Pair.abi), provider).connect(wallet);

    this.token0 = token0;
    this.token1 = token1;
    this.WETH = WETH;
    this.WETHPartner = WETHPartner;
    this.factoryV2 = factoryV2;
    this.router02 = router02;
    this.pair = pair;
    this.WETHPair = WETHPair;
  }
}
