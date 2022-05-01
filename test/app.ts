'use strict';
import { ethers } from 'hardhat';
import { EvabaseConfig, EvaFlowController, EvaSafesFactory } from '../typechain/index';
import { initEvebase } from './initEvebase';

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

  async deploy() {
    const result = await initEvebase();
    this.config = result.evabaseConfig as EvabaseConfig;
    this.safesFactory = result.evaSafesFactory as EvaSafesFactory;
    this.controler = result.evaFlowController as EvaFlowController;
  }

  async createOrLoadWalletSeafes(acct: string) {
    let find = await this.safesFactory.get(acct);
    if (find === ethers.constants.AddressZero) {
      await this.safesFactory.create(acct);
      find = await this.safesFactory.get(acct);
    }

    return ethers.getContractAt('EvaSafes', find);
  }
}
