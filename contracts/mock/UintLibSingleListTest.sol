pragma solidity ^0.8.0;
import "../lib/EvabaseHelper.sol";
import "./Utils.sol";

contract UintLibSingleListTest {
    using EvabaseHelper for EvabaseHelper.UintSet;
    EvabaseHelper.UintSet _list;

    event log(uint256 data);

    event log2(bytes32 data, uint16 count);

    function testRemove(uint256 a) public {
        _list.remove(a);
    }

    function getsize() public view returns (uint256) {
        return _list.getSize();
    }

    function get(uint256 _count) public view returns (uint256 arr) {
        return _list.get(_count);
    }

    function getall() public view returns (uint256[] memory arr) {
        return _list.getAll();
    }

    function getRange(uint256 fromIndex, uint256 endIndex) public view returns (uint256[] memory arr) {
        return _list.getRange(fromIndex, endIndex);
    }

    function add1Value(uint256 value) public {
        _list.add(value);
    }

    function testMath(
        uint256 allVaildSize,
        uint256 keepBotSize,
        uint256 keepbotId,
        uint32 batch
    ) public view returns (uint256[] memory arr) {
        (uint256 start, uint256 end) = Utils.getAvail(allVaildSize, keepBotSize, keepbotId, batch);

        arr = new uint256[](2);
        arr[0] = start;
        arr[1] = end;
    }
}
