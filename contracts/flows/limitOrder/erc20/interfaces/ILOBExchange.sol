//SPDX-License-Identifier: MIT
//Create by Openflow.network core team.
pragma solidity ^0.8.0;

struct Order {
    address owner;
    uint96 inputAmount;
    address inputToken;
    address outputToken;
    uint64 deadline;
    address receiptor;
    uint96 minInputPer;
    uint160 minRate;
}

interface ILOBExchange {
    function createOrder(Order calldata order) external payable returns (bytes32 key);

    function closeOrder(bytes32 key) external;
}
