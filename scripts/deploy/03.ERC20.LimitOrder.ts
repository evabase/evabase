/* eslint-disable node/no-missing-import */
'use strict';
import process from 'process';
import '@openzeppelin/hardhat-upgrades';
import { ethers } from 'hardhat';
import { store, help } from '../help';
import { LOBExchange } from '../../typechain';

async function main() {
  let uniswapV2StrategyAddr = store.get('UniswapV2Strategy');

  if (typeof uniswapV2StrategyAddr === 'undefined') {
    console.log('begin deploy UniswapV2Strategy contract....');

    const router = store.get('others.UniswapV2Router02');
    const swapFee = store.get('others.UniswapFee');

    console.log(`
    UniswapV2Router02: ${router}
    swapFee:${swapFee}`);

    const c = await help.deploy('UniswapV2Strategy', [router, (1 - swapFee) * 1000]);

    console.log(`\tdeploy UniswapV2Router02 success: ${c.address}`);
    uniswapV2StrategyAddr = c.address;
    store.set('UniswapV2Strategy', uniswapV2StrategyAddr);
  } else {
    console.log('skip deploy UniswapV2Strategy when exist');
  }

  let exchangeAddr = store.get('LOBExchange');
  if (typeof exchangeAddr === 'undefined') {
    console.log('begin deploy LOBExchange contract');

    const zeroConfig = [false, 0, ethers.constants.AddressZero];

    const exchange = (await help.deploy('LOBExchange', [uniswapV2StrategyAddr, zeroConfig])) as LOBExchange;
    exchangeAddr = exchange.address;
    store.set('LOBExchange', exchangeAddr);
    console.log(`\tdeploy LOBExchange success:${exchangeAddr}`);
  } else {
    console.log('skip deploy LOBExchange when exist');
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
