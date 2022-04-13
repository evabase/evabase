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

    function _decodeUints(bytes memory data)
        internal
        pure
        returns (uint256[] memory _arr)
    {
        _arr = abi.decode(data, (uint256[]));
    }

    function _encodeTwoArr(uint256[] memory _uint, bytes[] memory _bytes)
        internal
        pure
        returns (bytes memory)
    {
        return (abi.encode(_uint, _bytes));
    }

    function _decodeTwoArr(bytes memory data)
        internal
        pure
        returns (uint256[] memory _arr, bytes[] memory _bytes)
    {
        (_arr, _bytes) = abi.decode(data, (uint256[], bytes[]));
    }

    function _encodeUintAndBytes(uint256 _value, bytes memory _bytes)
        internal
        pure
        returns (bytes memory)
    {
        return (abi.encode(_value, _bytes));
    }

    function _decodeUintAndBytes(bytes memory data)
        internal
        pure
        returns (uint256 _arr, bytes memory _byte)
    {
        (_arr, _byte) = abi.decode(data, (uint256, bytes));
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) internal pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }

        // implicitly return (r, s, v)
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        internal
        pure
        returns (bytes32)
    {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }
}
