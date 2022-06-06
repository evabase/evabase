//SPDX-License-Identifier: MIT
//Create by evabase.network core team.
pragma solidity ^0.8.0;

import "./IEvaFlowController.sol";

interface IEvaFlowProxy {
    function closeFlow(IEvaFlowController ctr, uint256 flowId) external;
}
