//SPDX-License-Identifier: MIT
//Create by Openflow.network core team.
pragma solidity ^0.8.0;

interface IERC20Exchange {
    function afterCreate(bytes32 key) external;

    function afterExcute(
        bytes32 key,
        uint256 input,
        uint256 output
    ) external;
}

interface IStrategy {
    function execute(
        address inputToken,
        address outputToken,
        bytes calldata execData
    ) external;

    function getRouter(
        address intputToken,
        address outputToken,
        uint256 maxInput,
        uint256 minRate
    )
        external
        view
        returns (
            uint256 input,
            uint256 output,
            bytes memory execData
        );
}
