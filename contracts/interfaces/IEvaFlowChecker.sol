//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity ^0.8.0;
import {KeepNetWork} from "../lib/EvabaseHelper.sol";

interface IEvaFlowChecker {
    function check(
        uint256 keepbotId,
        uint256 lastMoveTime,
        KeepNetWork keepNetWork
    ) external  returns (bool needExec, bytes memory execData);
}
