//SPDX-License-Identifier: MIT
//Create by Openflow.network core team.
pragma solidity ^0.8.0;

// info stored for each order
struct Order {
    // the order owner
    address owner;
    // the amount of input token
    uint96 inputAmount;
    // the address of input token
    address inputToken;
    // the address of output token
    address outputToken;
    // unix timestamp after which the order will expire
    uint64 deadline;
    // the address which will receive the output token
    address receiptor;
    // minimum amount when splitting an order
    uint96 minInputPer;
    // lower exchange rate between inputToken and outputToken when create order
    uint160 minRate;
}

interface ILOBExchange {
    /// @notice Create order
    /// @param order The order info
    /// @return key The unique key of the order
    function createOrder(Order calldata order) external payable returns (bytes32 key);

    /// @notice Close order
    /// @param key The unique key of the order
    function closeOrder(bytes32 key) external;
}
