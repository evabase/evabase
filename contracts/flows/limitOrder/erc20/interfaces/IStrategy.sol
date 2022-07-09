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
    /// @notice The core execution function of the strategy
    /// @param inputToken The address of input token
    /// @param outputToken The address of output token
    /// @param execData The encoded execution data
    function execute(
        address inputToken,
        address outputToken,
        bytes calldata execData
    ) external;

    /// @notice Query the price and generate execution data
    /// @param inputToken The address of input token
    /// @param outputToken The address of output token
    /// @param maxInput The maximum amount of input token
    /// @param minRate The lower exchange rate
    /// @return input The amount to be swapped in
    /// @return output The amount to be received
    /// @return execData The encoded execution data
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
