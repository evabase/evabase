// SPDX-License-Identifier: GPL-2.0-or-later
// Create by Openflow.network core team.
pragma solidity ^0.8.0;
import "../../interfaces/IEvaSubFlow.sol";
import "../../interfaces/EIP712.sol";
import "../../lib/Utils.sol";
import "../../interfaces/IOpsFlow.sol";
import {IEvabaseConfig} from "../../interfaces/IEvabaseConfig.sol";
import {IEvaFlowController} from "../../interfaces/IEvaFlowController.sol";
import {IEvaSafesFactory} from "../../interfaces/IEvaSafesFactory.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OpsFlow is IEvaSubFlow, IOpsFlow, Ownable {
    using Address for address;

    mapping(uint256 => Task) private _tasks;
    IEvaSafesFactory public evaSafesFactory;
    IEvabaseConfig public config;
    uint32 private constant _MIN_INTERAL = 1 seconds;

    constructor(address _config, address _evaSafesFactory) {
        require(_evaSafesFactory != address(0), "addess is 0x");
        require(_config != address(0), "addess is 0x");
        config = IEvabaseConfig(_config);
        evaSafesFactory = IEvaSafesFactory(_evaSafesFactory);
    }

    function check(bytes memory taskIdData) external view override returns (bool, bytes memory) {
        uint256 key = abi.decode(taskIdData, (uint256));

        if (!isActiveTask(key) || taskExpired(key)) {
            return (false, bytes(""));
        }

        return (true, taskIdData);
    }

    function multicall(address target, bytes memory callData) external override onlyOwner {
        require(target != address(this), "FORBIDDEN");
        require(target != owner(), "FORBIDDEN");
        target.functionCall(callData, "CallFailed");
        return;
    }

    function setFactory(address factory) external onlyOwner {
        evaSafesFactory = IEvaSafesFactory(factory);
    }

    function execute(bytes memory executeData) external override returns (bool canDestoryFlow) {
        uint256 taskId = abi.decode(executeData, (uint256));
        Task memory task = _tasks[taskId];
        //Can be closed or not
        if (block.timestamp + task.interval > task.deadline) {
            canDestoryFlow = true;
        } else {
            _tasks[taskId].lastExecTime = Utils.toUint64(block.timestamp);
        }
        emit TaskExecuted(taskId);
    }

    function createTask(Task memory task, uint256 taskId) external payable override returns (bytes memory _taskId) {
        require(task.inputs.length > 0, "invalid length");
        //check
        require(task.deadline > Utils.toUint64(block.timestamp), "invalid time");
        for (uint256 i = 0; i < task.inputs.length; i++) {
            (address contractAdd, , ) = abi.decode(task.inputs[i], (address, uint120, bytes));
            require(contractAdd != address(this) && contractAdd != msg.sender, "FORBIDDEN");
        }

        task.lastExecTime = Utils.toUint64(block.timestamp);
        _tasks[taskId] = task;

        _taskId = abi.encode(taskId);
        emit TaskCreated(msg.sender, taskId, task);
    }

    function changeStatus(uint256 taskId, bool pause) public override {
        Task memory task = _tasks[taskId];
        require(task.owner != address(0), "task not exist");
        require(msg.sender == evaSafesFactory.get(task.owner), "shold be owner");

        if (pause) {
            emit TaskPause(msg.sender, taskId);
        } else {
            emit TaskStart(msg.sender, taskId);
        }
    }

    function cancelTask(uint256 taskId) public override {
        Task storage task = _tasks[taskId];
        require(task.owner != address(0), "task not exist");

        if (msg.sender != evaSafesFactory.get(task.owner)) {
            require(taskExpired(taskId), "task is active");
        }

        delete _tasks[taskId];

        emit TaskCancel(msg.sender, taskId);
    }

    function getTask(uint256 taskId) external view override returns (Task memory task) {
        task = _tasks[taskId];
    }

    function getSubCalls(bytes memory executeData) external view override returns (CallArgs[] memory subs){
        uint256 taskId = abi.decode(executeData, (uint256));
        uint256 taskLength = _tasks[taskId].inputs.length;
        subs = new CallArgs[](taskLength);
        for (uint256 i = 0; i < taskLength; i++) {
            (address _contractAdd, uint120 _value, bytes memory _data) = abi.decode(
                _tasks[taskId].inputs[i],
                (address, uint120, bytes)
            );
            subs[i] = CallArgs({target: _contractAdd, valueETH: _value, data: _data});
        }
    }

     

    function isActiveTask(uint256 taskId) public view returns (bool) {
        uint64 deadline = _tasks[taskId].deadline;
        uint64 interval = _tasks[taskId].interval;
        uint64 startTime = _tasks[taskId].startTime;
        uint64 lastExecTime = _tasks[taskId].lastExecTime;
        return
            Utils.toUint64(block.timestamp) >= startTime &&
            deadline >= lastExecTime + interval &&
            Utils.toUint64(block.timestamp) > lastExecTime + 1;
    }

    function needClose(bytes memory taskIdData) external view override returns (bool yes) {
        uint256 taskId = abi.decode(taskIdData, (uint256));
        yes = taskExpired(taskId);
    }

    function close(bytes memory taskIdData) external override {
        uint256 taskId = abi.decode(taskIdData, (uint256));
        cancelTask(taskId);
    }

    function taskExpired(uint256 taskId) public view returns (bool) {
        // solhint-disable
        uint256 deadline = _tasks[taskId].deadline;
        return deadline > 0 && deadline < block.timestamp;
    }
}
