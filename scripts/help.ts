'use strict';
import path from 'path';
import { ethers, network } from 'hardhat';
import { ethers as ethersV5 } from 'ethers';

let zeros = '0';
while (zeros.length < 256) {
  zeros += zeros;
}

const { Store } = require('data-store');
export const store = new Store({
  path: path.join(process.cwd(), '/scripts/deploy/', network.name + '.json'),
});

// console.log('path:', path.join(process.cwd(), '/scripts/deploy/', network.name + '.json'));

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

class Help {
  public readonly ETH_ADDRESS = '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE';

  toUnits(decimals: number) {
    return 1 + zeros.substring(0, decimals);
  }

  toFullNum(num: number) {
    if (isNaN(num)) {
      return num;
    }
    return num.toLocaleString('fullwide', { useGrouping: false });
  }

  async deploy(contractName: string, args?: any[], signer?: ethersV5.Signer) {
    const factory = await ethers.getContractFactory(contractName, signer);
    const contract = args ? await factory.deploy(...args) : await factory.deploy();
    await contract.deployed();
    return contract;
  }

  async deployERC20(symbol: string, decimal?: number) {
    return this.deploy('MockERC20', [symbol + ' token', symbol, decimal || 18]);
  }

  async getBlockTime() {
    const block = await ethers.provider.getBlock('latest');
    return block.timestamp;
  }

  async increaseBlockTime(seconds: number) {
    await ethers.provider.send('evm_increaseTime', [seconds]);
    await ethers.provider.send('evm_mine', []);
  }

  async setNextBlockTimestamp(timestamp: number) {
    await ethers.provider.send('evm_setNextBlockTimestamp', [timestamp]);
    await ethers.provider.send('evm_mine', []);
  }

  async encodeFunctionData(contractName: string, functionName: any, args?: any[], signer?: ethersV5.Signer) {
    // const factory = await ethers.getContractFactory(contractName, signer);
    // const contract = args ? await factory.deploy(...args) : await factory.deploy();
    // await contract.deployed();
    // return contract;
    const factory = await ethers.getContractFactory(contractName, signer);
    const data = factory.interface.encodeFunctionData(functionName, args);
    return data;
  }
}

export const help = new Help();
