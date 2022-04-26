//SPDX-License-Identifier: MIT
//Create by Openflow.network core team.
pragma solidity ^0.8.0;
import "../../interfaces/IEvaFlowController.sol";
import "../../interfaces/IEvaFlowProxy.sol";
import {KeepNetWork} from "../../lib/EvabaseHelper.sol";

import "../../lib/TransferHelper.sol";

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
        ILOBExchange dex,
        KeepNetWork network,
        uint256 gasFee,
        Order memory order
    ) external payable {
        if (order.inputToken != TransferHelper.ETH_ADDRESS) {
            //  pull token to here from acct (msg.sender)
            TransferHelper.safeTransferFrom(
                order.inputToken,
                msg.sender,
                address(dex),
                order.inputAmount
            );
            // approve Exchange can transfer amount
            TransferHelper.safeApprove(
                order.inputToken,
                address(dex),
                order.inputAmount
            );
        }

        // create order and get order key.
        bytes32 key = dex.createOrder(order);

        // 3. register listen order task on Evabase
        ser.registerFlow{value: msg.value}(
            "EvabaseLO",
            network,
            address(dex),
            abi.encode(key) //checkdata
        );
    }

    function pauseFlow(IEvaFlowController ser, uint256 flowId)
        external
        override
    {
        ser.pauseFlow(flowId, bytes(""));
        (ILOBExchange exchange, bytes32 orderKey) = _getInfo(ser, flowId);
        exchange.setPause(orderKey, true);
    }

    function startFlow(IEvaFlowController ser, uint256 flowId)
        external
        override
    {
        ser.startFlow(flowId, bytes(""));
        (ILOBExchange exchange, bytes32 orderKey) = _getInfo(ser, flowId);
        exchange.setPause(orderKey, true);
    }

    function destroyFlow(IEvaFlowController ser, uint256 flowId)
        external
        override
    {
        ser.startFlow(flowId, bytes(""));
        (ILOBExchange exchange, bytes32 orderKey) = _getInfo(ser, flowId);
        exchange.cancelOrder(orderKey);
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
