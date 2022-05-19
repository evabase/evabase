//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity ^0.8.0;

import "./interfaces/IEvaSubFlow.sol";
import "./interfaces/IEvaSafes.sol";
import "./interfaces/IEvaFlowController.sol";
import "./interfaces/IEvaFlowExecutor.sol";
import "./interfaces/IEvaFlow.sol";
import "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";

contract EvaFlowExecutor is IEvaFlowExecutor {
    bytes32 private constant _SUB_FLOW_INTERFACE = keccak256("getSubCalls");
    IERC1820Registry private constant _ERC1820_REGISTRY =
        IERC1820Registry(address(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24));

    address public immutable controller;

    constructor(address controller_) {
        controller = controller_;
    }

    function execute(EvaFlowMeta memory flow, bytes memory executeData) external override returns (bool needCloseFlow) {
        require(msg.sender == controller, "only for controller");

        require(flow.flowStatus == FlowStatus.Active, "task is not active");
        require(flow.maxVaildBlockNumber >= block.number, "invalid task");

        address flowImpl = _ERC1820_REGISTRY.getInterfaceImplementer(flow.lastVersionflow, _SUB_FLOW_INTERFACE);
        if (flowImpl != address(0)) {
            assert(flowImpl == flow.lastVersionflow); //safe check
            _executeSubFlows(IEvaSafes(flow.admin), IEvaSubFlow(flowImpl), executeData);
        }

        bytes memory returnBytes = IEvaSafes(flow.admin).proxy(
            flow.lastVersionflow,
            HowToCall.Call,
            abi.encodeWithSelector(IEvaFlow.execute.selector, executeData)
        );
        needCloseFlow = abi.decode(returnBytes, (bool));
    }

    function _executeSubFlows(
        IEvaSafes safes,
        IEvaSubFlow flow,
        bytes memory executeData
    ) private {
        CallArgs[] memory calls = flow.getSubCalls(executeData);
        for (uint256 i = 0; i < calls.length; i++) {
            require(calls[i].valueETH == 0, "unspport value"); // TODO: supprot call with value.
            safes.proxy(calls[i].target, HowToCall.Call, calls[i].data);
        }
    }
}
