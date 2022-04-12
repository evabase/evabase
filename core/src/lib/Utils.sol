//SPDX-License-Identifier: MIT
//Create by evabase.network core team.
pragma solidity ^0.8.0;

library Utils {
    function encodeUints(uint256[] memory _uint)
        internal
        pure
        returns (bytes memory)
    {
        return (abi.encode(_uint));
    }

    function decodeUints(bytes memory data)
        internal
        pure
        returns (uint256[] memory _uint2)
    {
        _uint2 = abi.decode(data, (uint256[]));
    }
}
