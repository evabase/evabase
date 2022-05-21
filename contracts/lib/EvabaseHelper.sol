//SPDX-License-Identifier: MIT
//Create by evabase.network core team.
pragma solidity ^0.8.0;

enum CompareOperator {
    Eq,
    Ne,
    Ge,
    Gt,
    Le,
    Lt
}

enum FlowStatus {
    Active, //可执行
    Closed,
    Expired,
    Completed,
    Unknown
}

enum KeepNetWork {
    ChainLink,
    Evabase,
    Gelato,
    Others
}

library EvabaseHelper {
    struct UintSet {
        // value ->index value !=0
        mapping(uint256 => uint256) indexMapping;
        uint256[] values;
    }

    function add(UintSet storage self, uint256 value) internal {
        require(value != uint256(0), "value=0");
        require(!contains(self, value), "value exists");
        self.values.push(value);
        self.indexMapping[value] = self.values.length;
    }

    function contains(UintSet storage self, uint256 value) internal view returns (bool) {
        return self.indexMapping[value] != 0;
    }

    function remove(UintSet storage self, uint256 value) internal {
        require(contains(self, value), "value doesn't exist");
        uint256 toDeleteindexMapping = self.indexMapping[value] - 1;
        uint256 lastindexMapping = self.values.length - 1;
        uint256 lastValue = self.values[lastindexMapping];
        self.values[toDeleteindexMapping] = lastValue;
        self.indexMapping[lastValue] = toDeleteindexMapping + 1;
        delete self.indexMapping[value];
        // self.values.length--;
        self.values.pop();
    }

    function getSize(UintSet storage self) internal view returns (uint256) {
        return self.values.length;
    }

    function get(UintSet storage self, uint256 index) internal view returns (uint256) {
        return self.values[index];
    }

    function getAll(UintSet storage self) internal view returns (uint256[] memory) {
        // uint256[] memory output = new uint256[](self.values.length);
        // for (uint256 i; i < self.values.length; i++) {
        //     output[i] = self.values[i];
        // }
        return self.values;
    }

    function toBytes(uint256 x) internal pure returns (bytes memory b) {
        b = new bytes(32);
        // solhint-disable no-inline-assembly
        assembly {
            mstore(add(b, 32), x)
        }
    }

    function getRange(
        UintSet storage self,
        uint256 fromIndex,
        uint256 endIndex
    ) internal view returns (uint256[] memory) {
        require(fromIndex <= endIndex, "fromIndex gt endIndex");
        require(endIndex <= self.values.length, "endIndex exceed bound");
        uint256[] memory output = new uint256[](endIndex - fromIndex);
        uint256 j = 0;
        for (uint256 i = fromIndex; i < endIndex; i++) {
            output[j++] = self.values[i];
        }
        return output;
    }
}
