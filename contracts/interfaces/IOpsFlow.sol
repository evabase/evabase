//SPDX-License-Identifier: MIT
//Create by Openflow.network core team.
pragma solidity ^0.8.0;

interface IOpsFlow {
    struct Task {
        address owner; //拥有人
        address[] contracts;
        bytes[] inputs;
        uint256 startTime; //开始时间
        uint256 deadline; //过期时间
        uint256 lastExecTime; //上次执行时间
        uint128 interval; //至少15秒
    }

    event TaskExecute(address indexed user, uint256 taskId);

    event TaskCancel(address indexed user, uint256 taskId);

    event TaskPause(address indexed user, uint256 taskId);
    event TaskStart(address indexed user, uint256 taskId);
    event TaskCreated(address indexed user, uint256 indexed flowId, Task task);

    function createTask(Task memory task, uint256 flowId) external payable returns (bytes memory taskId);

    function changeStatus(uint256 taskId, bool pause) external;

    function cancelTask(uint256 taskId) external;

    function getTask(uint256 taskId) external view returns (Task memory task);
}
