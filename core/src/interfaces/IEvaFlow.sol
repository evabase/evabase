//SPDX-License-Identifier: MIT
//Create by evabase.network core team.
pragma solidity ^0.8.0;

interface IEvaFlow {
    function owner() external view returns (address);

    function ownerWalletSafes() external view returns (address);

    function check(bytes memory checkData)
        external
        view
        returns (bool needExecute, bytes memory executeData);

    function multicall(bytes memory data) external;

    function execute(bytes memory executeData) external;

    function destroy() external;
}
