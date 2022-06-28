'use strict';
// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import '@openzeppelin/hardhat-upgrades';
import { ethers } from 'hardhat';
// eslint-disable-next-line node/no-missing-import
import { store } from '../help';

async function main() {
  // 10 ops
  const ownerO = await ethers.getSigners();
  console.log(`deployer owner : ${ownerO[0].address}`);

  const EvaBaseRead = await ethers.getContractFactory('EvaBaseRead');
  const evaBaseRead = await EvaBaseRead.deploy(
    store.get('others.UniswapV2Factory'),
    store.get('others.USDT'),
    store.get('others.USDC'),
    store.get('others.WETH'),
  );

  console.log('EvaBaseRead deployed to:', evaBaseRead.address);
  store.set('EvaBaseRead', evaBaseRead.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
