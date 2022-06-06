//SPDX-License-Identifier: MIT
//Create by evabase.network core team.
/* solhint-disable */

pragma solidity ^0.8.0;

library MathConv {
    function toU120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "to120-overflow");
        return uint120(value);
    }

    function toU96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "to96-overflow");
        return uint96(value);
    }

    function toU64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "to64-overflow");
        return uint64(value);
    }

    function toU8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "to8-overflow");
        return uint8(value);
    }
}
