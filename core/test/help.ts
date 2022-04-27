import { ethers } from "hardhat";
import { ethers as ethersV5 } from "ethers";

class Help {
  public readonly ETH_ADDRESS = "0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE";

  async deploy(contractName: string, args?: any[], signer?: ethersV5.Signer) {
    const factory = await ethers.getContractFactory(contractName, signer);
    const contract = args
      ? await factory.deploy(...args)
      : await factory.deploy();
    await contract.deployed();
    return contract;
  }

  async deployERC20(symbol: string, decimal?: number) {
    return this.deploy("MockERC20", [symbol + " token", symbol, decimal || 18]);
  }

  async getBlockTime() {
    const block = await ethers.provider.getBlock("latest");
    return block.timestamp;
  }

  async increaseBlockTime(seconds: number) {
    await ethers.provider.send("evm_increaseTime", [seconds]);
    await ethers.provider.send("evm_mine", []);
  }

  async setNextBlockTimestamp(timestamp: number) {
    await ethers.provider.send("evm_setNextBlockTimestamp", [timestamp]);
    await ethers.provider.send("evm_mine", []);
  }
}

export const help = new Help();
