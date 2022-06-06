'use strict';
// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const bre = require('@nomiclabs/buidler');
const store = require('data-store')({
  // path: process.cwd() + "/deployInfo.json",
  path: process.cwd() + '/scripts/deploy/rinkeby.json',
});
async function main() {
  await bre.run('verify', {
    address: store.get('evabaseConfig'),
  });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
