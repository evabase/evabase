//SPDX-License-Identifier: MIT
//Create by Openflow.network core team.
pragma solidity ^0.8.0;
import "../venders/chainlink/KeeperCompatibleInterface.sol";
import {EvaKeepBotBase} from "../keeper/EvaKeepBotBase.sol";
import {IEvabaseConfig} from "../interfaces/IEvabaseConfig.sol";
import {IEvaFlowChecker} from "../interfaces/IEvaFlowChecker.sol";
import {IEvaFlowController} from "../interfaces/IEvaFlowController.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import {KeepNetWork} from "../lib/EvabaseHelper.sol";

contract EvaBaseServerBot is EvaKeepBotBase, KeeperCompatibleInterface, Ownable {
    event SetEBSKeepStatus(address indexed user, bool status);
    uint32 public keepBotId;
    mapping(address => bool) public keeps;

    constructor(IEvabaseConfig _config, IEvaFlowChecker _evaFlowChecker) {
        require(address(_config) != address(0), "addess is 0x");
        require(address(_evaFlowChecker) != address(0), "addess is 0x");

        config = _config;
        evaFlowChecker = _evaFlowChecker;
        keeps[msg.sender] = true;
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

        IEvaFlowController(config.control()).batchExecFlow(msg.sender, _execdata);
    }

    function setEBSKeepStatus(address keep, bool status) external onlyOwner {
        keeps[keep] = status;
        emit SetEBSKeepStatus(keep, status);
    }
}
