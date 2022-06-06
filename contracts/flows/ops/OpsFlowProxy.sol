// SPDX-License-Identifier: GPL-2.0-or-later
// Create by Openflow.network core team.
pragma solidity ^0.8.0;
import "../../interfaces/IEvaFlowProxy.sol";
import "./OpsFlow.sol";

contract OpsFlowProxy is IEvaFlowProxy, OpsFlow {
    constructor(address _config, address _evaSafesFactory) OpsFlow(_config, _evaSafesFactory) {} //solhint-disable

    function create(
        IEvaFlowController ser,
        IOpsFlow opsFlow,
        KeepNetWork network,
        uint256 gasFee,
        string memory name,
        Task memory task
    ) external payable {
        require(bytes(name).length > 0, "invalid name");
        require(gasFee == msg.value, "invalid gasFee");
        uint256 flowSize = ser.getFlowMetaSize();
        bytes memory taskId = opsFlow.createTask(task, flowSize);
        uint256 afterFlowId = ser.registerFlow{value: gasFee}(name, network, address(opsFlow), taskId);
        require(flowSize == afterFlowId, "flowId must be equal");
    }

    function closeFlow(IEvaFlowController ser, uint256 flowId) external override {
        ser.closeFlow(flowId);
        IOpsFlow exchange = _getOpsFlow(ser, flowId);
        exchange.cancelTask(flowId);
    }

    function _getOpsFlow(IEvaFlowController ser, uint256 flowId) internal view returns (IOpsFlow opsFlow) {
        (address flow, ) = ser.getFlowCheckInfo(flowId);
        require(flow != address(0), "empty");
        opsFlow = IOpsFlow(flow);
    }
}
