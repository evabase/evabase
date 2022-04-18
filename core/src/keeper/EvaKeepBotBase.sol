//SPDX-License-Identifier: MIT
//Create by Openflow.network core team.
pragma solidity ^0.8.0;
import {IEvabaseConfig} from "../interfaces/IEvabaseConfig.sol";
import {EvaFlowChecker} from "../EvaFlowChecker.sol";

abstract contract EvaKeepBotBase {
    IEvabaseConfig public config;
    EvaFlowChecker public evaFlowChecker;

    function _check(bytes memory checkdata)
        internal
        virtual
        returns (bool needExec, bytes memory execdata);

    function _exec(bytes memory execdata) internal virtual;
}
