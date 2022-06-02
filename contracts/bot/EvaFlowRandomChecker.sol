//SPDX-License-Identifier: MIT
//Create by Openflow.network core team.
pragma solidity ^0.8.0;
import {IEvabaseConfig} from "../interfaces/IEvabaseConfig.sol";
import {IEvaFlow} from "../interfaces/IEvaFlow.sol";
import {IEvaFlowController, EvaFlowMeta} from "../interfaces/IEvaFlowController.sol";
import "../lib/MathConv.sol";
import {KeepNetWork} from "../lib/EvabaseHelper.sol";
import {IEvaFlowChecker} from "../interfaces/IEvaFlowChecker.sol";

contract EvaFlowRandomChecker is IEvaFlowChecker {
    IEvabaseConfig public config;

    uint32 private constant _GAS_SAVE = 60_000;
    uint256 private constant _TIME_SOLT = 12 seconds;

    constructor(address _config) {
        require(_config != address(0), "addess is 0x");
        config = IEvabaseConfig(_config);
    }

    struct Args {
        uint256 flowCount;
        uint256 startIndex;
        uint256 keeperCount;
        uint256 keepbotId;
        uint256 maxCheck;
        IEvaFlowController controller;
        KeepNetWork network;
    }

    function check(
        uint256 keepbotId,
        uint256 lastMoveTime,
        KeepNetWork keepNetWork
    ) external override returns (bool needExec, bytes memory execData) {
        // solhint-disable avoid-tx-origin
        require(tx.origin == address(0), "only for off-chain");
        Args memory args;
        args.controller = IEvaFlowController(config.control());
        args.flowCount = args.controller.getAllVaildFlowSize(keepNetWork);

        if (args.flowCount > 0) {
            args.keepbotId = keepbotId;
            args.network = keepNetWork;
            args.maxCheck = config.batchFlowNum();
            args.keeperCount = config.keepBotSizes(keepNetWork);
            require(args.keeperCount > 0, "keeper is zero");
            require(args.maxCheck > 0, "max check is zero");
            args.startIndex = _selectBeginIndex(args.flowCount, lastMoveTime);

            (uint256[] memory flows, bytes[] memory datas) = _checkFlows(args);

            if (flows.length > 0) {
                needExec = true;
                execData = abi.encode(flows, datas);
            }
        }
    }

    function _selectBeginIndex(uint256 count, uint256 lastMoveTime) internal view returns (uint256) {
        // solhint-disable
        if (block.timestamp - lastMoveTime >= _TIME_SOLT) {
            return uint256(keccak256(abi.encodePacked(block.timestamp))) % count;
        } else {
            return uint256(keccak256(abi.encodePacked(lastMoveTime))) % count;
        }
    }

    function _checkFlows(Args memory args) internal returns (uint256[] memory flows, bytes[] memory datas) {
        uint256 mod = (args.flowCount % args.keeperCount);
        uint256 max = args.flowCount / args.keeperCount;
        max += mod > 0 && args.keepbotId <= mod ? 1 : 0;
        if (max > args.maxCheck) {
            max = args.maxCheck;
        }
        uint256[] memory flowsAll = new uint256[](max);
        bytes[] memory datasAll = new bytes[](max);

        uint256 needExecCount;
        uint256 keepIndex = args.keepbotId - 1;
        for (uint256 i = keepIndex; i < max * args.keeperCount; i += args.keeperCount) {
            uint256 nextIndex = i % args.flowCount;
            uint256 flowId = args.controller.getIndexVaildFlow(nextIndex, args.network);
            EvaFlowMeta memory meta = args.controller.getFlowMetas(flowId);
            try IEvaFlow(meta.lastVersionflow).check(meta.checkData) returns (bool needExec, bytes memory executeData) {
                if (needExec) {
                    (bool success, ) = address(args.controller).call{value: 0}(
                        abi.encodeWithSelector(IEvaFlowController.execFlow.selector, address(this), flowId, executeData)
                    );
                    if (success) {
                        flowsAll[needExecCount] = flowId;
                        datasAll[needExecCount] = executeData;
                        needExecCount++;
                    }
                }
                // solhint-disable
            } catch {} //ignore error

            if (gasleft() <= _GAS_SAVE) {
                break;
            }
        }

        // remove empty item
        flows = new uint256[](needExecCount);
        datas = new bytes[](needExecCount);
        for (uint256 i = 0; i < needExecCount; i++) {
            flows[i] = flowsAll[i];
            datas[i] = datasAll[i];
        }
    }
}
