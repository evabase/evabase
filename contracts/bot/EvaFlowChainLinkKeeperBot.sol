//SPDX-License-Identifier: MIT
//Create by Openflow.network core team.
pragma solidity ^0.8.0;
import {KeeperRegistryInterface} from "../keeper/chainlink/KeeperRegistryInterface.sol";
import {KeeperCompatibleInterface} from "../keeper/chainlink/KeeperCompatibleInterface.sol";
import {EvaKeepBotBase} from "../keeper/EvaKeepBotBase.sol";
import {IEvabaseConfig} from "../interfaces/IEvabaseConfig.sol";
import {IEvaFlowChecker} from "../interfaces/IEvaFlowChecker.sol";
import {IEvaFlowController} from "../interfaces/IEvaFlowController.sol";
import {IEvaFlow} from "../interfaces/IEvaFlow.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import {UpkeepRegistrationRequestsInterface} from "../keeper/chainlink/UpkeepRegistrationRequestsInterface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {KeepNetWork} from "../lib/EvabaseHelper.sol";

contract EvaFlowChainLinkKeeperBot is EvaKeepBotBase, KeeperCompatibleInterface, Ownable {
    uint32 private constant _CHECK_GAS_LIMIT = 2_000_000;
    uint32 private constant _EXEC_GAS_LIMIT = 2_000_000;
    uint256 private constant _TIME_SOLT = 12 seconds;
    uint256 public lastMoveTime;

    KeeperRegistryInterface private immutable _keeperRegistry;

    event SetEvaCheck(address indexed evaCheck);

    constructor(
        address config_,
        address evaFlowChecker_,
        address keeperRegistry_
    ) {
        // require(_evaFlowControler != address(0), "addess is 0x");
        require(config_ != address(0), "addess is 0x");
        require(evaFlowChecker_ != address(0), "addess is 0x");
        require(keeperRegistry_ != address(0), "addess is 0x");

        config = IEvabaseConfig(config_);
        evaFlowChecker = IEvaFlowChecker(evaFlowChecker_);
        _keeperRegistry = KeeperRegistryInterface(keeperRegistry_);
        lastMoveTime = block.timestamp; // solhint-disable
    }

    function checkUpkeep(bytes calldata checkData)
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        (upkeepNeeded, performData) = _check(checkData);
    }

    function performUpkeep(bytes calldata performData) external override {
        _exec(performData);
    }

    function _check(bytes memory _checkdata) internal view override returns (bool needExec, bytes memory execdata) {
        uint32 keepBotId = abi.decode(_checkdata, (uint32));
        (needExec, execdata) = evaFlowChecker.check(keepBotId, lastMoveTime, KeepNetWork.ChainLink);
    }

    function _exec(bytes memory execdata) internal override {
        require(msg.sender == address(_keeperRegistry), "only for keeperRegistry");
        lastMoveTime = block.timestamp; // solhint-disable

        address keeper = tx.origin; // solhint-disable
        //off-chain try execute
        if (keeper == address(0)) {
            keeper = msg.sender;
        }
        IEvaFlowController(config.control()).batchExecFlow(keeper, execdata, _EXEC_GAS_LIMIT);
    }

    function setEvaCheck(IEvaFlowChecker evaFlowChecker_) external onlyOwner {
        require(address(evaFlowChecker_) != address(0), "addess is 0x");
        evaFlowChecker = evaFlowChecker_;
        emit SetEvaCheck(address(evaFlowChecker_));
    }
}
