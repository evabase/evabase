// SPDX-License-Identifier: GPL-2.0-or-later
// Copy from https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/TransferHelper.sol
pragma solidity ^0.8.0;
import "../../interfaces/IEvaFlow.sol";
import "../../interfaces/EIP712.sol";
import "../../lib/Utils.sol";
import "../../interfaces/INftLimitOrder.sol";
import {IEvabaseConfig} from "../../interfaces/IEvabaseConfig.sol";
import {IEvaSafes} from "../../interfaces/IEvaSafes.sol";
import {IEvaFlowController} from "../../interfaces/IEvaFlowController.sol";
import {IEvaSafesFactory} from "../../interfaces/IEvaSafesFactory.sol";
// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

contract NftLimitOrderFlow is IEvaFlow, INftLimitOrder, EIP712 {
    using AddressUpgradeable for address;

    // struct Order {
    //     address owner; //拥有人
    //     address assetToken; //资产合约地址
    //     uint256 amount; //NFT数量
    //     uint256 price; //NFT价格
    //     uint256 expireTime; //订单过期时间 s
    //     uint256 tokenId;
    //     uint256 salt; //随机数
    // }
    bytes32 constant _ORDER_TYPEHASH =
        keccak256(
            "Order(address owner,address assetToken,uint256 amount,uint256 price,uint256 expireTime,uint256 tokenId,uint256 salt)"
        );
    IEvaSafesFactory public evaSafesFactory;
    IEvabaseConfig public config;
    address private _owner;
    // bool isInitialized;

    // mapping(bytes32 => bool) public orderExist;
    mapping(bytes32 => OrderExist) public orderExists;

    constructor(
        address _config,
        address _evaSafesFactory,
        string memory name,
        string memory version
    ) public {
        // constructor(address _evaSafesFactory) {
        // require(isInitialized == false, "Already initialized");
        require(_evaSafesFactory != address(0), "addess is 0x");
        require(_config != address(0), "addess is 0x");
        // isInitialized = true;
        config = IEvabaseConfig(_config);
        evaSafesFactory = IEvaSafesFactory(_evaSafesFactory);
        _owner = msg.sender;
        init(name, version);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function check(bytes memory checkData) external view override returns (bool needExecute, bytes memory executeData) {
        return (false, checkData);
    }

    function multicall(address target, bytes memory callData) external override {
        require(_owner == msg.sender, "only owner can call this function");
        require(target != address(this), "FORBIDDEN safes address");
        require(target != _owner, "FORBIDDEN self");
        target.functionCall(callData, "CallFailed");
        return;
    }

    function setFactory() external {
        require(_owner == msg.sender, "only owner can call this function");
        evaSafesFactory = IEvaSafesFactory(msg.sender);
    }

    function execute(bytes memory executeData) external override {
        (Order memory order, bytes memory signature, bytes[] memory data) = abi.decode(
            executeData,
            (Order, bytes, bytes[])
        );
        // _atomicMatch(order, signature, data, _assetTokenIds);
        _atomicMatch(order, signature, data);
    }

    function createOrder(Order memory order, uint256 flowId) external payable override returns (bytes32 orderId) {
        require(msg.sender == evaSafesFactory.get(order.owner), "only safes can creat order");

        require(order.amount > 0, "amount must be greater than 0");
        require(order.price > 0, "price must be greater than 0");

        require(order.assetToken != address(0), "assetToken is 0x");
        require(order.expireTime > block.timestamp, "order time is end");

        uint256 total = order.amount * order.price;
        require(total <= msg.value, "order amount*price must be less than or equal to msg.value");

        bytes32 orderId = hashOrder(order);
        require(orderExists[orderId].owner == address(0), "order exist");

        orderExists[orderId] = OrderExist({amount: 0, owner: order.owner, balance: Utils.toUint96(total)});

        emit OrderCreated(msg.sender, flowId, orderId);
        return orderId;
    }

    function changeStatus(
        bytes32 orderId,
        bool pause,
        uint256 flowId
    ) public override {
        // require(
        //     address(0) != evaSafesFactory.get(msg.sender),
        //     "only owner can change status order"
        // );

        OrderExist memory orderExist = orderExists[orderId];
        require(orderExist.owner != address(0), "order not exist");
        require(msg.sender == evaSafesFactory.get(orderExist.owner), "shold be owner");

        if (pause) {
            emit OrderPause(msg.sender, flowId, orderId);
        } else {
            emit OrderStart(msg.sender, flowId, orderId);
        }
    }

    function cancelOrder(bytes32 orderId, uint256 flowId) public override {
        // require(
        //     address(0) != evaSafesFactory.get(msg.sender),
        //     "only owner can cancel order"
        // );

        OrderExist storage orderExist = orderExists[orderId];
        require(orderExist.owner != address(0), "order not exist");
        require(msg.sender == evaSafesFactory.get(orderExist.owner), "shold be owner");
        delete orderExists[orderId];
        uint256 remain = orderExist.balance;
        if (remain > 0) {
            (bool succeed, ) = orderExist.owner.call{value: remain}("");
            require(succeed, "Failed to transfer Ether");
        }

        emit OrderCancel(msg.sender, flowId, orderId);
    }

    function _atomicMatch(
        Order memory _order,
        bytes memory _signature,
        bytes[] memory _data
    ) internal returns (bytes[] memory results) {
        require(verifyOrder(_order, _signature), "signature is not valid");
        bytes32 ordeId = hashOrder(_order);
        OrderExist storage orderExist = orderExists[ordeId];
        require(orderExist.owner != address(0), "order not exist");
        require(_order.owner != address(0), "order owner addrss is 0x");
        uint256 _amount = _order.amount;
        require(_amount > 0, "execute amount gt 0");
        // require(_assetTokenIds.length == _data.length, "length should be same");

        require(_order.expireTime >= block.timestamp, "order time is end");
        require(
            msg.sender == evaSafesFactory.get(msg.sender),
            // msg.sender == evaSafesFactory.calcSafes(_order.owner),
            " should exected by safes"
        );

        uint256 total = 0;

        require(_data.length <= _order.amount - orderExist.amount, "Exceeded purchase");

        results = new bytes[](_data.length);

        for (uint256 i = 0; i < _data.length; i++) {
            (address target, bytes memory input, uint256 value) = abi.decode(_data[i], (address, bytes, uint256));
            require(target != address(this), "FORBIDDEN safes address");
            require(target != msg.sender, "FORBIDDEN self");
            results[i] = target.functionCallWithValue(
                // target,
                input,
                value,
                "CallFailed"
            );
            require(!Utils.hashCompareInternal(results[i], bytes("CallFailed")), "_atomicMatch failed");

            total += value;

            //     if (_order.assetType == AssetType.ERC721) {
            //         IERC721(_order.assetToken).safeTransferFrom(
            //             address(this),
            //             _order.owner,
            //             _assetTokenIds[i]
            //         );
            //     } else if (_order.assetType == AssetType.ERC1155) {}
            //     //withdarw erc721/erc1155
            //     IERC1155(_order.assetToken).safeTransferFrom(
            //         address(this),
            //         _order.owner,
            //         _assetTokenIds[i],
            //         IERC1155(_order.assetToken).balanceOf(
            //             address(this),
            //             _assetTokenIds[i]
            //         ),
            //         ""
            //     );
        }

        orderExist.amount = orderExist.amount - Utils.toUint8(_data.length);

        orderExist.balance = orderExist.balance - Utils.toUint96(total);

        emit OrderExecute(msg.sender, ordeId, _data.length, total);
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
                    order.expireTime,
                    order.tokenId,
                    order.salt
                )
            );
    }

    function verifyOrder(Order memory order, bytes memory signature) public view returns (bool) {
        bytes32 messageHash = hashOrder(order);
        // bytes32 ethSignedMessageHash = Utils.getEthSignedMessageHash(
        //     messageHash
        // );

        bytes32 ethSignedMessageHash = _hashTypedDataV4(messageHash);

        return SignatureChecker.isValidSignatureNow(order.owner, ethSignedMessageHash, signature);
        // return
        //     Utils.recoverSigner(ethSignedMessageHash, signature) == order.owner;
    }

    /**
    @dev can receive ETH, owner can refund.
   */
    receive() external payable {}
}
