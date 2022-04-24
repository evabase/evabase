//SPDX-License-Identifier: MIT
//Create by evabase.network core team.
pragma solidity ^0.8.0;

interface IEvaFlow {
    function owner() external view returns (address);

    function multicall(address target, bytes memory callData) external;

    function check(bytes memory checkData)
        external
        view
        returns (bool needExecute, bytes memory executeData);

    function execute(bytes memory executeData) external;

    function pause(uint256 flowId, bytes memory extraData) external;

    function start(uint256 flowId, bytes memory extraData) external;

    function destroy(uint256 flowId, bytes memory extraData) external;
}
