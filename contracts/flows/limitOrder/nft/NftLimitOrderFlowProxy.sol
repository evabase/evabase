// SPDX-License-Identifier: GPL-2.0-or-later
// Copy from https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/TransferHelper.sol
pragma solidity ^0.8.0;
import "../../../interfaces/IEvaFlowProxy.sol";
import "./NftLimitOrderFlow.sol";

contract NftLimitOrderFlowProxy is IEvaFlowProxy, NftLimitOrderFlow {
    constructor(
        address _config,
        address _evaSafesFactory,
        string memory name,
        string memory version
    ) NftLimitOrderFlow(_config, _evaSafesFactory, name, version) {} //solhint-disable

    function create(
        IEvaFlowController ser,
        INftLimitOrder nftLimitOrder,
        KeepNetWork network,
        uint256 gasFee,
        string memory name,
        Order memory order
    ) external payable {
        require(bytes(name).length > 0, "invalid name");
        uint256 _value = 0;

        _value = msg.value - gasFee;
        require(order.amount * order.price <= _value, "order value + gasFee must be greater than msg.value");

        uint256 flowSize = ser.getFlowMetaSize();
        bytes32 orderId = nftLimitOrder.createOrder{value: _value}(order, flowSize);
        uint256 afterFlowId = ser.registerFlow{value: gasFee}(
            name,
            network,
            address(nftLimitOrder),
            abi.encode(orderId)
        );
        require(flowSize == afterFlowId, "flowId must be equal");
    }

    function closeFlow(IEvaFlowController ser, uint256 flowId) external override {
        ser.closeFlow(flowId);
        (INftLimitOrder exchange, bytes32 orderId) = _getInfo(ser, flowId);
        exchange.cancelOrder(orderId);
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
