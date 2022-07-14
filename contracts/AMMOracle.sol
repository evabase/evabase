//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity ^0.8.0;
import "./venders/uniswapv2/IUniswapV2Factory.sol";
import "./venders/uniswapv2/IUniswapV2Pair.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AMMOracle {
    IUniswapV2Factory private immutable _FACTORY; //solhint-disable

    ERC20 private immutable _USDT;

    ERC20 private immutable _USDC;

    ERC20 private immutable _WETH;

    constructor(
        address _factory,
        address _usdt,
        address _usdc,
        address _weth
    ) {
        _FACTORY = IUniswapV2Factory(_factory);
        _USDT = ERC20(_usdt);
        _USDC = ERC20(_usdc);
        _WETH = ERC20(_weth);
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

        if (_tokenAddress == address(_USDT) || _tokenAddress == address(_USDC)) {
            return 1e18;
        }

        address lpU0 = _FACTORY.getPair(_tokenAddress, address(_USDT));
        address lpU1 = _FACTORY.getPair(_tokenAddress, address(_USDC));
        // _USDT(_USDC)/token pair not exist
        if (lpU0 == lpU1) {
            address lpw0 = _FACTORY.getPair(_tokenAddress, address(_WETH));
            if (lpw0 != address(0)) {
                address lpUW = _FACTORY.getPair(address(_WETH), address(_USDT));

                //1 token = xx eth
                uint256 price0 = getPrice(lpw0, address(_WETH));
                //1 eth = xx _USDT
                uint256 price1 = getPrice(lpUW, address(_USDT));

                price = (price0 * price1) / 1e18;
            }
        } else {
            // _USDT(USDC)/token pair exist
            if (lpU0 != address(0)) {
                price = getPrice(lpU0, address(_USDT));
            }

            if (lpU0 == address(0) && lpU1 != address(0)) {
                price = getPrice(lpU1, address(_USDC));
            }
        }
    }

    function getPrice(
        address token0,
        address token1,
        address underlyingAddress
    ) public view returns (uint256 price) {
        // (reserve1/10 ** token1'decimals) /(reserve0/10** token0'decimals)
        address _lpAddress = _FACTORY.getPair(token0, token1);
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
