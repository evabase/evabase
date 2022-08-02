//SPDX-License-Identifier: MIT
//Create by evabase.network core team.
/* solhint-disable */

pragma solidity ^0.8.0;

library BytesLib {
    /// @notice Arbitrary length slice
    function sub(
        bytes calldata v,
        uint256 start,
        uint256 len
    ) internal pure returns (bytes calldata) {
        return v[start:start + len];
    }

    /// @notice Head Transform
    function headConv(bytes calldata v)
        internal
        pure
        returns (
            uint8 a,
            uint8 b,
            uint8 c
        )
    {
        a = uint8(v[0]);
        b = uint8(v[1]);
        c = uint8(v[2]);
        return (a, b, c);
    }

    function toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        require(_bytes.length >= _start + 32, "toBytes32_outOfBounds");
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        require(_bytes.length >= _start + 2, "toUint16_outOfBounds");
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }
}
