'use strict';
// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import '@openzeppelin/hardhat-upgrades';
import { ethers } from 'hardhat';
// eslint-disable-next-line node/no-missing-import
import { store, help, zeroAddress } from '../help';

async function main() {
  // 10 ops
  const evabaseConfigAddr = store.get('evabaseConfig');
  const evaSafesFactoryAddr = store.get('evaSafesFactory');
  // let opsFlowProxyAddr = store.get('opsFlowProxy');
  // if (typeof opsFlowProxyAddr === 'undefined') {
  const OpsFlowProxy = await ethers.getContractFactory('OpsFlowProxy');
  //   const opsFlowProxy = await OpsFlowProxy.deploy(evabaseConfigAddr, evaSafesFactoryAddr);
  //   console.log(`opsFlowProxy: ${opsFlowProxy.address}`);
  //   store.set('opsFlowProxy', opsFlowProxy.address);
  //   opsFlowProxyAddr = opsFlowProxy.address;
  // }
  const signer = await help.admin();
  const admin = await signer?.getAddress();
  console.log(`deployer owner : ${admin}`);
  const calldata = OpsFlowProxy.interface.encodeFunctionData('transferOwnership', [admin]);
  console.log(`deployer calldata : ${calldata}`);
  const expectAddress = await help.deployByFactory('OpsFlowProxy', [evabaseConfigAddr, evaSafesFactoryAddr], calldata);
  console.log(`deployer expectAddress : ${expectAddress}`);
  if (expectAddress !== zeroAddress) {
    console.log(`opsFlowProxy: ${expectAddress}`);
    store.set('opsFlowProxy', expectAddress);
  } else {
    console.log('opsFlowProxy existed !');
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
