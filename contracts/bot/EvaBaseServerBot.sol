//SPDX-License-Identifier: MIT
//Create by Openflow.network core team.
pragma solidity ^0.8.0;
import {KeeperRegistryInterface} from "../keeper/chainlink/KeeperRegistryInterface.sol";
import {KeeperCompatibleInterface} from "../keeper/chainlink/KeeperCompatibleInterface.sol";
import {EvaKeepBotBase} from "../keeper/EvaKeepBotBase.sol";
import {IEvabaseConfig} from "../interfaces/IEvabaseConfig.sol";
import {EvaFlowChecker} from "../EvaFlowChecker.sol";
import {IEvaFlowController} from "../interfaces/IEvaFlowController.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import {KeepNetWork} from "../lib/EvabaseHelper.sol";

contract EvaBaseServerBot is EvaKeepBotBase, KeeperCompatibleInterface, Ownable {
    event SetEBSKeepStatus(address indexed user, bool status);
    uint32 public keepBotId;
    mapping(address => bool) public keeps;
    uint32 private constant _EXEC_GAS_LIMIT = 8_000_000;

    constructor(
        address _config,
        address _evaFlowChecker
    ) {
        // require(_evaFlowControler != address(0), "addess is 0x");
        require(_config != address(0), "addess is 0x");
        require(_evaFlowChecker != address(0), "addess is 0x");

        // evaFlowControler = IEvaFlowControler(_evaFlowControler);
        config = IEvabaseConfig(_config);
        evaFlowChecker = EvaFlowChecker(_evaFlowChecker);
        // execAddress = _execAddress;
        config = IEvabaseConfig(_config);
        keeps[msg.sender] = true;
        // config.addKeeper(address(this), keepNetWork);
        // keepBotId = config.keepBotSizes(keepNetWork);
    }

    function checkUpkeep(bytes calldata checkData)
        external
        pure
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        return _check(checkData);
    }

    function _check(bytes memory _checkdata) internal pure override returns (bool needExec, bytes memory execdata) {
        return (true, _checkdata);
    }

    function performUpkeep(bytes calldata performData) external override {
        _exec(performData);
    }

    function _exec(bytes memory _execdata) internal override {
        require(_execdata.length > 0, "exec data should not null");

        require(keeps[msg.sender], "not active EvaBase bot");

        IEvaFlowController(config.control()).batchExecFlow(msg.sender, _execdata, _EXEC_GAS_LIMIT);
    }

    function setEBSKeepStatus(address keep, bool status) external onlyOwner {
        keeps[keep] = status;
        emit SetEBSKeepStatus(keep, status);
    }

    function encodeTwoArr(uint256[] memory _uint, bytes[] memory _bytes) external pure returns (bytes memory) {
        return (abi.encode(_uint, _bytes));
    }

    function encodeUintAndBytes(bytes memory _bytes, uint256 _value) external pure returns (bytes memory) {
        return (abi.encode(_bytes, _value));
    }

    function encodeUints(uint256[] memory _uint) external pure returns (bytes memory) {
        return (abi.encode(_uint));
    }
}
