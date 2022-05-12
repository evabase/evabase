/* eslint-disable node/no-missing-import */
'use strict';
import { ethers } from 'hardhat';
import { help } from '../scripts/help';
import {
  EvabaseConfig,
  EvaFlowController,
  EvaSafesFactory,
  EvaBaseServerBot,
  NftLimitOrderFlowProxy,
  EvaFlowChainLinkKeeperBot,
  EvaFlowRandomChecker,
  UniswapV2Strategy,
  LOBExchange,
  EvaFlowStatusUpkeep,
} from '../typechain/index';
import { initEvebase } from './initEvebase';

import { UniswapV2 } from './shared/uniswapv2/factory';

export enum HowToCall {
  Call,
  Delegate,
}

export enum CompareOperator {
  Eq,
  Ne,
  Ge,
  Gt,
  Le,
  Lt,
}

export enum FlowStatus {
  Active, // 可执行
  Paused,
  Destroyed,
  Expired,
  Completed,
  Unknown,
}

export enum KeepNetWork {
  ChainLink,
  Evabase,
  Gelato,
  Others,
}

export class App {
  public config!: EvabaseConfig;
  public safesFactory!: EvaSafesFactory;
  public controler!: EvaFlowController;
  public evaFlowChecker!: EvaFlowRandomChecker;
  public evaBaseServerBot!: EvaBaseServerBot;
  public nftLimitOrderFlowProxy!: NftLimitOrderFlowProxy;
  public evaFlowChainLinkKeeperBot!: EvaFlowChainLinkKeeperBot;
  public uni!: UniswapV2;
  public uniStrategy!: UniswapV2Strategy;
  public lobExchange!: LOBExchange;
  public flowStatusUpKeep!: EvaFlowStatusUpkeep;

  async deploy() {
    const admin = await ethers.provider.getSigner();
    const result = await initEvebase();
    this.config = result.evabaseConfig as EvabaseConfig;
    this.safesFactory = result.evaSafesFactory as EvaSafesFactory;
    this.controler = result.evaFlowController as EvaFlowController;
    this.evaFlowChecker = result.evaFlowChecker as EvaFlowRandomChecker;
    this.evaBaseServerBot = result.evaBaseServerBot as EvaBaseServerBot;
    this.nftLimitOrderFlowProxy = result.nftLimitOrderFlowProxy as NftLimitOrderFlowProxy;
    this.evaFlowChainLinkKeeperBot = result.evaFlowChainLinkKeeperBot as EvaFlowChainLinkKeeperBot;

    this.flowStatusUpKeep = (await help.deploy('EvaFlowStatusUpkeep', [
      this.controler.address,
      0,
    ])) as EvaFlowStatusUpkeep;
    await this.controler.setFlowOperators(this.flowStatusUpKeep.address, true);
  }

  async createOrLoadWalletSeafes(acct: string) {
    let find = await this.safesFactory.get(acct);
    if (find === ethers.constants.AddressZero) {
      await this.safesFactory.create(acct);
      find = await this.safesFactory.get(acct);
    }

    return ethers.getContractAt('EvaSafes', find);
  }

  async enableERC20LimitOrderService() {
    const admin = await ethers.provider.getSigner();
    const exchangeConfig = {
      paused: false,
      basisPointsRate: 0.001 * 10000,
      feeTo: '0x00F113faB82626dca0eE04b126629B4577F3d5E2',
    };

    // 创建流动性
    const uni = new UniswapV2();
    await uni.initApp(admin);

    this.uniStrategy = (await help.deploy('UniswapV2Strategy', [uni.router02!.address, 997])) as UniswapV2Strategy;
    this.lobExchange = (await help.deploy('LOBExchange', [this.uniStrategy.address, exchangeConfig])) as LOBExchange;
  }
}
