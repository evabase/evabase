//SPDX-License-Identifier: MIT
//Create by Openflow.network core team.
pragma solidity ^0.8.0;
import {IEvabaseConfig} from "../interfaces/IEvabaseConfig.sol";
import {IEvaFlowChecker} from "../interfaces/IEvaFlowChecker.sol";

abstract contract EvaKeepBotBase {
    IEvabaseConfig public config;
    IEvaFlowChecker public evaFlowChecker;

    function _check(bytes memory checkdata) internal virtual returns (bool needExec, bytes memory execdata);

    function _exec(bytes memory execdata) internal virtual;
}
