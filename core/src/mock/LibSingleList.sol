// SPDX-License-Identifier: GPL-2.0-or-later
// Copy from https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/TransferHelper.sol
pragma solidity ^0.8.0;

library LibSingleList {
    address private constant NULL = address(0);
    struct ListNode {
        address nextNode;
        bool exist;
        uint16 count;
    }
    struct List {
        mapping(address => ListNode) data;
        address header;
        address tail;
        uint256 size;
    }

    struct Iterate {
        address value;
        address prevNode;
    }

    function pushBack(List storage self, address ele) internal {
        pushBack(self, ele, 0);
    }

    function pushBack(
        List storage self,
        address ele,
        uint16 _count
    ) internal {
        require(!self.data[ele].exist, "the element is already exists");
        if (self.size == 0) {
            addFirstNode(self, ele, _count);
        } else {
            self.data[ele] = ListNode({
                nextNode: NULL,
                exist: true,
                count: _count
            });
            self.data[self.tail].nextNode = ele;
            self.tail = ele;
        }

        self.size++;
    }

    function pushFront(List storage self, address ele) internal {
        pushFront(self, ele, 0);
    }

    function pushFront(
        List storage self,
        address ele,
        uint16 _count
    ) internal {
        require(!self.data[ele].exist, "the element is already exists");
        if (self.size == 0) {
            addFirstNode(self, ele);
        } else {
            self.data[ele] = ListNode({
                nextNode: self.header,
                exist: true,
                count: _count
            });
            self.header = ele;
        }
        self.size++;
    }

    //删除一个元素 o(n)
    function remove(List storage self, address ele) internal {
        Iterate memory iter = find(self, ele);
        if (iter.value != NULL) {
            remove(self, iter);
        }
    }

    //查找 o(n)
    function find(List storage self, address ele)
        internal
        returns (Iterate memory)
    {
        require(self.data[ele].exist, "the node is not exists");
        address prev = NULL;
        address beg = self.header;
        while (beg != NULL) {
            if (beg == ele) {
                Iterate memory iter = Iterate({value: ele, prevNode: prev});
                return iter;
            }
            prev = beg;
            beg = self.data[beg].nextNode;
        }
        return Iterate({value: NULL, prevNode: NULL});
    }

    function remove(List storage self, Iterate memory iter)
        internal
        returns (Iterate memory)
    {
        require(self.data[iter.value].exist, "the node is not exists");
        Iterate memory nextIter = Iterate({
            value: self.data[iter.value].nextNode,
            prevNode: iter.prevNode
        });
        if (iter.prevNode == NULL) {
            self.header = self.data[iter.value].nextNode;
        } else {
            self.data[iter.prevNode].nextNode = self.data[iter.value].nextNode;
        }
        delete self.data[iter.value];
        if (self.header == NULL) {
            self.tail = NULL;
        }
        self.size--;
        return nextIter;
    }

    function insertNext(
        List storage self,
        Iterate memory iter,
        address ele
    ) internal {
        insertNext(self, iter, ele, 0);
    }

    function insertNext(
        List storage self,
        Iterate memory iter,
        address ele,
        uint16 _count
    ) internal {
        require(self.data[iter.value].exist, "the node is not exists");
        address next = self.data[iter.value].nextNode;
        self.data[ele] = ListNode({nextNode: next, exist: true, count: _count});
        self.data[iter.value].nextNode = ele;
        if (self.tail == iter.value) {
            self.tail = ele;
        }
        self.size++;
    }

    function insertOrder(
        List storage self,
        address ele,
        uint16 _count
    ) internal {
        require(ele != address(0), "address is 0x");

        if (isExists(self, ele)) {
            remove(self, ele);
        }
        Iterate memory beg = begin(self);
        while (!isEnd(self, beg)) {
            if (self.data[beg.value].count >= _count) {
                //插入节点
                insertPrev(self, beg, ele, _count);
                return;
            } else {
                beg = nextNode(self, beg);
            }
        }
        pushBack(self, ele, _count);
    }

    function insertPrev(
        List storage self,
        Iterate memory iter,
        address ele,
        uint16 _count
    ) internal {
        require(self.data[iter.value].exist, "the node is not exists");
        self.data[ele] = ListNode({
            nextNode: iter.value,
            exist: true,
            count: _count
        });
        if (self.header == iter.value) {
            self.header = ele;
        } else {
            require(
                self.data[iter.prevNode].exist,
                "the prev node is not exists"
            );
            self.data[iter.prevNode].nextNode = ele;
        }
        self.size++;
    }

    function insertPrev(
        List storage self,
        Iterate memory iter,
        address ele
    ) internal {
        insertPrev(self, iter, ele, 0);
    }

    function addFirstNode(List storage self, address ele) private {
        addFirstNode(self, ele, 0);
    }

    function addFirstNode(
        List storage self,
        address ele,
        uint16 _count
    ) private {
        ListNode memory node = ListNode({
            nextNode: NULL,
            exist: true,
            count: _count
        });
        self.data[ele] = node;
        self.header = ele;
        self.tail = ele;
    }

    function getBack(List storage self) internal returns (address) {
        require(self.size > 0, "the list is empty");
        return self.tail;
    }

    function getFront(List storage self) internal returns (address) {
        require(self.size > 0, "the list is empty");
        return self.header;
    }

    function getSize(List storage self) internal view returns (uint256) {
        return self.size;
    }

    function isEmpty(List storage self) internal view returns (bool) {
        return self.size == 0;
    }

    function isExists(List storage self, address ele)
        internal
        view
        returns (bool)
    {
        return self.data[ele].exist && ele != NULL;
    }

    function begin(List storage self) internal view returns (Iterate memory) {
        Iterate memory iter = Iterate({value: self.header, prevNode: NULL});
        return iter;
    }

    function isEnd(List storage self, Iterate memory iter)
        internal
        view
        returns (bool)
    {
        return iter.value == NULL;
    }

    function nextNode(List storage self, Iterate memory iter)
        internal
        view
        returns (Iterate memory)
    {
        require(self.data[iter.value].exist, "the node is not exists");
        Iterate memory nextIter = Iterate({
            value: self.data[iter.value].nextNode,
            prevNode: iter.value
        });
        return nextIter;
    }

    function getTop(List storage self, uint256 _num)
        internal
        view
        returns (address[] memory arr)
    {
        if (_num == 0) {
            return arr;
        }
        uint256 top = 0;
        bool isOverSize = getSize(self) < _num;
        if (isOverSize) {
            top = getSize(self);
        } else {
            top = _num;
        }

        arr = new address[](top);

        Iterate memory beg = begin(self);
        uint16 i = 0;
        while (!isEnd(self, beg)) {
            arr[i++] = beg.value;
            if (!isOverSize && top <= i) {
                return arr;
            }
            beg = nextNode(self, beg);
        }

        return arr;
    }

    function getIndex(List storage self, uint256 _index)
        internal
        view
        returns (address arr)
    {
        if (_index == 0) {
            return arr;
        }

        bool isOverSize = getSize(self) < _index;
        if (!isOverSize) {
            Iterate memory beg = begin(self);
            uint16 i = 1;
            while (!isEnd(self, beg)) {
                if (_index <= i++) {
                    arr = beg.value;
                    return arr;
                }

                beg = nextNode(self, beg);
            }
        }

        return arr;
    }
}
