//SPDX-License-Identifier: MIT
//Create by Openflow.network core team.
pragma solidity ^0.8.0;
import "../lib/TransferHelper.sol";
import "./MockERC20.sol";

import "../limitOrder/erc20/interfaces/IStrategy.sol";
import "../limitOrder/erc20/strategyies/StrategyBase.sol";

contract MockSwapStrategy is IStrategy {
    uint256 private _amountOut;

    struct SwapArgs {
        address[] path;
        uint256 amountIn;
        uint256 amountOutMin;
        uint256 deadline;
    }

    function getRouter(
        address inputToken,
        address outputToken,
        uint256 maxInput,
        uint256
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
        address[] memory path = new address[](2);
        path[0] = inputToken;
        path[1] = outputToken;

        input = maxInput;
        output = input * 2;
        execData = abi.encode(
            // solhint-disable not-rely-on-time
            SwapArgs({path: path, amountIn: input, amountOutMin: output, deadline: block.timestamp + 1 hours})
        );
    }

    function execute(
        address inputToken,
        address outputToken,
        bytes calldata execData
    ) external override {
        SwapArgs memory args = abi.decode(execData, (SwapArgs));
        require(inputToken == args.path[0], "bad input token");
        require(outputToken == args.path[1], "bad output token");

        uint256 balance = TransferHelper.balanceOf(inputToken, address(this));
        require(balance >= args.amountIn, "bad input amount");
        uint256 out = _amountOut == 0 ? args.amountOutMin : _amountOut;
        //自动Mint代币
        if (outputToken != TransferHelper.ETH_ADDRESS) {
            MockERC20(outputToken).mint(out);
        }
        TransferHelper.safeTransferTokenOrETH(outputToken, msg.sender, out);
        _amountOut = 0; //reset
    }

    function mockSwapOut(uint256 amount) external {
        _amountOut = amount;
    }

    receive() external payable {} // solhint-disable  no-empty-blocks
}
