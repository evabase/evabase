//SPDX-License-Identifier: MIT
//Create by Openflow.network core team.
pragma solidity ^0.8.0;
import "../interfaces/IStrategy.sol";
import "./StrategyBase.sol";

contract UniswapV2Strategy is IStrategy, StrategyBase {
    constructor(IUniswapV2Router02 _router, uint256 bp) StrategyBase(_router, bp) {} // solhint-disable no-empty-blocks

    function getRouter(
        address inputToken,
        address outputToken,
        uint256 maxInput,
        uint256 minRate
    )
        external
        view
        override
        returns (
            uint256 input,
            uint256 output,
            bytes memory execData
        )
    {
        return _checkRouter(inputToken, outputToken, maxInput, minRate);
    }

    function execute(
        address inputToken,
        address outputToken,
        bytes calldata execData
    ) external override {
        _swap(inputToken, outputToken, execData);
    }
}
