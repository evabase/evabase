//SPDX-License-Identifier: MIT
//Create by Openflow.network core team.
pragma solidity ^0.8.0;
import "../interfaces/IStrategy.sol";
import "./StrategyBase.sol";

contract UniswapV2Strategy is IStrategy, StrategyBase {
    mapping(address => bool) public executors;
    event ExecutorChanged(address acct, bool added);

    constructor(IUniswapV2Router02 _router, uint256 bp) StrategyBase(_router, bp) {}

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
        require(executors[msg.sender], "NO_EXECUTOR");
        _swap(inputToken, outputToken, execData);
    }

    // admin
    function setExecutor(address acct, bool add) external onlyOwner {
        if (add) {
            executors[acct] = true;
        } else {
            delete executors[acct];
        }
        emit ExecutorChanged(acct, add);
    }
}
