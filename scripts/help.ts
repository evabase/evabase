'use strict';
import path from 'path';
import { ethers, network } from 'hardhat';
import { ethers as ethersV5 } from 'ethers';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';

let zeros = '0';
while (zeros.length < 256) {
  zeros += zeros;
}

const { Store } = require('data-store');
const lastCreate2FactoryAddress = '0x49088917be000e083963312b50866fdf52798a8b';
export const zeroAddress = '0x0000000000000000000000000000000000000000';
export const store = new Store({
  path: path.join(process.cwd(), '/scripts/deploy/', network.name + '.json'),
});

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
  Closed,
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

export enum Operator {
  Gt,
  Lt,
  EqOrGt,
  EqOrLt,
  Eq,
  NEq,
}

export enum CallWay {
  Call,
  StaticCall,
  Const,
}

// 拼接头部
export async function head(op: number, wayA: number, wayB: number) {
  // const op = Operator.NEq;
  // const wayA = CallWay.Const;
  // const wayB = CallWay.Call;
  const head = ethers.utils.solidityPack(['uint8', 'uint8', 'uint8'], [op, wayA, wayB]);
  // console.log(head);
  return head;
}

// 拼接常数
export async function constData(constValue: any, size: number) {
  // 这里显示长度不能超过 32 字节，如果超出会抛出异常
  // console.log(constValue);
  // const b = ethers.utils.hexValue(constValue);
  // console.log(b);
  const data = ethers.utils.hexZeroPad(ethers.utils.solidityPack(['bytes'], [constValue]), size);
  // console.log(data);
  return data;
}
// 拼接合约获取
export async function contractData(contractAddress: any, contractCallData: any) {
  const length = await constData(ethers.utils.hexDataLength(contractCallData), 2);
  // const data1 = ethers.utils.hexZeroPad(ethers.utils.solidityPack(['bytes'], [length]), 2);
  const data = ethers.utils.hexConcat([
    ethers.utils.hexZeroPad(ethers.utils.solidityPack(['address'], [contractAddress]), 20), // 20 个字节长度的地址编码
    length, // 记录调用数据长度,占有2字节
    contractCallData, // 存储原始调用数据
  ]);
  return data;
}

class Help {
  public readonly adminMap: Map<string, string>;
  public readonly ETH_ADDRESS = '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE';
  private _admin?: SignerWithAddress;
  private _me?: SignerWithAddress;

  constructor() {
    this.adminMap = new Map<string, string>();
    this.adminMap.set('rinkeby', '0xE860aE9379B1902DC08F67F50de7b9CC066AF0FF');
    this.adminMap.set('localhost', '0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266');
    this.adminMap.set('mainnet', '0x0ec384A45064146AC4B3559FD67e8c7E9d9E2846');
  }

  toUnits(decimals: number) {
    return 1 + zeros.substring(0, decimals);
  }

  toFullNum(num: number) {
    if (isNaN(num)) {
      return num;
    }
    return num.toLocaleString('fullwide', { useGrouping: false });
  }

  async admin() {
    if (this._admin === undefined) {
      return ethers.getSigners().then((list) => {
        const v = this.adminMap.get(network.name);
        this._admin = list.find((r) => r.address === v);
        this._me = list.find((r) => r.address !== v);
        return this._admin;
      });
    } else {
      return this._admin;
    }
  }

  async me() {
    if (this._me === undefined) {
      return ethers.getSigners().then((list) => {
        const v = this.adminMap.get(network.name);
        this._admin = list.find((r) => r.address === v);
        this._me = list.find((r) => r.address !== v);
        return this._me;
      });
    } else {
      return this._me;
    }
  }

  setStore(key: string, value: any) {
    console.log(`update ${key} config: ${store.get(key)} --> ${value}`);
    store.set(key, value);
  }

  async deploy(contractName: string, args?: any[], signer?: ethersV5.Signer) {
    if (signer === undefined) {
      signer = await this.admin();
    }
    const factory = await ethers.getContractFactory(contractName, signer);
    // const op = { gasPrice: 30 * 1e9 };
    const contract = args ? await factory.deploy(...args) : await factory.deploy();

    if (network.name === 'rinkeby') {
      console.log(`deploy ${contractName} ${contract.deployTransaction.hash}`);
    }
    await contract.deployed();
    return contract;
  }

  async deployByFactory(contractName: string, args?: any[], calldata?: any, signer?: ethersV5.Signer) {
    if (signer === undefined) {
      signer = await this.admin();
    }
    const lastCreate2FactoryContract = await ethers.getContractAt(
      lastCreate2FactoryAbi,
      lastCreate2FactoryAddress,
      signer,
    );

    console.log(await signer?.getAddress());

    const salt = ethers.utils.hexZeroPad('0x3a0807916caa0103f2239361', 32);
    const factory = await ethers.getContractFactory(contractName, signer);
    const initCode = args
      ? (await factory.getDeployTransaction(...args)).data
      : (await factory.getDeployTransaction()).data;

    if (calldata === undefined) {
      calldata = '0x';
    }

    const expectAddress = await lastCreate2FactoryContract.callStatic.findCreate2Address(salt, initCode);

    if (expectAddress !== zeroAddress) {
      const contract = await lastCreate2FactoryContract.safeCreate2(salt, initCode, calldata);
      console.log(`deploy Hash = ${await contract.hash}`);
    }
    return expectAddress;
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

const lastCreate2FactoryAbi = [
  {
    anonymous: false,
    inputs: [
      { indexed: false, internalType: 'address', name: 'addr', type: 'address' },
      { indexed: false, internalType: 'bytes32', name: 'salt', type: 'bytes32' },
    ],
    name: 'Deployed',
    type: 'event',
  },
  {
    constant: true,
    inputs: [{ internalType: 'address', name: '', type: 'address' }],
    name: 'deployed',
    outputs: [{ internalType: 'bool', name: '', type: 'bool' }],
    payable: false,
    stateMutability: 'view',
    type: 'function',
  },
  {
    constant: true,
    inputs: [
      { internalType: 'bytes32', name: 'salt', type: 'bytes32' },
      { internalType: 'bytes', name: 'initCode', type: 'bytes' },
    ],
    name: 'findCreate2Address',
    outputs: [{ internalType: 'address', name: 'deploymentAddress', type: 'address' }],
    payable: false,
    stateMutability: 'view',
    type: 'function',
  },
  {
    constant: false,
    inputs: [
      { internalType: 'bytes32', name: 'salt', type: 'bytes32' },
      { internalType: 'bytes', name: 'initializationCode', type: 'bytes' },
      { internalType: 'bytes', name: 'callData', type: 'bytes' },
    ],
    name: 'safeCreate2',
    outputs: [{ internalType: 'address', name: 'deploymentAddress', type: 'address' }],
    payable: false,
    stateMutability: 'nonpayable',
    type: 'function',
  },
];
