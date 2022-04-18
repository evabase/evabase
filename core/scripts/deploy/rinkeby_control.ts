// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
import "@openzeppelin/hardhat-upgrades";
import { ethers } from "hardhat";
const store = require("data-store")({
  // path: process.cwd() + "/deployInfo.json",
  path: process.cwd() + "/scripts/deploy/rinkeby.json",
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

  // EvaFlowControler
  const EvaFlowControler = await ethers.getContractFactory("EvaFlowControler");
  const evaFlowControler = await EvaFlowControler.deploy(
    store.get("evabaseConfig"),
    store.get("evaSafesFactory")
  );
  await evaFlowControler.deployed();
  // await evabaseConfig.setControl(evaFlowControler.address);
  await evaFlowControler.addEvabaseFlowByOwner(
    store.get("NftLimitOrderFlow"),
    1, // KeepNetWork.Evabase
    "NFTLimitOrderFlow"
  );

  store.set("evaFlowControler", evaFlowControler.address);
  console.log(`evaFlowControler: ${evaFlowControler.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
