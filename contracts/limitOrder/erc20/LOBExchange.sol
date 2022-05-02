//SPDX-License-Identifier: MIT
//Create by Openflow.network core team.
pragma solidity ^0.8.0;

import "./LOB.sol";
// import "./LOBExchange.sol";
import "./LOBFlowProxy.sol";
import "./interfaces/ILOBExchange.sol";
import "./interfaces/IStrategy.sol";
import "../../interfaces/IEvaFlow.sol";

contract LOBExchange is IEvaFlow, LOBFlowProxy, LOB {
    IStrategy public strategy;

    event StrategyChanged(address newStrategy);

    constructor(IStrategy strategy_, Config memory cfg) LOB(cfg) {
        strategy = strategy_;
    }

    function multicall(address, bytes memory) external pure override {
        revert("F");
    }

    function check(bytes memory checkData) external view override returns (bool needExecute, bytes memory executeData) {
        bytes32 key = abi.decode(checkData, (bytes32));

        if (!isActiveOrder(key)) {
            return (false, bytes(""));
        }

        (Order memory order, OrderStatus memory status) = getOrderInfo(key);

        //find taker
        (uint256 input, uint256 output, bytes memory execData) = strategy.getRouter(
            address(order.inputToken),
            address(order.outputToken),
            status.balance,
            order.minRate
        );

        if (output == 0 || input < order.minInputPer) {
            return (false, bytes(""));
        }

        return (true, abi.encode(key, strategy, input, execData));
    }

    function execute(bytes memory executeData) external override {
        (bytes32 key, IStrategy s, uint256 input, bytes memory data) = abi.decode(
            executeData,
            (bytes32, IStrategy, uint256, bytes)
        );
        executeOrder(key, s, input, data);
    }

    function setStrategy(address s) external onlyOwner {
        require(s != address(0), "strategy is empty");
        strategy = IStrategy(s);

        emit StrategyChanged(s);
    }
}
