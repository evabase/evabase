// SPDX-License-Identifier: GPL-2.0-or-later
// Create by Openflow.network core team.
pragma solidity ^0.8.0;
import "../../interfaces/IEvaFlow.sol";
import "../../interfaces/EIP712.sol";
import "../../lib/Utils.sol";
import "../../interfaces/IOpsFlow.sol";
import {IEvabaseConfig} from "../../interfaces/IEvabaseConfig.sol";
import {IEvaSafes} from "../../interfaces/IEvaSafes.sol";
import {IEvaFlowController} from "../../interfaces/IEvaFlowController.sol";
import {IEvaSafesFactory} from "../../interfaces/IEvaSafesFactory.sol";
import "@openzeppelin/contracts/utils/Address.sol";

contract OpsFlow is IEvaFlow, IOpsFlow {
    using Address for address;

    mapping(uint256 => Task) private _tasks;
    IEvaSafesFactory public evaSafesFactory;
    IEvabaseConfig public config;
    address private _owner;
    uint32 private constant _MIN_INTERAL = 15 seconds;

    constructor(address _config, address _evaSafesFactory) {
        require(_evaSafesFactory != address(0), "addess is 0x");
        require(_config != address(0), "addess is 0x");
        config = IEvabaseConfig(_config);
        evaSafesFactory = IEvaSafesFactory(_evaSafesFactory);
        _owner = msg.sender;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function check(bytes memory taskIdData) external view override returns (bool, bytes memory) {
        uint256 key = abi.decode(taskIdData, (uint256));

        if (!isActiveTask(key) || taskExpired(key)) {
            return (false, bytes(""));
        }

        return (true, taskIdData);
    }

    function multicall(address target, bytes memory callData) external override {
        require(_owner == msg.sender, "only for owner");
        require(target != address(this), "FORBIDDEN");
        require(target != _owner, "FORBIDDEN");
        target.functionCall(callData, "CallFailed");
        return;
    }

    function setFactory() external {
        require(_owner == msg.sender, "only for owner");
        evaSafesFactory = IEvaSafesFactory(msg.sender);
    }

    function execute(bytes memory executeData) external override returns (bool canDestoryFlow) {
        uint256 taskId = abi.decode(executeData, (uint256));

        Task memory task = _tasks[taskId];
        for (uint256 i = 0; i < task.contracts.length; i++) {
            require(task.contracts[i] != address(this) && task.contracts[i] != msg.sender, "FORBIDDEN");
            task.contracts[i].functionCall(task.inputs[i], "CallFailed");
        }

        //Can be closed or not
        if (block.timestamp + _tasks[taskId].interval > _tasks[taskId].deadline) {
            canDestoryFlow = true;
        } else {
            _tasks[taskId].lastExecTime = block.timestamp;
        }
        emit TaskExecute(msg.sender, taskId);
    }

    function createTask(Task memory task, uint256 taskId) external payable override returns (bytes memory _taskId) {
        require(msg.sender == evaSafesFactory.get(task.owner), "only safes can creat task");

        require(task.contracts.length == task.inputs.length && task.contracts.length > 0, "invalid length");
        require(task.interval >= _MIN_INTERAL, "invalid interval");
        require(task.startTime > block.timestamp && task.deadline > task.startTime + task.interval, "invalid time");
        task.lastExecTime = task.startTime;
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

    function isActiveTask(uint256 taskId) public view returns (bool) {
        uint256 deadline = _tasks[taskId].deadline;
        uint128 interval = _tasks[taskId].interval;
        uint256 startTime = _tasks[taskId].startTime;
        uint256 lastExecTime = _tasks[taskId].lastExecTime;
        return deadline >= lastExecTime + interval && block.timestamp <= startTime + interval;
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

    /**
    @dev can receive ETH, owner can refund.
   */
    receive() external payable {} //solhint-disable
}
