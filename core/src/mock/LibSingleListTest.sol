pragma solidity ^0.8.0;
import "./LibSingleList.sol";
import "./Utils.sol";

contract LibSingleListTest {
    using LibSingleList for LibSingleList.List;
    using LibSingleList for LibSingleList.Iterate;
    LibSingleList.List _list;

    event log(address data);

    function testInit1() public returns (address[] memory arr) {
        address a1 = 0x83b61Abd789bBA9CDBeF56dAD18D6F2d1E826406;
        address a2 = 0xe847e5C9E13441adE8999D506422BED0f3545456;
        address a3 = 0x2079812353E2C9409a788FBF5f383fa62aD85bE8;
        address a4 = 0x43B12dA984315636F6Dd49B0d6c68e03e3f03b14;
        address a5 = 0x6529ea9109ba664D6eFd8EAa3a4a0B1202F77615;
        _list.pushBack(a1);
        _list.pushBack(a2);
        _list.pushFront(a3);
        require(_list.getSize() == 3, "List size error");

        require(_list.getFront() == a3, "Front node error");
        require(_list.getBack() == a2, "back node error");

        LibSingleList.Iterate memory iter = _list.find(a1);
        require(iter.value == a1, "find error");
        require(iter.prevNode == a3, "list error");
        LibSingleList.Iterate memory next = _list.nextNode(iter);
        require(next.value == a2, "nextNode error");

        _list.remove(a3);
        require(_list.getSize() == 2, "List size error");

        LibSingleList.Iterate memory curr = _list.find(a1);
        _list.insertNext(curr, a4);
        _list.insertPrev(curr, a5);

        require(_list.getFront() == a5, "insert Front node error");
        require(_list.getBack() == a2, " insert  back node error");
        require(_list.getSize() == 4, "List size error");

        LibSingleList.Iterate memory beg = _list.begin();

        while (!_list.isEnd(beg)) {
            emit log(beg.value);

            beg = _list.nextNode(beg);
        }

        return arr;
    }

    event log2(address data, uint16 count);

    function testInit2() public {
        //3-->1-->0xe847e5C9E13441adE8999D506422BED0f3545456

        address a2 = 0xe847e5C9E13441adE8999D506422BED0f3545456;
        _list.insertOrder(a2, 2);
        address a3 = 0x2079812353E2C9409a788FBF5f383fa62aD85bE8;
        address a4 = 0x43B12dA984315636F6Dd49B0d6c68e03e3f03b14;
        address a5 = 0x6529ea9109ba664D6eFd8EAa3a4a0B1202F77615;
        address a1 = 0x83b61Abd789bBA9CDBeF56dAD18D6F2d1E826406;

        _list.insertOrder(a1, 1);
        _list.insertOrder(a4, 4);
        _list.insertOrder(a5, 5);
        _list.insertOrder(a3, 3);

        LibSingleList.Iterate memory beg = _list.begin();

        while (!_list.isEnd(beg)) {
            emit log2(beg.value, _list.data[beg.value].count);

            beg = _list.nextNode(beg);
        }
    }

    function testRemove(address a) public {
        _list.remove(a);

        LibSingleList.Iterate memory beg = _list.begin();

        while (!_list.isEnd(beg)) {
            emit log2(beg.value, _list.data[beg.value].count);

            beg = _list.nextNode(beg);
        }
    }

    function testInsertOrder(address a, uint16 _count) public {
        _list.insertOrder(a, _count);

        LibSingleList.Iterate memory beg = _list.begin();

        while (!_list.isEnd(beg)) {
            emit log2(beg.value, _list.data[beg.value].count);

            beg = _list.nextNode(beg);
        }
    }

    function getsize() public view returns (uint256) {
        return _list.getSize();
    }

    function getTop(uint16 _count) public view returns (address[] memory arr) {
        return _list.getTop(_count);
    }

    function getIndex(uint16 _count) public view returns (address arr) {
        return _list.getIndex(_count);
    }

    function testMath(
        uint256 allVaildSize,
        uint256 keepBotSize,
        uint256 keepbotId,
        uint32 batch
    ) public view returns (uint256[] memory arr) {
        (uint256 start, uint256 end) = Utils.getAvail(
            allVaildSize,
            keepBotSize,
            keepbotId,
            batch
        );

        arr = new uint256[](2);
        arr[0] = start;
        arr[1] = end;
    }
}
