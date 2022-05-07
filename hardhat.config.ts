/* eslint-disable */
import * as dotenv from 'dotenv';
import fs from 'fs';
import path from 'path';
import { task } from 'hardhat/config';
import '@nomiclabs/hardhat-etherscan';
import '@nomiclabs/hardhat-waffle';
import '@typechain/hardhat';
import '@openzeppelin/hardhat-upgrades';
import chai from 'chai';
import { solidity } from 'ethereum-waffle';
chai.use(solidity);

dotenv.config();

/// ENVVAR
// - CI:                output gas report to file instead of stdout
// - COVERAGE:          enable coverage report
// - ENABLE_GAS_REPORT: enable gas report
// - COMPILE_MODE:      production modes enables optimizations (default: development)
// - COMPILE_VERSION:   compiler version (default: 0.8.9)
// - COINMARKETCAP:     coinmarkercat api key for USD value in gas report

const argsTool = 'yargs/yargs';
const argv = require(argsTool)()
  .env('')
  .options({
    ci: {
      type: 'boolean',
      default: false,
    },
    coverage: {
      type: 'boolean',
      default: false,
    },
    gas: {
      alias: 'enableGasReport',
      type: 'boolean',
      default: false,
    },
    mode: {
      alias: 'compileMode',
      type: 'string',
      choices: ['production', 'development'],
      default: 'development',
    },
    compiler: {
      alias: 'compileVersion',
      type: 'string',
      default: '0.8.9',
    },
    coinmarketcap: {
      alias: 'coinmarketcapApiKey',
      type: 'string',
    },
  }).argv;

if (argv.enableGasReport) {
  require('hardhat-gas-reporter');
}

if (argv.coverage) {
  require('solidity-coverage');
}
//
const otherConfigs = path.join(__dirname, 'hardhat');
fs.stat(otherConfigs, function (_err, stats) {
  if (stats && stats.isDirectory()) {
    for (const f of fs.readdirSync(otherConfigs)) {
      require(path.join(__dirname, 'hardhat', f));
    }
  }
});

const withOptimizations = argv.enableGasReport || argv.compileMode === 'production';

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task('accounts', 'Prints the list of accounts', async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

//load keys
var accounts = [];
for (var item of Object.keys(process.env)) {
  if (item.endsWith('PRIVATE_KEY')) {
    accounts.push(process.env[item]);
  }
}

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more
/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: '0.8.4',
    settings: {
      optimizer: {
        enabled: withOptimizations,
        runs: 200,
      },
    },
  },
  paths: {
    sources: './contracts',
    tests: './test',
    cache: './cache',
    artifacts: './artifacts',
  },
  mocha: {
    timeout: 40000,
  },
  networks: {
    localhost: {
      url: 'http://127.0.0.1:8545',
      accounts: process.env.LOCAL_KEY !== undefined ? [process.env.LOCAL_KEY] : [],
    },
    hardhat: {
      blockGasLimit: 10000000,
      allowUnlimitedContractSize: !withOptimizations,
      initialBaseFeePerGas: argv.coverage ? 0 : 1000000000,
    },
    ropsten: {
      url: process.env.ROPSTEN_URL || '',
      allowUnlimitedContractSize: !withOptimizations,
      accounts: accounts,
    },
    bscTest: {
      url: process.env.BSCTEST_URL || '',
      allowUnlimitedContractSize: !withOptimizations,
      accounts: accounts,
      gas: 26000000,
    },
    rinkeby: {
      url: process.env.RINKEBY_URL || '',
      accounts: accounts,
      gas: 29999972,
      gasPrice: 8000000000,
    },
  },
  gasReporter: {
    currency: 'USD',
    outputFile: argv.ci ? 'gas-report.txt' : undefined,
    coinmarketcap: argv.coinmarketcap,
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
};
