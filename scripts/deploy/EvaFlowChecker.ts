/* eslint-disable node/no-missing-import */
'use strict';
import process from 'process';
import '@openzeppelin/hardhat-upgrades';
import { ethers } from 'hardhat';
import { store, help } from '../help';
import { EvaFlowRandomChecker, LOBExchange } from '../../typechain';

async function main() {
  const admin = await help.admin();
  const checker = (await help.deploy(
    'EvaFlowRandomChecker',
    [store.get('evabaseConfig')],
    admin,
  )) as EvaFlowRandomChecker;

  help.setStore('EvaFlowRandomChecker', checker.address);

  // update
  const bot = await ethers.getContractAt('EvaFlowChainLinkKeeperBot', store.get('evaFlowChainLinkKeeperBot'));

  const tx = await bot.connect(admin).setEvaCheck(checker.address);
  console.log(`setEvaCheck tx=${tx.hash}`);
  await tx.wait();
  console.log('setEvaCheck done');
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
