//SPDX-License-Identifier: MIT
//Create by Openflow.network core team.
pragma solidity ^0.8.0;

import "../../../lib/TransferHelper.sol";

import "./uniswapv2/IUniswapV2Router02.sol";
import "./uniswapv2/IUniswapV2Factory.sol";
import "./uniswapv2/IUniswapV2Pair.sol";

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract StrategyBase is Ownable {
    using SafeMath for uint256;
    uint256 public constant DEADLINE = 30 minutes;
    address public immutable weth;
    uint256 public immutable bp; //997
    IUniswapV2Router02 public immutable router;

    struct SwapArgs {
        address[] path;
        uint256 amountIn;
        uint256 amountOutMin;
        uint256 deadline;
    }

    constructor(IUniswapV2Router02 router_, uint256 bp_) {
        router = router_;
        weth = router_.WETH();
        bp = bp_; //997
    }

    function calcMaxInput(
        address inputToken,
        address outputToken,
        uint256 minRate
    ) public view returns (uint256 amountIn) {
        IUniswapV2Factory factory = IUniswapV2Factory(router.factory());

        IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(inputToken, outputToken));
        if (address(pair) == address(0)) {
            return 0;
        }

        (uint112 r0, uint112 r1, ) = pair.getReserves();

        (r0, r1) = inputToken < outputToken ? (r0, r1) : (r1, r0);

        // (in*0.997*R1)/(R0+in*0.997) >= in*MinRate
        // =>  in <= (997*R1 - 1000*MinRate*R0)/(997*MinRate)
        uint256 a = bp.mul(uint256(r1));
        uint256 b = minRate.mul(uint256(r0)).mul(1000).div(1e18);
        if (b >= a) {
            return 0;
        }
        uint256 c = bp.mul(minRate).div(1e18);
        amountIn = (a - b).div(c);
    }

    function _getAmountsOut(uint256 amountIn, address[] memory path) internal view returns (uint256 amountOut) {
        uint256[] memory amounts = router.getAmountsOut(amountIn, path);
        amountOut = amounts[amounts.length - 1];
    }

    function _checkRouter(
        address inputToken,
        address outputToken,
        uint256 maxInput,
        uint256 minRate
    )
        internal
        view
        returns (
            uint256 input,
            uint256 output,
            bytes memory execData
        )
    {
        if (inputToken == TransferHelper.ETH_ADDRESS) {
            inputToken = weth;
        }
        if (outputToken == TransferHelper.ETH_ADDRESS) {
            outputToken = weth;
        }
        address[] memory path = new address[](2);
        path[0] = inputToken;
        path[1] = outputToken;

        uint256 canInput = calcMaxInput(inputToken, outputToken, minRate);
        if (canInput > maxInput) {
            canInput = maxInput;
        }
        uint256[] memory amounts = router.getAmountsOut(canInput, path);

        output = amounts[amounts.length - 1];
        input = amounts[0];
        execData = abi.encode(
            // solhint-disable not-rely-on-time
            SwapArgs({path: path, amountIn: input, amountOutMin: output, deadline: block.timestamp + DEADLINE})
        );
    }

    function _swap(
        address inputToken,
        address outputToken,
        bytes calldata execData
    ) internal returns (uint256 bought) {
        SwapArgs memory args = abi.decode(execData, (SwapArgs));

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
        bought = TransferHelper.balanceOf(outputToken, address(this)).sub(preSwapBalance);
        require(bought >= args.amountOutMin, "INSUFFICIENT_OUTPUT_AMOUNT");
    }

    receive() external payable {} // solhint-disable  no-empty-blocks
}
