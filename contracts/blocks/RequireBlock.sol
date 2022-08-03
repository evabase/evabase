//SPDX-License-Identifier: MIT
//Create by Openflow.network core team.
pragma solidity ^0.8.0;

contract RequireBlock {
    /**
     *GreaterThan:greater than
     *LessThan:less than
     *GreaterThanOrEqual:equal or greater than
     *LessThanOrEqual:equal or less than
     *Equal:equal
     *NotEqual:Not equal
     */
    enum Operator {
        GreaterThan,
        LessThan,
        GreaterThanOrEqual,
        LessThanOrEqual,
        Equal,
        NotEqual
    }

    enum CallWay {
        Call,
        StaticCall,
        Const
    }

    /// @notice core function Testing if the status is as expected
    /// @dev  can exec for anyone.
    /// @param expression The expression parameter is an expression encoding information that sets how A and B will be compared
    function exec(bytes calldata expression) external {
        //67 length
        require(expression.length > 47, "invalid length");
        //head
        // (uint8 op, uint8 wayA, uint8 wayB) = BytesLib.headConv(expression);
        uint8 op = uint8(expression[0]);
        uint8 wayA = uint8(expression[1]);
        uint8 wayB = uint8(expression[2]);
        require(wayA < 3 && wayB < 3 && op < 6, "invalid head");
        (bytes32 valueA, uint256 index) = valueConv(expression, wayA, 3);

        (bytes32 valueB, uint256 end) = valueConv(expression, wayB, index);

        require(end == expression.length, "invalid end");

        if (op == uint8(Operator.GreaterThan)) {
            require(valueA > valueB, "!>");
        } else if (op == uint8(Operator.LessThan)) {
            require(valueA < valueB, "!<");
        } else if (op == uint8(Operator.GreaterThanOrEqual)) {
            require(valueA >= valueB, "!>=");
        } else if (op == uint8(Operator.LessThanOrEqual)) {
            require(valueA <= valueB, "!<=");
        } else if (op == uint8(Operator.Equal)) {
            require(valueA == valueB, "!==");
        } else if (op == uint8(Operator.NotEqual)) {
            require(valueA != valueB, "!!=");
        } else {
            revert("invalid Op");
        }
    }

    ///expression->A/B Calculation results
    function valueConv(
        bytes calldata expression,
        uint8 way,
        uint256 start
    ) public returns (bytes32 ret, uint256 index) {
        if (way == uint8(CallWay.Const)) {
            bytes calldata originalValue = expression[start:start + 32];
            ret = _toBytes32(originalValue, 0);
            index = start + 32;
        } else {
            address dst = _toAddress(expression[start:20 + start], 0);
            // BytesLib.sub(expression, start, 20), 0);
            index = start + 20;
            uint16 len = _toUint16(expression[index:index + 2], 0);
            // uint16 len = BytesLib._toUint16(BytesLib.sub(expression, index, 2), 0);
            index += 2;
            bytes memory data = expression[index:index + len];
            //  BytesLib.sub(expression, index, len);
            index += len;
            bool success;
            bytes memory returndata;
            if (way == uint8(CallWay.Call)) {
                (success, returndata) = dst.call{value: 0}(data);
            } else if (way == uint8(CallWay.StaticCall)) {
                (success, returndata) = dst.staticcall(data);
            } else {
                revert("invalid way");
            }

            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                // solhint-disable reason-string
                if (returndata.length < 68) revert();
                // solhint-disable no-inline-assembly
                assembly {
                    returndata := add(returndata, 0x04)
                }
                revert(abi.decode(returndata, (string)));
            } else {
                ret = _toBytes32(returndata, 0);
            }
        }
    }

    function _toBytes32(bytes memory _bytes, uint256 _start) internal pure returns (bytes32) {
        bytes32 tempBytes32;

        assembly {
            tempBytes32 := mload(add(add(_bytes, 0x20), _start))
        }

        return tempBytes32;
    }

    function _toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }

    function _toUint16(bytes memory _bytes, uint256 _start) internal pure returns (uint16) {
        uint16 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x2), _start))
        }

        return tempUint;
    }
}
