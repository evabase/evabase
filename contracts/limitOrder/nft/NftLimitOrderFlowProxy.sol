// SPDX-License-Identifier: GPL-2.0-or-later
// Copy from https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/TransferHelper.sol
pragma solidity ^0.8.0;
import "../../interfaces/IEvaFlowProxy.sol";
// import "../../interfaces/INftLimitOrder.sol";
import "./NftLimitOrderFlow.sol";

contract NftLimitOrderFlowProxy is IEvaFlowProxy, NftLimitOrderFlow {
    constructor(
        address _config,
        address _evaSafesFactory,
        string memory name,
        string memory version
    ) NftLimitOrderFlow(_config, _evaSafesFactory, name, version) {}

    function create(
        IEvaFlowController ser,
        INftLimitOrder nftLimitOrder,
        KeepNetWork network,
        uint256 gasFee,
        Order memory order
    ) external payable {
        uint256 _value = 0;

        _value = msg.value - gasFee;
        require(order.amount * order.price <= _value, "order value + gasFee must be greater than msg.value");

        uint256 flowSize = ser.getFlowMetaSize();
        bytes32 orderId = nftLimitOrder.createOrder{value: _value}(order, flowSize);
        uint256 afterFlowId = ser.registerFlow{value: gasFee}(
            "NftLimitOrder",
            network,
            address(nftLimitOrder),
            abi.encode(orderId)
        );
        require(flowSize == afterFlowId, "flowId must be equal");

        // emit OrderCreated(msg.sender, flowId, orderId, order);
    }

    function pauseFlow(IEvaFlowController ser, uint256 flowId) external override {
        ser.pauseFlow(flowId);
        (INftLimitOrder nftLimitOrder, bytes32 orderId) = _getInfo(ser, flowId);
        nftLimitOrder.changeStatus(orderId, true, flowId);

        // emit OrderPause(msg.sender, flowId, orderId);
    }

    function startFlow(IEvaFlowController ser, uint256 flowId) external override {
        ser.startFlow(flowId);
        (INftLimitOrder nftLimitOrder, bytes32 orderId) = _getInfo(ser, flowId);
        nftLimitOrder.changeStatus(orderId, false, flowId);

        // emit OrderStart(msg.sender, flowId, orderId);
    }

    function destroyFlow(IEvaFlowController ser, uint256 flowId) external override {
        ser.destroyFlow(flowId);
        (INftLimitOrder exchange, bytes32 orderId) = _getInfo(ser, flowId);
        exchange.cancelOrder(orderId, flowId);

        // emit OrderCancel(msg.sender, flowId, orderId);
    }

    function _getInfo(IEvaFlowController ser, uint256 flowId)
        internal
        view
        returns (INftLimitOrder nftLimitOrder, bytes32 orderId)
    {
        (address flow, bytes memory checkdata) = ser.getFlowCheckInfo(flowId);
        require(flow != address(0), "empty");

        nftLimitOrder = INftLimitOrder(flow);
        orderId = abi.decode(checkdata, (bytes32));
    }
}
