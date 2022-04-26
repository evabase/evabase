// SPDX-License-Identifier: GPL-2.0-or-later
// Copy from https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/TransferHelper.sol
pragma solidity ^0.8.0;
import "../interfaces/IEvaFlow.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract IEvaFlowTest is IEvaFlow {
    address private _owner;

    constructor() {
        _owner = msg.sender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function check(bytes memory checkData)
        external
        view
        override
        returns (bool needExecute, bytes memory executeData)
    {
        return (true, bytes(""));
    }

    function multicall(address, bytes memory) external override {
        revert("F");
    }

    function execute(bytes memory executeData) external override {
        return;
    }
}
