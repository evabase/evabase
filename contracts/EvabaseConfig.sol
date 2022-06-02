//SPDX-License-Identifier: MIT
//Create by Openflow.network core team.
pragma solidity ^0.8.0;

import "./interfaces/IEvabaseConfig.sol";

import {EvabaseHelper, KeepNetWork} from "./lib/EvabaseHelper.sol";
import {IEvaSafesFactory} from "./interfaces/IEvaSafesFactory.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract EvabaseConfig is IEvabaseConfig, Ownable {
    event ItemChanged(bytes32 indexed key, bytes32 newValue);

    mapping(address => KeepInfo) private _keepBotExists;
    mapping(KeepNetWork => uint32) public override keepBotSizes;

    address public override control;
    uint32 public override batchFlowNum = 60;

    mapping(bytes32 => bytes32) private _bytes32items;

    function setBatchFlowNum(uint32 num) external onlyOwner {
        batchFlowNum = num;
        emit SetBatchFlowNum(msg.sender, num);
    }

    function addKeeper(address _keeper, KeepNetWork keepNetWork) external {
        require(msg.sender == owner(), "only owner can add keeper");
        require(!_keepBotExists[_keeper].isActive, "keeper exist");

        _keepBotExists[_keeper] = KeepInfo(true, keepNetWork);

        // require(keepBots.contains(_keeper), "keeper exist");
        // keepBots.add(_keeper);
        keepBotSizes[keepNetWork] = keepBotSizes[keepNetWork] + 1;
        emit AddKeeper(msg.sender, _keeper, keepNetWork);
    }

    function removeBatchKeeper(address[] memory arr) external onlyOwner {
        for (uint256 i = 0; i < arr.length; i++) {
            if (_keepBotExists[arr[i]].isActive) {
                keepBotSizes[_keepBotExists[arr[i]].keepNetWork] = keepBotSizes[_keepBotExists[arr[i]].keepNetWork] - 1;
                delete _keepBotExists[arr[i]];
            }
        }

        emit RemoveBatchKeeper(msg.sender, arr);
    }

    function addBatchKeeper(address[] memory arr, KeepNetWork[] memory keepNetWorks) external onlyOwner {
        require(arr.length == keepNetWorks.length, "invalid length");
        for (uint256 i = 0; i < arr.length; i++) {
            if (!_keepBotExists[arr[i]].isActive) {
                _keepBotExists[arr[i]] = KeepInfo(true, keepNetWorks[i]);
                keepBotSizes[keepNetWorks[i]] = keepBotSizes[keepNetWorks[i]] + 1;
            }
        }

        emit AddBatchKeeper(msg.sender, arr, keepNetWorks);
    }

    function removeKeeper(address _keeper) external onlyOwner {
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
    }

    function getKeepBot(address _query) external view override returns (KeepInfo memory) {
        return _keepBotExists[_query];
    }

    function setControl(address _control) external onlyOwner {
        control = _control;
        emit SetControl(msg.sender, _control);
    }

    function isActiveControler(address add) external view override returns (bool) {
        return control == add;
    }

    function setBytes32Item(bytes32 key, bytes32 value) external onlyOwner {
        _bytes32items[key] = value;

        emit ItemChanged(key, value);
    }

    function getBytes32Item(bytes32 key) external view override returns (bytes32) {
        return _bytes32items[key];
    }

    function getAddressItem(bytes32 key) external view override returns (address) {
        return address(uint160(uint256(_bytes32items[key])));
    }
}
