//SPDX-License-Identifier: MIT
//Create by Openflow.network core team.
pragma solidity ^0.8.0;

import "./interfaces/IStrategy.sol";
import "../../lib/TransferHelper.sol";
import {Order} from "./interfaces/ILOBExchange.sol";

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @notice Core contract used to create, cancel and execute orders.
contract LOB is Ownable {
    using SafeMath for uint256;
    using Address for address;
    using SafeERC20 for IERC20;
    // using Fabric for bytes32;

    uint256 private constant _FEE_UNIT = 10000;
    uint256 private constant _ORDER_MIN_AGE = 9 minutes;
    uint256 private constant _ORDER_MAX_AGE = 90 days;
    mapping(bytes32 => Order) private _orders;
    mapping(bytes32 => OrderStatus) private _orderStatus;

    Config public config;
    struct Config {
        bool paused;
        uint64 basisPointsRate;
        address feeTo;
    }

    struct OrderStatus {
        uint96 balance;
        bool paused;
    }

    event OrderCreated(bytes32 indexed orderId, address indexed owner, uint256 fee);
    event OrderExecuted(bytes32 indexed orderId, uint256 input, uint256 output);
    event OrderCancelled(bytes32 indexed orderId, uint256 returnAmount);
    event OrderPaused(bytes32 indexed orderId, bool paused);
    event ConfigChanged(Config newConfig);

    constructor(Config memory cfg) {
        setConfig(cfg);
    }

    /**
      @notice create order
      @dev sender can create order for anyone.
      rule:
      1. can't repeat create same order.
      2. creation fee charged, but capped.
      3. will transfer sell token to here.
     */
    function createOrder(Order memory order) public payable onlyRunning returns (bytes32 orderId) {
        orderId = keyOf(order);

        require(order.owner == msg.sender, "WRONG_INPUT_OWNER");
        require(
            order.deadline >= block.timestamp + _ORDER_MIN_AGE && //solhint-disable  not-rely-on-time
                order.deadline <= block.timestamp + _ORDER_MAX_AGE, //solhint-disable  not-rely-on-time
            "WRONG_EXPIRATION"
        );
        require(order.minInputPer <= order.inputAmount, "WRONG_INPUT_AMOUNT");
        require(_orders[orderId].owner == address(0), "ORDER_EXIST");

        (address feeTo, uint256 fee) = getFee(order.inputAmount);

        // save order info
        _orders[orderId] = order;
        _orderStatus[orderId].balance = order.inputAmount - uint96(fee);

        // transfer order amount to here include fee.
        if (order.inputToken == TransferHelper.ETH_ADDRESS) {
            require(msg.value == order.inputAmount, "WRONG_INPUT_AMOUNT");
        } else {
            TransferHelper.safeTransferFrom(order.inputToken, msg.sender, address(this), order.inputAmount);
        }

        if (fee > 0) {
            // feeTo never empty
            TransferHelper.safeTransferTokenOrETH(order.inputToken, feeTo, fee);
        }
        emit OrderCreated(orderId, order.owner, fee);
    }

    /**
     * @notice Cancel order
     * @dev
     *   1. order can be closed by order owner on any time.
     *   2. any one can close order when order has expired.
     */
    function closeOrder(bytes32 orderId) public {
        Order memory order = _orders[orderId];
        address orderOwner = order.owner;
        if (orderOwner != msg.sender) {
            require(orderExpired(orderId), "order is active");
        }
        uint256 balance = _orderStatus[orderId].balance; //  balance may be zero.
        delete _orderStatus[orderId];

        TransferHelper.safeTransferTokenOrETH(
            order.inputToken,
            order.receiptor == address(0) ? orderOwner : order.receiptor,
            balance
        );
        emit OrderCancelled(orderId, balance);
    }

    function setPause(bytes32 orderId, bool pause) external onlySeller(orderId) {
        require(_orderStatus[orderId].paused != pause, "INVALID_STATUS");
        _orderStatus[orderId].paused = pause;
        emit OrderPaused(orderId, pause);
    }

    /**
     * @notice Executes an order
     * @dev it can be called by anyone
     */
    function executeOrder(
        bytes32 orderId,
        IStrategy strategy,
        uint256 input,
        bytes memory data
    ) public onlyRunning returns (uint256 output, uint256 orderBalance) {
        Order memory order = _orders[orderId];
        require(isActiveOrder(orderId), "ORDER_NOT_ACTIVE");

        // check input
        uint256 balance = _orderStatus[orderId].balance;
        uint256 minInput = balance <= order.minInputPer ? balance : order.minInputPer;
        require(input >= minInput, "ORDER_INPUT_LESS");

        // Pull amount to strategy
        _transferOutBalance(orderId, address(strategy), input);

        uint256 before = TransferHelper.balanceOf(order.outputToken, address(this));
        strategy.execute(order.inputToken, order.outputToken, data);
        output = TransferHelper.balanceOf(order.outputToken, address(this)).sub(before);

        // check bought
        uint256 expect = input.mul(order.minRate).div(1e18);

        require(output >= expect, "ORDER_OUTPUT_LESS");

        // pull bought to receiptor
        TransferHelper.safeTransferTokenOrETH(
            order.outputToken,
            order.receiptor != address(0) ? order.receiptor : order.owner,
            output
        );
        orderBalance = _orderStatus[orderId].balance;
        emit OrderExecuted(orderId, input, output);
    }

    function getOrderInfo(bytes32 orderId) public view returns (Order memory order, OrderStatus memory status) {
        order = _orders[orderId];
        status = _orderStatus[orderId];
    }

    function isActiveOrder(bytes32 orderId) public view returns (bool) {
        OrderStatus memory status = _orderStatus[orderId];
        //solhint-disable  not-rely-on-time
        return !status.paused && status.balance > 0 && _orders[orderId].deadline >= block.timestamp;
    }

    function orderExpired(bytes32 orderId) public view returns (bool) {
        return _orders[orderId].deadline < block.timestamp && _orderStatus[orderId].balance > 0;
    }

    /**
     * @notice Get the order's orderId
     */
    function keyOf(Order memory o) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    o.owner,
                    o.receiptor,
                    o.inputToken,
                    o.outputToken,
                    o.inputAmount,
                    o.minRate,
                    o.deadline,
                    o.minInputPer
                )
            );
    }

    function getFee(uint96 amountIn) public view returns (address feeTo, uint256 fee) {
        Config memory cfg = config;
        feeTo = cfg.feeTo;

        if (feeTo != address(0)) {
            // fee will always be less then amountIn
            fee = uint256(cfg.basisPointsRate).mul(amountIn).div(_FEE_UNIT);
        }
    }

    function setConfig(Config memory cfg) public onlyOwner {
        config = cfg;
        // safe check
        require(cfg.basisPointsRate < _FEE_UNIT, "INVALID_RATE");
        emit ConfigChanged(cfg);
    }

    function _transferOutBalance(
        bytes32 orderId,
        address to,
        uint256 amount
    ) private {
        uint96 balance = _orderStatus[orderId].balance;
        require(amount <= uint256(balance), "INSUFFICIENT_BALANCE");
        _orderStatus[orderId].balance = balance - uint96(amount);

        TransferHelper.safeTransferTokenOrETH(_orders[orderId].inputToken, to, amount);
    }

    modifier onlyRunning() {
        require(!config.paused, "LOB_PAUSED");
        _;
    }

    modifier onlySeller(bytes32 orderId) {
        require(msg.sender == _orders[orderId].owner, "INVALID_OWNER");
        _;
    }
}
