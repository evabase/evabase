//SPDX-License-Identifier: MIT
//Create by Openflow.network core team.
pragma solidity ^0.8.0;

import "./interfaces/IEvabaseConfig.sol";
import {EvabaseHelper, KeepNetWork} from "./lib/EvabaseHelper.sol";
import {IEvaSafesFactory} from "./interfaces/IEvaSafesFactory.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract EvabaseConfig is IEvabaseConfig, Ownable {
    mapping(address => KeepStruct) private _keepBotExists;
    mapping(KeepNetWork => uint32) public override keepBotSizes;
    // uint32 public override keepBotSize;
    // using EvabaseHelper for EvabaseHelper.AddressSet;
    // EvabaseHelper.AddressSet keepBots;

    address public override control;

    uint32 public override batchFlowNum = 60;

    function setBatchFlowNum(uint32 num) external override onlyOwner {
        batchFlowNum = num;
        emit SetBatchFlowNum(msg.sender, num);
    }

    function addKeeper(address _keeper, KeepNetWork keepNetWork) external override {
        require(msg.sender == owner(), "only owner can add keeper");
        require(!_keepBotExists[_keeper].isActive, "keeper exist");

        _keepBotExists[_keeper] = KeepStruct(true, keepNetWork);

        // require(keepBots.contains(_keeper), "keeper exist");
        // keepBots.add(_keeper);
        keepBotSizes[keepNetWork] = keepBotSizes[keepNetWork] + 1;
        emit AddKeeper(msg.sender, _keeper, keepNetWork);
    }

    function removeBatchKeeper(address[] memory arr) external override {
        require(msg.sender == owner(), "only owner can add keeper");
        // require(
        //     arr.length == keepNetWorks.length,
        //     "arr length not equal keepNetWorks length"
        // );
        for (uint256 i = 0; i < arr.length; i++) {
            // if (keepBots.contains(arr[i])) {
            //     keepBots.remove(arr[i]);
            // }

            if (_keepBotExists[arr[i]].isActive) {
                // _keepBotExists[arr[i]].isActive = false;

                keepBotSizes[_keepBotExists[arr[i]].keepNetWork] = keepBotSizes[_keepBotExists[arr[i]].keepNetWork] - 1;
                delete _keepBotExists[arr[i]];
            }
        }

        emit RemoveBatchKeeper(msg.sender, arr);
    }

    function addBatchKeeper(address[] memory arr, KeepNetWork[] memory keepNetWorks) external override {
        require(arr.length == keepNetWorks.length, "invalid length");
        require(msg.sender == owner(), "only owner");
        for (uint256 i = 0; i < arr.length; i++) {
            // if (!keepBots.contains(arr[i])) {
            //     keepBots.add(arr[i]);
            // }
            if (!_keepBotExists[arr[i]].isActive) {
                // _keepBotExists[arr[i]] = true;
                // keepBotSize++;

                // require(keepBots.contains(_keeper), "keeper exist");
                // keepBots.add(_keeper);
                _keepBotExists[arr[i]] = KeepStruct(true, keepNetWorks[i]);

                // stuct.isActive == true;
                // _keepBotExists[arr[i]].keepNetWork == keepNetWorks[i];
                keepBotSizes[keepNetWorks[i]] = keepBotSizes[keepNetWorks[i]] + 1;
            }
        }

        emit AddBatchKeeper(msg.sender, arr, keepNetWorks);
    }

    function removeKeeper(address _keeper) external override {
        require(msg.sender == owner(), "only owner can add keeper");
        require(_keepBotExists[_keeper].isActive, "keeper not exist");

        KeepNetWork _keepNetWork = _keepBotExists[_keeper].keepNetWork;
        keepBotSizes[_keepNetWork] = keepBotSizes[_keepNetWork] - 1;
        delete _keepBotExists[_keeper];
        // require(!keepBots.contains(_keeper), "keeper not exist");
        // keepBots.remove(_keeper);
        emit RemoveKeeper(msg.sender, _keeper);
    }

    function isKeeper(address _query) external view override returns (bool) {
        return _keepBotExists[_query].isActive;
        // return keepBots.contains(_query);
    }

    function getKeepBot(address _query) external view override returns (KeepStruct memory) {
        return _keepBotExists[_query];
        // return keepBots.contains(_query);
    }

    function setControl(address _control) external override onlyOwner {
        control = _control;
        emit SetControl(msg.sender, _control);
    }

    function isActiveControler(address add) external view override returns (bool) {
        return control == add;
    }

    // function keepBotSizes(KeepNetWork keepNetWork)
    //     external
    //     view
    //     override
    //     returns (uint32)
    // {
    //     return keepBotSizes[keepNetWork];
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
