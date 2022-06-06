//SPDX-License-Identifier: MIT
//Create by Openflow.network core team.
pragma solidity ^0.8.0;

interface IOpsFlow {
    struct Task {
        address owner; //拥有人
        bytes[] inputs; //abi.encode(target+callData+value)
        uint64 startTime; //开始时间
        uint64 deadline; //过期时间
        uint64 lastExecTime; //上次执行时间
        uint64 interval; //至少15秒
    }

    event TaskExecuted(uint256 indexed taskId);

    event TaskCancelled(address indexed user, uint256 taskId);

    event TaskCreated(address indexed user, uint256 indexed flowId, Task task);

    function createTask(Task memory task, uint256 flowId) external payable returns (bytes memory taskId);

    function cancelTask(uint256 taskId) external;

    function getTask(uint256 taskId) external view returns (Task memory task);
}
