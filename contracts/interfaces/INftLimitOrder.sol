//SPDX-License-Identifier: MIT
//Create by Openflow.network core team.
pragma solidity ^0.8.0;

interface INftLimitOrder {
    struct Order {
        address owner; //拥有人
        address assetToken; //资产合约地址
        uint256 amount; //NFT数量
        uint256 price; //NFT价格
        uint256 deadline; //订单过期时间 s
        uint256 tokenId;
        uint256 salt; //随机数
    }
    struct OrderExist {
        address owner; //   slot 0   order owner
        uint96 balance; //  slot 0  order eth balance
        uint8 amount; //    slot 1    dealed nft amount
        uint64 deadline; // slot 1 order expired time
    }
    event OrderExecuted(address indexed user, bytes32 orderId, uint256 amount, uint256 value);

    event OrderCancelled(address indexed user, bytes32 orderId);

    event OrderCreated(address indexed user, uint256 indexed flowId, Order order);

    function createOrder(Order memory order, uint256 flowId) external payable returns (bytes32 orderId);

    function cancelOrder(bytes32 orderId) external;
}
