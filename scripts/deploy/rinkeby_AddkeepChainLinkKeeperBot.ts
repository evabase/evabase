'use strict';
// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import '@openzeppelin/hardhat-upgrades';
import { config } from 'dotenv';
import { ethers } from 'hardhat';
// eslint-disable-next-line node/no-missing-import
import { help, KeepNetWork, store } from '../help';
async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');
  // We get the contract to deploy
  const ownerO = await help.admin()!;
  const config = await ethers.getContractAt('EvabaseConfig', store.get('evabaseConfig'), ownerO);
  const tx = await config.addKeeper(store.get('evaFlowChainLinkKeeperBot'), KeepNetWork.ChainLink, {
    gasPrice: 1e10,
  });
  tx.wait();
  // const tx1 = await config.addKeeper(store.get('evaBaseServerBot'), 1);
  // tx1.wait();
  // console.log(tx);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
