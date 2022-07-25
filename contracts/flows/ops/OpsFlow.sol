// SPDX-License-Identifier: GPL-2.0-or-later
// Create by Openflow.network core team.
pragma solidity ^0.8.0;
import "../../interfaces/IEvaSubFlow.sol";
import "../../lib/MathConv.sol";
import "../../interfaces/IOpsFlow.sol";
import {IEvabaseConfig} from "../../interfaces/IEvabaseConfig.sol";
import {IEvaFlowController} from "../../interfaces/IEvaFlowController.sol";
import {IEvaSafesFactory} from "../../interfaces/IEvaSafesFactory.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC1820Registry.sol";

contract OpsFlow is IEvaSubFlow, IOpsFlow, Ownable {
    using Address for address;
    bytes32 private constant _SUB_FLOW_INTERFACE = keccak256("getSubCalls(bytes)");

    mapping(uint256 => Task) private _tasks;
    IEvaSafesFactory public evaSafesFactory;
    IEvabaseConfig public config;
    uint32 private constant _MIN_INTERAL = 1 seconds;

    constructor(address _config, address _evaSafesFactory) {
        require(_evaSafesFactory != address(0), "addess is 0x");
        require(_config != address(0), "addess is 0x");
        config = IEvabaseConfig(_config);
        evaSafesFactory = IEvaSafesFactory(_evaSafesFactory);
        enableERC1820();
    }

    function check(bytes memory taskIdData) external view override returns (bool, bytes memory) {
        uint256 key = abi.decode(taskIdData, (uint256));

        if (!isActiveTask(key) || taskExpired(key)) {
            return (false, bytes(""));
        }

        return (true, taskIdData);
    }

    function setFactory(address factory) external onlyOwner {
        evaSafesFactory = IEvaSafesFactory(factory);
    }

    function execute(bytes memory executeData) external override returns (bool canDestoryFlow) {
        uint256 taskId = abi.decode(executeData, (uint256));
        Task memory task = _tasks[taskId];
        require(msg.sender == evaSafesFactory.get(task.owner), "shold be owner");
        require(isActiveTask(taskId), "not active");
        //Can be closed or not
        // solhint-disable not-rely-on-time
        if (block.timestamp > task.deadline || (task.deadline == 0 && task.startTime == 0)) {
            canDestoryFlow = true;
            delete _tasks[taskId];
        } else {
            // solhint-disable not-rely-on-time
            _tasks[taskId].lastExecTime = MathConv.toU64(block.timestamp);
        }
        emit TaskExecuted(taskId);
    }

    function createTask(Task memory task, uint256 taskId) external payable override returns (bytes memory _taskId) {
        require(task.inputs.length > 0, "invalid length");
        require(task.interval >= _MIN_INTERAL, "invalid interval");
        //check
        require(task.deadline > MathConv.toU64(block.timestamp) || task.deadline == 0, "invalid time");
        for (uint256 i = 0; i < task.inputs.length; i++) {
            (address contractAdd, , ) = abi.decode(task.inputs[i], (address, uint120, bytes));
            require(contractAdd != address(this) && contractAdd != msg.sender, "FORBIDDEN");
        }

        _tasks[taskId] = task;

        _taskId = abi.encode(taskId);
        emit TaskCreated(msg.sender, taskId, task);
    }

    function cancelTask(uint256 taskId) public override {
        Task storage task = _tasks[taskId];
        require(task.owner != address(0), "task not exist");

        if (msg.sender != evaSafesFactory.get(task.owner)) {
            require(taskExpired(taskId), "task is active");
        }

        delete _tasks[taskId];

        emit TaskCancelled(msg.sender, taskId);
    }

    function getTask(uint256 taskId) external view override returns (Task memory task) {
        task = _tasks[taskId];
    }

    function getSubCalls(bytes memory executeData) external view override returns (CallArgs[] memory subs) {
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
            MathConv.toU64(block.timestamp) >= startTime &&
            ((deadline >= lastExecTime + interval && MathConv.toU64(block.timestamp) >= lastExecTime + interval) ||
                (deadline == 0)) &&
            _tasks[taskId].owner != address(0);
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

    function enableERC1820() public onlyOwner {
        IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24).setInterfaceImplementer(
            address(this),
            _SUB_FLOW_INTERFACE,
            address(this)
        );
    }

    function removeERC1820() external onlyOwner {
        IERC1820Registry(0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24).setInterfaceImplementer(
            address(this),
            _SUB_FLOW_INTERFACE,
            address(0)
        );
    }
}
