//SPDX-License-Identifier: MIT
//Create by Openflow.network core team.
pragma solidity ^0.8.0;

import "../../interfaces/IEvaFlow.sol";
import "./LOB.sol";
import "./interfaces/IStrategy.sol";

contract LOBExchange is LOB {
    IStrategy public strategy;

    bytes32[] private _activeOrders;

    constructor(address _safeFactory) LOB(_safeFactory) {}

    function check(bytes memory checkData)
        external
        view
        returns (bool needExecute, bytes memory executeData)
    {
        bytes32 key = abi.decode(checkData, (bytes32));

        if (!isActiveOrder(key)) {
            return (false, bytes(""));
        }

        (Order memory order, uint256 balance) = getOrderInfo(key);

        //find taker
        (uint256 input, uint256 output, bytes memory execData) = strategy
            .getRouter(
                address(order.inputToken),
                address(order.outputToken),
                balance,
                order.minRate
            );

        if (output == 0) {
            return (false, bytes(""));
        }

        return (true, abi.encode(key, strategy, input, execData));
    }

    function execute(bytes memory executeData) external {
        (bytes32 key, IStrategy stategy, uint256 input, bytes memory data) = abi
            .decode(executeData, (bytes32, IStrategy, uint256, bytes));

        executeOrder(key, stategy, input, data);
    }

    function _afterCreate(
        bytes32 key,
        uint256 amount,
        uint256 fee
    ) internal override {}

    function _afterExecute(
        bytes32 key,
        uint256 input,
        uint256 output,
        uint256 balance
    ) internal override {}

    function _afterCancel(bytes32 key, uint256 returnAmount)
        internal
        override
    {}
}
