//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity ^0.8.0;

contract BatchCall {
    struct Call {
        address target;
        uint256 value;
        bytes input;
    }

    function batchCall(Call[] memory calls) external payable returns (bytes[] memory ret) {
        require(calls.length > 0, "invalid length");
        ret = new bytes[](calls.length);
        for (uint256 i = 0; i < calls.length; i++) {
            require(calls[i].target != address(0), "invalid address");
            (bool success, bytes memory returndata) = calls[i].target.call{value: calls[i].value}(calls[i].input);
            if (!success) {
                if (returndata.length > 0) {
                    // The easiest way to bubble the revert reason is using memory via assembly
                    assembly {
                        let returndata_size := mload(returndata)
                        revert(add(32, returndata), returndata_size)
                    }
                } else {
                    revert("F");
                }
            }
            ret[i] = returndata;
        }
    }
}
