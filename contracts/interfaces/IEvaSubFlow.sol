//SPDX-License-Identifier: MIT
//Create by evabase.network core team.
pragma solidity ^0.8.0;

import "./IEvaFlow.sol";
struct CallArgs {
    address target;
    uint120 valueETH;
    bytes data;
}

interface IEvaSubFlow is IEvaFlow {
    function getSubCalls(bytes memory executeData) external view returns (CallArgs[] memory subs);
}
