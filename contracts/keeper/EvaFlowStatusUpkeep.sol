//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity ^0.8.0;

import {KeeperCompatibleInterface} from "../keeper/chainlink/KeeperCompatibleInterface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import {IEvaFlowController, KeepNetWork} from "../interfaces/IEvaFlowController.sol";
import {IEvaFlow} from "../interfaces/IEvaFlow.sol";

contract EvaFlowStatusUpkeep is KeeperCompatibleInterface, Ownable {
    event PerformFailed(uint256 flowId, string err);

    uint64 public lastPerformTime;
    uint64 public perfromInterval;
    IEvaFlowController public controller;
    uint256[] private _flowIdTemp; //just for off-chain.

    constructor(IEvaFlowController controller_, uint64 interval_) {
        controller = controller_;
        perfromInterval = interval_;
    }

    function setInterval(uint64 interval) external onlyOwner {
        perfromInterval = interval;
    }

    function checkUpkeep(bytes calldata checkData)
        external
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        require(tx.origin == address(0), "only for off-chain"); // solhint-disable

        upkeepNeeded = lastPerformTime + perfromInterval < block.timestamp;
        if (!upkeepNeeded) {
            return (false, bytes(""));
        }
        (KeepNetWork network, uint32 maxChecks) = abi.decode(checkData, (KeepNetWork, uint32));

        IEvaFlowController _controller = controller;
        uint256 flowCount = _controller.getAllVaildFlowSize(network);
        if (flowCount == 0) {
            return (false, bytes(""));
        }

        uint256 begin;
        if (flowCount > maxChecks) {
            // select a random number as first flow index.
            begin = uint256(keccak256(abi.encode(block.timestamp))) % flowCount; // solhint-disable
        }
        for (uint256 i = begin; i < maxChecks && i < flowCount; i++) {
            uint256 flowId = _controller.getIndexVaildFlow(i, network);

            (address flow, bytes memory flowCheckData) = _controller.getFlowCheckInfo(flowId);

            // can be check next flow when flow has reveted.
            // solhint-disable
            (bool success, bytes memory returnBytes) = flow.call(
                abi.encodeWithSelector(IEvaFlow.needClose.selector, flowCheckData)
            );
            if (success) {
                bool can = abi.decode(returnBytes, (bool));
                if (can) {
                    // push functon only for storage array.
                    _flowIdTemp.push(flowId);
                }
            }
        }

        upkeepNeeded = _flowIdTemp.length > 0;
        performData = abi.encode(_flowIdTemp);
    }

    /**
     * @notice destory flow when flow can never be executed.
     * @dev note: can be called by anyone
     */
    function performUpkeep(bytes calldata performData) external override {
        require(lastPerformTime + perfromInterval < block.timestamp, "in dormancy");

        uint256[] memory flowIds = abi.decode(performData, (uint256[]));
        IEvaFlowController _controller = controller;
        uint256 succCount;
        for (uint256 i = 0; i < flowIds.length; i++) {
            uint256 before = gasleft();
            uint256 flowId = flowIds[i];
            (address flow, bytes memory flowCheckData) = _controller.getFlowCheckInfo(flowId);

            try IEvaFlow(flow).close(flowCheckData) {
                _controller.closeFlowWithGas(flowId, before);
                succCount++;
            } catch Error(string memory err) {
                emit PerformFailed(flowId, err);
            }
        }
        // Eusure that invalid tx are not always minted.
        require(succCount > 0, "all failed");
    }
}
