//SPDX-License-Identifier: MIT
//Create by Openflow.network core team.
pragma solidity ^0.8.0;

struct Order {
    address owner;
    uint96 inputAmount;
    address inputToken;
    uint96 minRate;
    address outputToken;
    uint64 expiration;
    address receiptor;
    bool foc;
}

interface ILOBExchange {
    function createOrder(Order calldata order) external payable returns (bytes32 key);

    function setPause(bytes32 key, bool pause) external;

    function cancelOrder(bytes32 key) external;
}
