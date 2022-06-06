'use strict';

import '@openzeppelin/hardhat-upgrades';
import hre from 'hardhat';
import path from 'path';

const { Store } = require('data-store');

export const store = new Store({
  // path: process.cwd() + "/deployInfo.json",
  path: path.join(process.cwd(), '/scripts/deploy/', hre.network.name + '.json'),
});
