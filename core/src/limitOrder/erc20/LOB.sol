//SPDX-License-Identifier: MIT
//Create by Openflow.network core team.
pragma solidity ^0.8.0;

import "../../lib/Constants.sol";
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

    uint256 private constant FEE_UNIT = 10000;
    uint256 private constant ORDER_MIN_AGE = 10 minutes;
    uint256 private constant ORDER_MAX_AGE = 90 days;
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

    event OrderCreated(bytes32 indexed key, uint256 fee);
    event OrderExecuted(bytes32 indexed key, uint256 input, uint256 output);
    event OrderCancelled(bytes32 indexed key, uint256 returnAmount);
    event OrderPaused(bytes32 indexed key, bool paused);
    event ConfigChanged(Config newConfig);

    /**
      @notice create order
      @dev sender can create order for anyone.
      rule:
      1. can't repeat create same order.
      2. creation fee charged, but capped.
      3. will transfer sell token to here.
     */
    function createOrder(Order memory order)
        public
        payable
        onlyRunning
        returns (bytes32 key)
    {
        key = keyOf(order);

        require(order.owner == msg.sender, "WRONG_INPUT_OWNER");
        require(
            order.expiration >= block.timestamp + ORDER_MIN_AGE &&
                order.expiration <= block.timestamp + ORDER_MAX_AGE,
            "WRONG_EXPIRATION"
        );
        require(_orders[key].owner == address(0), "ORDER_EXIST");

        (address feeTo, uint256 fee) = getFee(order.inputAmount);

        // save order info
        _orders[key] = order;
        _orderStatus[key].balance = order.inputAmount - uint96(fee);

        // transfer order amount to here include fee.
        if (order.inputToken == TransferHelper.ETH_ADDRESS) {
            require(msg.value == order.inputAmount, "WRONG_INPUT_AMOUNT");
        } else {
            TransferHelper.safeTransferFrom(
                order.inputToken,
                msg.sender,
                address(this),
                order.inputAmount
            );
        }

        if (fee > 0) {
            // feeTo never empty
            TransferHelper.safeTransferTokenOrETH(order.inputToken, feeTo, fee);
        }

        emit OrderCreated(key, fee);
    }

    /**
     * @notice Cancel order
     */
    function cancelOrder(bytes32 key) public onlySeller(key) {
        uint256 balance = _orderStatus[key].balance;
        _transferOutBalance(key, msg.sender, balance);
        emit OrderCancelled(key, balance);
    }

    function setPause(bytes32 key, bool pause) external onlySeller(key) {
        require(_orderStatus[key].paused != pause, "INVALID_STATUS");
        _orderStatus[key].paused = pause;
        emit OrderPaused(key, pause);
    }

    /**
     * @notice Executes an order
     * @dev it can be called by anyone
     */
    function executeOrder(
        bytes32 key,
        IStrategy strategy,
        uint256 input,
        bytes memory data
    ) public onlyRunning {
        Order memory order = _orders[key];
        require(isActiveOrder(key), "ORDER_NOT_ACTIVE");
        require(order.owner != msg.sender, "ORDER_YOURSELF");
        if (order.foc) {
            // full deal or cancel
            require(input == uint256(_orderStatus[key].balance), "ORDER_FOC");
        }
        // Pull amount to strategy
        _transferOutBalance(key, address(strategy), input);

        uint256 before = TransferHelper.balanceOf(
            order.outputToken,
            address(this)
        );
        strategy.execute(order.inputToken, order.outputToken, data);
        uint256 output = TransferHelper
            .balanceOf(order.outputToken, address(this))
            .sub(before);

        // check bought
        uint256 expect = input.mul(order.minRate).div(1e18);
        require(output >= expect, "ORDER_OUTPUT_LESS");

        // pull bought to receiptor
        TransferHelper.safeTransferTokenOrETH(
            order.outputToken,
            order.receiptor != address(0) ? order.receiptor : order.owner,
            output
        );

        emit OrderExecuted(key, input, output);
    }

    function getOrderInfo(bytes32 key)
        public
        view
        returns (Order memory order, OrderStatus memory status)
    {
        order = _orders[key];
        status = _orderStatus[key];
    }

    function getOrderOwner(bytes32 key) public view returns (address) {
        return _orders[key].owner;
    }

    function isActiveOrder(bytes32 key) public view returns (bool) {
        OrderStatus memory status = _orderStatus[key];
        return
            !status.paused &&
            status.balance > 0 &&
            _orders[key].expiration >= block.timestamp;
    }

    /**
     * @notice Get the order's key
     */
    function keyOf(Order memory o) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    o.owner,
                    o.inputToken,
                    o.outputToken,
                    o.inputAmount,
                    o.minRate,
                    o.expiration,
                    o.extraData
                )
            );
    }

    function getFee(uint96 amountIn)
        public
        view
        returns (address feeTo, uint256 fee)
    {
        Config memory cfg = config;
        feeTo = cfg.feeTo;

        if (feeTo != address(0)) {
            // fee will always be less then amountIn
            fee = uint256(cfg.basisPointsRate).mul(amountIn).div(FEE_UNIT);
        }
    }

    function setConfig(Config calldata cfg) external onlyOwner {
        config = cfg;
        // safe check
        require(cfg.basisPointsRate < FEE_UNIT, "INVALID_RATE");
        emit ConfigChanged(cfg);
    }

    function _transferOutBalance(
        bytes32 key,
        address to,
        uint256 amount
    ) private {
        require(amount < type(uint96).max, "OVERFLOW");
        _orderStatus[key].balance = _orderStatus[key].balance - uint96(amount);
        TransferHelper.safeTransferTokenOrETH(
            _orders[key].inputToken,
            to,
            amount
        );
    }

    modifier onlyRunning() {
        require(!config.paused, "LOB_PAUSED");
        _;
    }

    modifier onlySeller(bytes32 key) {
        require(msg.sender == _orders[key].owner, "INVALID_OWNER");
        _;
    }
}
