//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity ^0.8.0;

import {EvaFlowMeta} from "./IEvaFlowController.sol";

interface IEvaFlowExecutor {
    function execute(EvaFlowMeta memory flow, bytes memory executeData) external returns (bool needCloseFlow);
}
