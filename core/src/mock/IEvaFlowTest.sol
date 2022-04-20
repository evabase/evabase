// SPDX-License-Identifier: GPL-2.0-or-later
// Copy from https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/TransferHelper.sol
pragma solidity ^0.8.0;
import "../interfaces/IEvaFlow.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract IEvaFlowTest is IEvaFlowExtra {
    address private _owner;

    constructor() {
        _owner = msg.sender;
    }

    function owner() public view override returns (address) {
        return _owner;
    }

    function ownerWalletSafes() external view override returns (address) {
        return msg.sender;
    }

    function check(bytes memory checkData)
        external
        view
        override
        returns (bool needExecute, bytes memory executeData)
    {
        return (true, bytes(""));
    }

    function multicall(bytes memory data) external override {
        return;
    }

    function execute(bytes memory executeData) external override {
        return;
    }

    function create(uint256 flowId, bytes memory extraData)
        external
        override
        returns (bytes memory checkData)
    {}

    function pause(uint256 flowId, bytes memory extraData) external override {}

    function start(uint256 flowId, bytes memory extraData) external override {}

    function destroy(uint256 flowId, bytes memory extraData)
        external
        override
    {}
}
