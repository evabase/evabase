//SPDX-License-Identifier: MIT
//Create by Openflow.network core team.
pragma solidity ^0.8.0;
import "../../../interfaces/IEvaFlowController.sol";
import "../../../interfaces/IEvaFlowProxy.sol";
import {KeepNetWork} from "../../../lib/EvabaseHelper.sol";

import "../../../lib/TransferHelper.sol";

import "./interfaces/ILOBExchange.sol";

contract LOBFlowProxy is IEvaFlowProxy {
    /**
      @notice use delegate to create LimitOrder by WalletSafes.
      @dev step:
         1. approve exchange to use asset.
         2. create order on exchange.
         3. register listen order task to Evabase
     */
    function create(
        IEvaFlowController ser,
        ILOBExchange exchange,
        KeepNetWork network,
        uint256 gasFee,
        Order memory order
    ) external payable {
        // disable call self
        require(address(this) != address(exchange), "FORBIDDEN");

        uint256 value = 0;
        if (order.inputToken == TransferHelper.ETH_ADDRESS) {
            value = msg.value - gasFee; // will be revert when overflow
            require(order.inputAmount + gasFee == msg.value, "invalid input amount");
        } else {
            require(msg.value == gasFee, "invalid value");
            //  pull token to acct's walletsafes from acct (msg.sender)
            TransferHelper.safeTransferFrom(order.inputToken, msg.sender, address(this), order.inputAmount);
            // approve Exchange can transfer amount
            TransferHelper.safeApprove(order.inputToken, address(exchange), order.inputAmount);
        }

        // create order and get order key.

        bytes32 orderId = exchange.createOrder{value: value}(order);

        // orderId+safes
        // 3. register listen order task on Evabase
        ser.registerFlow{value: gasFee}(
            "EvabaseLO",
            network,
            address(exchange),
            abi.encode(orderId) //checkdata
        );
    }

    function closeFlow(IEvaFlowController ser, uint256 flowId) external override {
        ser.closeFlow(flowId);
        (ILOBExchange exchange, bytes32 orderKey) = _getInfo(ser, flowId);
        exchange.closeOrder(orderKey);
    }

    function _getInfo(IEvaFlowController ser, uint256 flowId)
        private
        view
        returns (ILOBExchange exchange, bytes32 key)
    {
        (address flow, bytes memory checkdata) = ser.getFlowCheckInfo(flowId);
        require(flow != address(0), "empty");

        exchange = ILOBExchange(flow);
        key = abi.decode(checkdata, (bytes32));
    }
}
