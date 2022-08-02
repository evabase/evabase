//SPDX-License-Identifier: MIT
//Create by Openflow.network core team.
pragma solidity ^0.8.0;
import "../lib/BytesLib.sol";

contract RequireBlock {
    /**
     *Gt:greater than
     *Lt:less than
     *EqOrGt:equal or greater than
     *EqOrLt:equal or less than
     *Eq:equal
     *NEq:equal or less than
     */
    enum Operator {
        Gt,
        Lt,
        EqOrGt,
        EqOrLt,
        Eq,
        NEq
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
        (uint8 op, uint8 wayA, uint8 wayB) = BytesLib.headConv(expression);
        require(wayA < 3 && wayB < 3 && op < 6, "invalid head");
        (bytes32 valueA, uint256 index) = valueConv(expression, wayA, 3);

        (bytes32 valueB, uint256 end) = valueConv(expression, wayB, index);

        require(end == expression.length, "invalid end");

        if (op == uint8(Operator.Gt)) {
            require(valueA > valueB, "gt");
        } else if (op == uint8(Operator.Lt)) {
            require(valueA < valueB, "lt");
        } else if (op == uint8(Operator.EqOrGt)) {
            require(valueA >= valueB, "EqOrGt");
        } else if (op == uint8(Operator.EqOrLt)) {
            require(valueA <= valueB, "EqOrLt");
        } else if (op == uint8(Operator.Eq)) {
            require(valueA == valueB, "Eq");
        } else if (op == uint8(Operator.NEq)) {
            require(valueA != valueB, "NEq");
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
            bytes calldata originalValue = BytesLib.sub(expression, start, 32);
            ret = BytesLib.toBytes32(originalValue, 0);
            index = start + 32;
        } else {
            address dst = BytesLib.toAddress(BytesLib.sub(expression, start, 20), 0);
            index = start + 20;
            uint16 len = BytesLib.toUint16(BytesLib.sub(expression, index, 2), 0);
            index += 2;
            bytes memory data = BytesLib.sub(expression, index, len);
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
                ret = BytesLib.toBytes32(returndata, 0);
            }
        }
    }
}
