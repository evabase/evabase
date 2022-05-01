'use strict';
// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import '@openzeppelin/hardhat-upgrades';
import { ethers } from 'hardhat';
const store = require('data-store')({
  // path: process.cwd() + "/deployInfo.json",
  path: process.cwd() + '/scripts/deploy/rinkeby.json',
});

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const ownerO = await ethers.getSigners();
  console.log(`deployer owner : ${ownerO[0].address}`);

  // EvaFlowController
  const EvaFlowController = await ethers.getContractFactory('EvaFlowController');
  const evaFlowController = await EvaFlowController.deploy(store.get('evabaseConfig'), store.get('evaSafesFactory'));
  await evaFlowController.deployed();
  // const Order = [
  //   { name: "owner", type: "addess" },
  //   { name: "assetToken", type: "addess" },
  //   { name: "amount", type: "uint256" },
  //   { name: "price", type: "uint256" },
  //   { name: "expireTime", type: "uint256" },
  //   { name: "tokenId", type: "uint256" },
  //   { name: "salt", type: "uint256" },
  // ];

  const myStructData = ethers.utils.AbiCoder.prototype.encode(
    ['address', 'address', 'uint256', 'uint256', 'uint256', 'uint256', 'uint256'],
    [ownerO[0].address, ownerO[0].address, 100, 1, 16803555107, 342905, 1899909],
  );

  // const tx = await myContract.myFunction(myStructData, {
  //   gasLimit: ethers.utils.parseUnits("1000000", "wei"),
  // });

  // const order = {
  //   owner: ownerO[0].address,
  //   assetToken: ownerO[0].address,
  //   amount: "1000",
  //   price: "1",
  //   expireTime: "1680355507",
  //   tokenId: 342905,
  //   salt: "1899909",
  // };

  // const data = ethers.utils.defaultAbiCoder.encode(["Order"], [order]);

  console.log(`data: ${myStructData}`);

  // await evaFlowController.createFlow(
  //   'ACE',
  //   1, // evabaseKeep
  //   store.get('NftLimitOrderFlow'),
  //   myStructData,
  //   200000,
  //   {
  //     value: ethers.utils.parseEther('0.01'),
  //   },
  // );

  // await evaFlowController.pauseFlow(1, myStructData);
  // await evaFlowController.startFlow(1, myStructData);
  // await evabaseConfig.setControl(evaFlowController.address);
  // await evaFlowController.addEvabaseFlowByOwner(
  //   store.get("NftLimitOrderFlow"),
  //   1, // KeepNetWork.Evabase
  //   "NFTLimitOrderFlow"
  // );

  store.set('evaFlowController', evaFlowController.address);
  console.log(`evaFlowController: ${evaFlowController.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
