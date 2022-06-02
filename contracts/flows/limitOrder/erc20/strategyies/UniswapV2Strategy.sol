//SPDX-License-Identifier: MIT
//Create by Openflow.network core team.
pragma solidity ^0.8.0;
import "../interfaces/IStrategy.sol";
import "./uniswapv2/IUniswapV2Router02.sol";

import "../../../../lib/TransferHelper.sol";
import "./uniswapv2/IUniswapV2Factory.sol";
import "./uniswapv2/IUniswapV2Pair.sol";

contract UniswapV2Strategy is IStrategy {
    uint256 public constant DEADLINE = 30 minutes;

    address private immutable _WETH; //solhint-disable
    uint256 private immutable _BP; //base point=997 //solhint-disable
    IUniswapV2Router02 public immutable router;

    struct SwapArgs {
        address[] path;
        uint256 amountIn;
        uint256 amountOutMin;
        uint256 deadline;
    }

    constructor(IUniswapV2Router02 router_, uint256 bp_) {
        require(bp_ <= 1000, "invalid bp");
        router = router_;
        _WETH = router_.WETH();
        _BP = bp_; //997
    }

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
        if (inputToken == TransferHelper.ETH_ADDRESS) {
            inputToken = _WETH;
        }
        if (outputToken == TransferHelper.ETH_ADDRESS) {
            outputToken = _WETH;
        }
        address[] memory path = new address[](2);
        path[0] = inputToken;
        path[1] = outputToken;

        (input, output) = getAmountsOut(inputToken, outputToken, maxInput, minRate);
        if (input > 0) {
            execData = abi.encode(
                // solhint-disable not-rely-on-time
                SwapArgs({path: path, amountIn: input, amountOutMin: output, deadline: block.timestamp + DEADLINE})
            );
        }
    }

    function execute(
        address inputToken,
        address outputToken,
        bytes calldata execData
    ) external override {
        SwapArgs memory args = abi.decode(execData, (SwapArgs));

        address inputReal = inputToken == TransferHelper.ETH_ADDRESS ? _WETH : inputToken;
        address outputReal = outputToken == TransferHelper.ETH_ADDRESS ? _WETH : outputToken;

        require(inputReal == args.path[0], "INVALID_PATH[0]");
        require(outputReal == args.path[args.path.length - 1], "INVALID_PATH[-1]");

        uint256 preSwapBalance = TransferHelper.balanceOf(outputToken, address(this));
        if (inputToken == TransferHelper.ETH_ADDRESS) {
            router.swapExactETHForTokens{value: args.amountIn}(
                args.amountOutMin,
                args.path,
                address(this),
                args.deadline
            );
        } else {
            TransferHelper.safeApprove(inputToken, address(router), args.amountIn);

            // swap: A->B->ETH
            if (outputToken == TransferHelper.ETH_ADDRESS) {
                router.swapExactTokensForETH(args.amountIn, args.amountOutMin, args.path, address(this), args.deadline);
            } else {
                router.swapExactTokensForTokens(
                    args.amountIn,
                    args.amountOutMin,
                    args.path,
                    address(this),
                    args.deadline
                );
            }
        }

        //check bought amount
        uint256 bought = TransferHelper.balanceOf(outputToken, address(this)) - preSwapBalance;
        require(bought >= args.amountOutMin, "INSUFFICIENT_OUTPUT_AMOUNT");

        //transfer
        TransferHelper.safeTransferTokenOrETH(outputToken, msg.sender, bought);
    }

    function getAmountsOut(
        address inputToken,
        address outputToken,
        uint256 maxInput,
        uint256 minRate
    ) public view returns (uint256 amountIn, uint256 amountOut) {
        IUniswapV2Factory factory = IUniswapV2Factory(router.factory());

        IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(inputToken, outputToken));
        if (address(pair) == address(0)) {
            return (0, 0);
        }

        (uint256 r0, uint256 r1, ) = pair.getReserves();

        (r0, r1) = inputToken < outputToken ? (r0, r1) : (r1, r0);

        // R=MinRate
        // (in*0.997*R1)/(R0+in*0.997) >= in*MinRate
        // =>  in <= (997*R1 - 1000*MinRate*R0)/(997*MinRate)
        // =>  in <= R1/R - 1000 * R0 / BP
        uint256 a = (r1 * 1e18) / minRate;
        uint256 b = (1000 * r0) / _BP;
        if (b >= a) {
            return (0, 0);
        }
        amountIn = a - b > maxInput ? maxInput : a - b;
        amountOut = (amountIn * _BP * r1) / (r0 * 1000 + amountIn * _BP);
        //safe check
        require((amountIn * minRate) / 1e18 <= amountOut, "invalid amountIn");
    }

    receive() external payable {} // solhint-disable  no-empty-blocks
}
