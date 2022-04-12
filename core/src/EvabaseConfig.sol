//SPDX-License-Identifier: MIT
//Create by Openflow.network core team.
pragma solidity ^0.8.0;

import {IEvabaseConfig} from "./interfaces/IEvabaseConfig.sol";
import {EvabaseHelper} from "./lib/EvabaseHelper.sol";
import {IEvaSafesFactory} from "./interfaces/IEvaSafesFactory.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract EvabaseConfig is IEvabaseConfig, Ownable {
    mapping(address => bool) public keepBotExists;
    uint32 public override keepBotSize;
    // using EvabaseHelper for EvabaseHelper.AddressSet;
    // EvabaseHelper.AddressSet keepBots;

    address public override control;

    uint32 public override batchFlowNum = 5;

    function setBatchFlowNum(uint32 num) external override {
        batchFlowNum = num;
        emit SetBatchFlowNum(msg.sender, num);
    }

    function addKeeper(address _keeper) external override {
        require(tx.origin == owner(), "only owner can add keeper");
        require(!keepBotExists[_keeper], "keeper exist");
        keepBotExists[_keeper] == true;
        // require(keepBots.contains(_keeper), "keeper exist");
        // keepBots.add(_keeper);
        keepBotSize++;
        emit AddKeeper(msg.sender, _keeper);
    }

    function removeBatchKeeper(address[] calldata arr) external override {
        require(tx.origin == owner(), "only owner can add keeper");
        for (uint256 i = 0; i < arr.length; i++) {
            // if (keepBots.contains(arr[i])) {
            //     keepBots.remove(arr[i]);
            // }
            if (keepBotExists[arr[i]]) {
                keepBotExists[arr[i]] = false;
                keepBotSize--;
            }
        }

        emit RemoveBatchKeeper(msg.sender, arr);
    }

    function addBatchKeeper(address[] memory arr) external override {
        require(tx.origin == owner(), "only owner can add keeper");
        for (uint256 i = 0; i < arr.length; i++) {
            // if (!keepBots.contains(arr[i])) {
            //     keepBots.add(arr[i]);
            // }
            if (!keepBotExists[arr[i]]) {
                keepBotExists[arr[i]] = true;
                keepBotSize++;
            }
        }

        emit AddBatchKeeper(msg.sender, arr);
    }

    function removeKeeper(address _keeper) external override {
        require(tx.origin == owner(), "only owner can add keeper");
        require(keepBotExists[_keeper], "keeper not exist");
        keepBotExists[_keeper] = false;
        keepBotSize--;

        // require(!keepBots.contains(_keeper), "keeper not exist");
        // keepBots.remove(_keeper);
        emit RemoveKeeper(msg.sender, _keeper);
    }

    function isKeeper(address _query) external view override returns (bool) {
        return keepBotExists[_query];
        // return keepBots.contains(_query);
    }

    function setControl(address _control) external override onlyOwner {
        control = _control;
        emit SetControl(msg.sender, _control);
    }

    function isActiveControler(address add)
        external
        view
        override
        returns (bool)
    {
        return control == add;
    }

    // function keepBotSize() external view override returns (uint32) {
    //     return keepBotSize;
    // }

    // function getAllKeepBots()
    //     external
    //     view
    //     override
    //     returns (address[] memory)
    // {
    //     return keepBots.getAll();
    // }

    // function getKeepBotSize() external view override returns (uint32) {
    //     return uint32(keepBots.getSize());
    // }
}
