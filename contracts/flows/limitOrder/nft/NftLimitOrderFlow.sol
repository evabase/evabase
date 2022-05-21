// SPDX-License-Identifier: GPL-2.0-or-later
// Copy from https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/TransferHelper.sol
pragma solidity ^0.8.0;
import "../../../interfaces/IEvaFlow.sol";
import "../../../interfaces/EIP712.sol";
import "../../../lib/Utils.sol";
import "../../../interfaces/INftLimitOrder.sol";
import {IEvabaseConfig} from "../../../interfaces/IEvabaseConfig.sol";
import {IEvaSafes} from "../../../interfaces/IEvaSafes.sol";
import {IEvaFlowController} from "../../../interfaces/IEvaFlowController.sol";
import {IEvaSafesFactory} from "../../../interfaces/IEvaSafesFactory.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract NftLimitOrderFlow is IEvaFlow, INftLimitOrder, EIP712, Ownable {
    using Address for address;

    bytes32 private constant _ORDER_TYPEHASH =
        keccak256(
            "Order(address owner,address assetToken,uint256 amount,uint256 price,uint256 deadline,uint256 tokenId,uint256 salt)"
        );
    IEvaSafesFactory public evaSafesFactory;
    IEvabaseConfig public config;
    address private _owner;

    mapping(bytes32 => OrderExist) public orderExists;

    constructor(
        address _config,
        address _evaSafesFactory,
        string memory name,
        string memory version
    ) {
        require(_evaSafesFactory != address(0), "addess is 0x");
        require(_config != address(0), "addess is 0x");
        config = IEvabaseConfig(_config);
        evaSafesFactory = IEvaSafesFactory(_evaSafesFactory);
        init(name, version);
    }

    function check(bytes memory) external view override returns (bool, bytes memory) {
        revert("No support check");
    }

    function multicall(address target, bytes memory callData) external override onlyOwner {
        require(target != address(this), "FORBIDDEN");
        require(target != owner(), "FORBIDDEN");
        target.functionCall(callData, "Multicall CallFailed");
        return;
    }

    function setFactory(address factory) external onlyOwner {
        evaSafesFactory = IEvaSafesFactory(factory);
    }

    function execute(bytes memory executeData) external override returns (bool canDestoryFlow) {
        (Order memory order, bytes memory signature, bytes[] memory data) = abi.decode(
            executeData,
            (Order, bytes, bytes[])
        );
        canDestoryFlow = _atomicMatch(order, signature, data);
    }

    function createOrder(Order memory order, uint256 flowId) external payable override returns (bytes32 orderId) {
        require(msg.sender == evaSafesFactory.get(order.owner), "only safes can creat order");

        require(order.amount > 0, "invalid order.amount");
        require(order.price > 0, "invalid order.price");

        require(order.assetToken != address(0), "invalid order.assetToken");
        require(order.deadline > block.timestamp, "invalid order.deadline"); //solhint-disable

        uint256 totalOrder = order.amount * order.price;
        uint256 total = msg.value;
        require(total >= totalOrder, "invalid msg value");

        orderId = hashOrder(order);
        require(orderExists[orderId].owner == address(0), "order exist");

        orderExists[orderId] = OrderExist({
            amount: 0,
            owner: order.owner,
            balance: Utils.toUint96(total),
            deadline: Utils.toUint64(order.deadline)
        });

        emit OrderCreated(msg.sender, flowId, order);
    }

    function cancelOrder(bytes32 orderId) public override {
        OrderExist storage orderExist = orderExists[orderId];
        require(orderExist.owner != address(0), "order not exist");

        if (msg.sender != evaSafesFactory.get(orderExist.owner)) {
            require(orderExpired(orderId), "order is active");
        }
        uint256 remain = orderExist.balance;
        address user = orderExist.owner;
        delete orderExists[orderId];
        if (remain > 0) {
            (bool succeed, ) = user.call{value: remain}(""); //solhint-disable
            require(succeed, "Failed to transfer Ether");
        }
        emit OrderCancel(msg.sender, orderId);
    }

    function needClose(bytes memory orderIdData) external view override returns (bool yes) {
        bytes32 orderId = abi.decode(orderIdData, (bytes32));
        yes = orderExpired(orderId);
    }

    function close(bytes memory orderIdData) external override {
        bytes32 orderId = abi.decode(orderIdData, (bytes32));
        cancelOrder(orderId);
    }

    function _atomicMatch(
        Order memory _order,
        bytes memory _signature,
        bytes[] memory _data
    ) internal returns (bool orderDone) {
        require(verifyOrder(_order, _signature), "signature is not valid");
        bytes32 orderId = hashOrder(_order);
        OrderExist storage orderExist = orderExists[orderId];
        require(orderExist.owner != address(0), "order not exist");
        require(_order.owner != address(0), "order owner addrss is 0x");
        uint256 _amount = _order.amount;
        require(_amount > 0, "execute amount gt 0");

        require(_order.deadline >= block.timestamp, "order time is end"); //solhint-disable
        require(msg.sender == evaSafesFactory.get(orderExist.owner), "should exected by safes");

        uint256 total = 0;

        require(_data.length <= _order.amount - orderExist.amount, "Exceeded purchase");

        for (uint256 i = 0; i < _data.length; i++) {
            (address target, bytes memory input, uint256 value) = abi.decode(_data[i], (address, bytes, uint256));
            require(target != address(this), "FORBIDDEN");
            require(target != msg.sender, "FORBIDDEN");
            target.functionCallWithValue(input, value, "CallFailed");

            total += value;
        }

        //Increase in the number of completed purchases
        orderExist.amount = Utils.toUint8(_data.length) + orderExist.amount;
        //Decrease in funds deposited for purchases
        uint96 totalUsed = Utils.toUint96(total);
        require(orderExist.balance >= totalUsed, "invalid balance");
        orderExist.balance = orderExist.balance - totalUsed;

        orderDone = orderExist.amount == _order.amount;
        if (orderDone) {
            uint256 bal = orderExist.balance;
            if (bal > 0) {
                (bool succeed, ) = orderExist.owner.call{value: bal}(""); //solhint-disable
                require(succeed, "Failed to transfer Ether");
            }
            delete orderExists[orderId];
        }
        emit OrderExecute(msg.sender, orderId, _data.length, total);
    }

    function hashOrder(Order memory order) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode( // order
                    _ORDER_TYPEHASH,
                    order.owner,
                    order.assetToken,
                    order.amount,
                    order.price,
                    order.deadline,
                    order.tokenId,
                    order.salt
                )
            );
    }

    function verifyOrder(Order memory order, bytes memory signature) public view returns (bool) {
        bytes32 messageHash = hashOrder(order);

        bytes32 ethSignedMessageHash = _hashTypedDataV4(messageHash);

        return SignatureChecker.isValidSignatureNow(order.owner, ethSignedMessageHash, signature);
    }

    function orderExpired(bytes32 orderId) public view returns (bool) {
        // solhint-disable
        uint256 deadline = orderExists[orderId].deadline;
        return deadline > 0 && deadline < block.timestamp;
    }

    /**
    @dev can receive ETH, owner can refund.
   */
    receive() external payable {} //solhint-disable
}
