//SPDX-License-Identifier: MIT
//Create by Openflow.network core team.
pragma solidity ^0.8.0;

import {IEvabaseConfig} from "./interfaces/IEvabaseConfig.sol";
import {EvabaseHelper, KeepNetWork} from "./lib/EvabaseHelper.sol";
import {IEvaSafesFactory} from "./interfaces/IEvaSafesFactory.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract EvabaseConfig is IEvabaseConfig, Ownable {
    struct KeepStuct {
        bool isActive;
        KeepNetWork keepNetWork;
    }
    mapping(address => KeepStuct) public keepBotExists;
    mapping(KeepNetWork => uint32) public keepBotSizes;
    // uint32 public override keepBotSize;
    // using EvabaseHelper for EvabaseHelper.AddressSet;
    // EvabaseHelper.AddressSet keepBots;

    address public override control;

    uint32 public override batchFlowNum = 2;

    function setBatchFlowNum(uint32 num) external override onlyOwner {
        batchFlowNum = num;
        emit SetBatchFlowNum(msg.sender, num);
    }

    function addKeeper(address _keeper, KeepNetWork keepNetWork)
        external
        override
    {
        require(tx.origin == owner(), "only owner can add keeper");
        require(!keepBotExists[_keeper].isActive, "keeper exist");
        keepBotExists[_keeper].isActive == true;
        // require(keepBots.contains(_keeper), "keeper exist");
        // keepBots.add(_keeper);
        keepBotSizes[keepNetWork] = keepBotSizes[keepNetWork] + 1;
        emit AddKeeper(msg.sender, _keeper, keepNetWork);
    }

    function removeBatchKeeper(
        address[] memory arr,
        KeepNetWork[] memory keepNetWorks
    ) external override {
        require(tx.origin == owner(), "only owner can add keeper");
        require(
            arr.length == keepNetWorks.length,
            "arr length not equal keepNetWorks length"
        );
        for (uint256 i = 0; i < arr.length; i++) {
            // if (keepBots.contains(arr[i])) {
            //     keepBots.remove(arr[i]);
            // }

            if (keepBotExists[arr[i]].isActive) {
                // keepBotExists[arr[i]].isActive = false;
                delete keepBotExists[arr[i]];
                keepBotSizes[keepNetWorks[i]] =
                    keepBotSizes[keepNetWorks[i]] -
                    1;
            }
        }

        emit RemoveBatchKeeper(msg.sender, arr, keepNetWorks);
    }

    function addBatchKeeper(
        address[] memory arr,
        KeepNetWork[] memory keepNetWorks
    ) external override {
        require(
            arr.length == keepNetWorks.length,
            "arr length not equal keepNetWorks length"
        );
        require(tx.origin == owner(), "only owner can add keeper");
        for (uint256 i = 0; i < arr.length; i++) {
            // if (!keepBots.contains(arr[i])) {
            //     keepBots.add(arr[i]);
            // }
            if (!keepBotExists[arr[i]].isActive) {
                // keepBotExists[arr[i]] = true;
                // keepBotSize++;

                // require(keepBots.contains(_keeper), "keeper exist");
                // keepBots.add(_keeper);
                keepBotExists[arr[i]].isActive == true;
                keepBotSizes[keepNetWorks[i]] =
                    keepBotSizes[keepNetWorks[i]] +
                    1;
            }
        }

        emit AddBatchKeeper(msg.sender, arr, keepNetWorks);
    }

    function removeKeeper(address _keeper, KeepNetWork keepNetWork)
        external
        override
    {
        require(tx.origin == owner(), "only owner can add keeper");
        require(keepBotExists[_keeper].isActive, "keeper not exist");
        delete keepBotExists[_keeper];
        keepBotSizes[keepNetWork] = keepBotSizes[keepNetWork] - 1;
        // require(!keepBots.contains(_keeper), "keeper not exist");
        // keepBots.remove(_keeper);
        emit RemoveKeeper(msg.sender, _keeper, keepNetWork);
    }

    function isKeeper(address _query) external view override returns (bool) {
        return keepBotExists[_query].isActive;
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

    function keepBotSize(KeepNetWork keepNetWork)
        external
        view
        override
        returns (uint32)
    {
        return keepBotSizes[keepNetWork];
    }

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
