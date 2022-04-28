//SPDX-License-Identifier: MIT
//Create by evabase.network core team.
pragma solidity ^0.8.0;

library Utils {
    function _decodeUints(bytes memory data) internal pure returns (uint256[] memory _arr) {
        _arr = abi.decode(data, (uint256[]));
    }

    function _decodeTwoArr(bytes memory data) internal pure returns (uint256[] memory _arr, bytes[] memory _bytes) {
        (_arr, _bytes) = abi.decode(data, (uint256[], bytes[]));
    }

    function _decodeUintAndBytes(bytes memory data) internal pure returns (bytes memory _byte, uint256 _arr) {
        (_byte, _arr) = abi.decode(data, (bytes, uint256));
    }

    function _encodeTwoArr(uint256[] memory _uint, bytes[] memory _bytes) internal pure returns (bytes memory) {
        return (abi.encode(_uint, _bytes));
    }

    function hashCompareInternal(bytes memory a, bytes memory b) internal returns (bool) {
        return keccak256(a) == keccak256(b);
    }

    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 224 bits");
        return uint120(value);
    }

    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }
}
