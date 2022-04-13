//SPDX-License-Identifier: MIT
//Create by Openflow.network core team.
pragma solidity ^0.8.0;
import {KeeperRegistryInterface} from "./keeper/chainlink/KeeperRegistryInterface.sol";
import {KeeperCompatibleInterface} from "./keeper/chainlink/KeeperCompatibleInterface.sol";
import {EvaKeepBotBase} from "./keeper/EvaKeepBotBase.sol";
import {IEvabaseConfig} from "./interfaces/IEvabaseConfig.sol";
import {EvaFlowChecker} from "./EvaFlowChecker.sol";
import {IEvaFlowControler} from "./interfaces/IEvaFlowControler.sol";
import {Utils} from "./lib/Utils.sol";
import {IEvaFlow} from "./interfaces/IEvaFlow.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EvaBaseServerBot is
    EvaKeepBotBase,
    KeeperCompatibleInterface,
    Ownable
{
    event SetEBSKeepStatus(address indexed user, bool status);
    uint32 public keepBotId;
    mapping(address => bool) public keeps;
    uint32 private constant EXEC_GAS_LIMIT = 8_000_000;

    constructor(
        address _config,
        address _evaFlowChecker,
        address _evaFlowControler
    ) {
        require(_evaFlowControler != address(0), "addess is 0x");
        require(_config != address(0), "addess is 0x");
        require(_evaFlowChecker != address(0), "addess is 0x");

        evaFlowControler = IEvaFlowControler(_evaFlowControler);
        config = IEvabaseConfig(_config);
        evaFlowChecker = EvaFlowChecker(_evaFlowChecker);
        // execAddress = _execAddress;
        config = IEvabaseConfig(_config);
        keeps[msg.sender] = true;
    }

    function checkUpkeep(bytes calldata checkData)
        external
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        return _check(checkData);
    }

    function _check(bytes memory _checkdata)
        internal
        override
        returns (bool needExec, bytes memory execdata)
    {
        return (true, _checkdata);
    }

    function performUpkeep(bytes calldata performData) external override {
        _exec(performData);
    }

    function _exec(bytes memory _execdata) internal override {
        _batchExec(_execdata);
    }

    function _batchExec(bytes memory _data) internal {
        require(_data.length > 0, "exec data should not null");

        require(keeps[tx.origin], "not active chianlink active");

        evaFlowControler.batchExecFlow(_data, EXEC_GAS_LIMIT);
    }

    function setEBSKeepStatus(address keep, bool status) external onlyOwner {
        keeps[keep] = status;
        emit SetEBSKeepStatus(keep, status);
    }

    // function encodeUints(uint256[] memory _uint)
    //     public
    //     pure
    //     returns (bytes memory)
    // {
    //     return (abi.encode(_uint));
    // }

    // function decodeUints(bytes memory data)
    //     public
    //     pure
    //     returns (uint256[] memory _uint2)
    // {
    //     _uint2 = abi.decode(data, (uint256[]));
    // }

    // function registerTask(bytes memory checkData)
    //     external
    //     onlyOwner
    //     returns (uint256 thirdId)
    // {
    //     config.addKeeper(address(this));
    //     keepBotId = config.keepBotSize() + 1;
    //     return keepBotId;
    // }
}
