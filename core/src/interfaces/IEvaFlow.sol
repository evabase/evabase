//SPDX-License-Identifier: MIT
//Create by evabase.network core team.
pragma solidity ^0.8.0;

interface IEvaFlow {
    function check(bytes memory checkData)
        external
        view
        returns (bool needExecute, bytes memory executeData);

    function execute(bytes memory executeData) external;

    // function destroy() external;

    function create(uint256 flowId, bytes memory extraData)
        external
        returns (bytes memory checkData);

    function pause(uint256 flowId, bytes memory extraData) external;

    function start(uint256 flowId, bytes memory extraData) external;

    function destroy(uint256 flowId, bytes memory extraData) external;
}

interface IEvaFlowExtra is IEvaFlow {
    function owner() external view returns (address);

    function multicall(bytes memory data) external;

    function ownerWalletSafes() external view returns (address);
}
