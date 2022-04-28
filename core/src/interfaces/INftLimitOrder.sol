//SPDX-License-Identifier: MIT
//Create by Openflow.network core team.
pragma solidity ^0.8.0;

interface INftLimitOrder {
    struct Order {
        address owner; //拥有人
        address assetToken; //资产合约地址
        uint256 amount; //NFT数量
        uint256 price; //NFT价格
        uint256 expireTime; //订单过期时间 s
        uint256 tokenId;
        uint256 salt; //随机数
    }
    struct OrderExist {
        // bool exist; //是否存在
        uint8 amount; //已购NFT数量
        address owner; //  msg.sender== safes(owner)
        uint96 balance; //可提取金额
    }
    event OrderExecute(
        address indexed user,
        // Order order,
        bytes32 orderId,
        uint256 amount,
        uint256 value
    );

    event OrderCancel(
        address indexed user,
        uint256 indexed flowId,
        bytes32 orderId
    );

    event OrderPause(
        address indexed user,
        uint256 indexed flowId,
        bytes32 orderId
    );
    event OrderStart(
        address indexed user,
        uint256 indexed flowId,
        bytes32 orderId
    );
    event OrderCreated(
        address indexed user,
        uint256 indexed flowId,
        bytes32 orderId
    );

    function createOrder(Order memory order, uint256 flowId)
        external
        payable
        returns (bytes32 orderId);

    function changeStatus(
        bytes32 orderId,
        bool pause,
        uint256 flowId
    ) external;

    function cancelOrder(bytes32 orderId, uint256 flowId) external;
}
