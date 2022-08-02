'use strict';
// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import '@openzeppelin/hardhat-upgrades';
import { BigNumber } from 'ethers';
import { ethers } from 'hardhat';
// eslint-disable-next-line node/no-missing-import
import { store, help, HowToCall, KeepNetWork, Operator, CallWay } from '../help';

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const ownerO = await ethers.getSigners();
  const user = ownerO[0].address;
  console.log(`deployer owner : ${user}`);
  const headData = await head(Operator.NEq, CallWay.Const, CallWay.StaticCall);
  console.log(`headData=  ${headData}`);
  const dataA = await constData(123, 32);
  console.log(`dataA=  ${dataA}`);
  const contractAddress = '0xC272e20C2d0F8fb7B9B05B9F2Ba4407E95928CbF';

  const MockERC20 = await ethers.getContractFactory('MockERC20');
  const contractCallData = MockERC20.interface.encodeFunctionData('totalSupply', []);
  console.log(`contractCallData=  ${contractCallData}`);
  const dataB = await contractData(contractAddress, contractCallData);
  console.log(`dataB=  ${dataB}`);
  console.log(`length Head= ${ethers.utils.hexDataLength(headData)}`);
  console.log(`length A= ${ethers.utils.hexDataLength(dataA)}`);
  console.log(`length B= ${ethers.utils.hexDataLength(dataB)}`);
  const expression = ethers.utils.hexConcat([headData, dataA, dataB]);

  console.log(`expression=  ${expression}`);
  console.log(`length= ${ethers.utils.hexDataLength(expression)}`);

  const totalUSDC = BigNumber.from('1000000000000000000000000000');
  console.log(await constData(totalUSDC, 32));
}

// 拼接头部
async function head(op: number, wayA: number, wayB: number) {
  // const op = Operator.NEq;
  // const wayA = CallWay.Const;
  // const wayB = CallWay.Call;
  const head = ethers.utils.solidityPack(['uint8', 'uint8', 'uint8'], [op, wayA, wayB]);
  // console.log(head);
  return head;
}

// 拼接常数
async function constData(constValue: any, size: number) {
  // 这里显示长度不能超过 32 字节，如果超出会抛出异常
  // const b = ethers.utils.hexValue(constValue);
  const data = ethers.utils.hexZeroPad(ethers.utils.solidityPack(['bytes'], [constValue]), size);
  // console.log(data);
  return data;
}
// 拼接合约获取
async function contractData(contractAddress: any, contractCallData: any) {
  const length = await constData(ethers.utils.hexDataLength(contractCallData), 2);
  // const data1 = ethers.utils.hexZeroPad(ethers.utils.solidityPack(['bytes'], [length]), 2);
  const data = ethers.utils.hexConcat([
    ethers.utils.hexZeroPad(ethers.utils.solidityPack(['address'], [contractAddress]), 20), // 20 个字节长度的地址编码
    length, // 记录调用数据长度,占有2字节
    contractCallData, // 存储原始调用数据
  ]);
  console.log(length);
  return data;
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
