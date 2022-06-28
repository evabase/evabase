//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity ^0.8.0;
import "./venders/uniswapv2/IUniswapV2Factory.sol";
import "./venders/uniswapv2/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract EvaBaseRead {
    IUniswapV2Factory public factory;

    ERC20 public usdt;

    ERC20 public usdc;

    ERC20 public weth;

    constructor(
        address _factory,
        address _usdt,
        address _usdc,
        address _weth
    ) {
        factory = IUniswapV2Factory(_factory);
        usdt = ERC20(_usdt);
        usdc = ERC20(_usdc);
        weth = ERC20(_weth);
    }

    function getBatchUPrice(address[] memory tokens) public view returns (uint256[] memory prices) {
        prices = new uint256[](tokens.length);
        for (uint256 i = 0; i < tokens.length; i++) {
            prices[i] = getUPrice(tokens[i]);
        }
    }

    function getBatchPrice(address[] memory lps, address[] memory underlyingAddress)
        public
        view
        returns (uint256[] memory prices)
    {
        require(lps.length == underlyingAddress.length, "invalid length");
        prices = new uint256[](lps.length);
        for (uint256 i = 0; i < lps.length; i++) {
            prices[i] = getPrice(lps[i], underlyingAddress[i]);
        }
    }

    function getUPrice(address _tokenAddress) public view returns (uint256 price) {
        if (_tokenAddress == address(0x0)) {
            return 0;
        }

        if (_tokenAddress == address(usdt) || _tokenAddress == address(usdc)) {
            return 1e18;
        }

        address lpU0 = factory.getPair(_tokenAddress, address(usdt));
        address lpU1 = factory.getPair(_tokenAddress, address(usdc));
        // usdt(usdc)/token pair not exist
        if (lpU0 == lpU1) {
            address lpw0 = factory.getPair(_tokenAddress, address(weth));
            if (lpw0 != address(0)) {
                address lpUW = factory.getPair(address(weth), address(usdt));

                //1 token = xx eth
                uint256 price0 = getPrice(lpw0, address(weth));
                //1 eth = xx usdt
                uint256 price1 = getPrice(lpUW, address(usdt));

                price = (price0 * price1) / 1e18;
            }
        } else {
            // usdt(USDC)/token pair exist
            if (lpU0 != address(0)) {
                price = getPrice(lpU0, address(usdt));
            }

            if (lpU0 == address(0) && lpU1 != address(0)) {
                price = getPrice(lpU1, address(usdc));
            }
        }
    }

    function getPrice(
        address token0,
        address token1,
        address underlyingAddress
    ) public view returns (uint256 price) {
        // (reserve1/10 ** token1'decimals) /(reserve0/10** token0'decimals)
        address _lpAddress = factory.getPair(token0, token1);
        price = getPrice(_lpAddress, underlyingAddress);
    }

    function getPrice(address lpAddress, address underlyingAddress) public view returns (uint256 price) {
        if (lpAddress == address(0)) return price;

        (uint256 reserve0, uint256 reserve1, ) = IUniswapV2Pair(lpAddress).getReserves();

        uint8 dec0 = ERC20(IUniswapV2Pair(lpAddress).token0()).decimals();
        uint8 dec1 = ERC20(IUniswapV2Pair(lpAddress).token1()).decimals();
        //(reserve1/10 ** token1 的 decimals) /(reserve0/10** token0 的decimals)
        if (underlyingAddress == IUniswapV2Pair(lpAddress).token1()) {
            price = (reserve1 * 1e18 * (10**dec0)) / (reserve0 * (10**dec1));
        }

        if (underlyingAddress == IUniswapV2Pair(lpAddress).token0()) {
            price = (reserve0 * 1e18 * (10**dec1)) / (reserve1 * (10**dec0));
        }
    }
}
