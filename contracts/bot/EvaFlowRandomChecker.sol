//SPDX-License-Identifier: MIT
//Create by Openflow.network core team.
pragma solidity ^0.8.0;
import {IEvabaseConfig} from "../interfaces/IEvabaseConfig.sol";
import {IEvaFlow} from "../interfaces/IEvaFlow.sol";
import {IEvaFlowController, EvaFlowMeta} from "../interfaces/IEvaFlowController.sol";
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

    /**
       寻找可执行的Flow，
       随机选择一个起始位置，然后开始依次检查Flow，直到 Gas 用尽。
     */
    function _checkFlows(Args memory args) internal returns (uint256[] memory flows, bytes[] memory datas) {
        uint256[] memory flowsAll = new uint256[](args.maxCheck);
        bytes[] memory datasAll = new bytes[](args.maxCheck);

        uint256 needExecCount;
        uint256 next = args.startIndex + (args.keepbotId - 1);
        uint256 firstIndex = next % args.flowCount;
        bool notFirst;
        // 跳表查询，直到找满或Gas耗尽
        for (; needExecCount < args.maxCheck; next += args.keeperCount) {
            uint256 nextIndex = next % args.flowCount;
            // 最多只需转一圈，不重复检查
            if (notFirst && nextIndex == firstIndex) {
                break;
            }
            notFirst = true;
            uint256 flowId = args.controller.getIndexVaildFlow(nextIndex, args.network);

            EvaFlowMeta memory meta = args.controller.getFlowMetas(flowId);
            try IEvaFlow(meta.lastVersionflow).check(meta.checkData) returns (bool needExec, bytes memory executeData) {
                if (needExec) {
                    // 此处属模拟执行
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
