//SPDX-License-Identifier: MIT
//Create by Openflow.network core team.
pragma solidity ^0.8.0;

import "../../lib/Constants.sol";
import "../../interfaces/IEvaSafesFactory.sol";
import "./interfaces/IStrategy.sol";
import "../../lib/TransferHelper.sol";

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
    IEvaSafesFactory public immutable safesFactory;
    mapping(bytes32 => Order) private _orders;
    mapping(bytes32 => uint256) private _orderBalance;

    Config public config;

    struct Config {
        bool paused;
        uint64 maximumFee;
        uint64 basisPointsRate;
    }

    enum OrderType {
        GTC,
        IOC
    }

    struct Order {
        address owner;
        uint96 inputAmount;
        address inputToken;
        uint96 minRate;
        address outputToken;
        uint64 expiration;
        OrderType typ;
        bytes extraData;
    }

    event OrderCreated(bytes32 indexed key, Order order, uint256 fee);
    event OrderExecuted(bytes32 indexed key, uint256 input, uint256 output);
    event OrderCancelled(bytes32 indexed key, uint256 returnAmount);
    event ConfigChanged(Config newConfig);

    constructor(address _safesFactory) {
        require(_safesFactory.isContract(), "INVALID_FACTORY");
        safesFactory = IEvaSafesFactory(_safesFactory);
    }

    function _afterCreate(
        bytes32 key,
        uint256 amount,
        uint256 fee
    ) internal virtual {}

    function _afterExecute(
        bytes32 key,
        uint256 input,
        uint256 output,
        uint256 balance
    ) internal virtual {}

    function _afterCancel(bytes32 key, uint256 returnAmount) internal virtual {}

    /**
      @notice create order
      @dev sender can create order for anyone.
      rule:
      1. can't repeat create same order.
      2. creation fee charged, but capped.
      3. will transfer sell token to here.
     */
    function createOrder(Order calldata order) external payable {
        bytes32 key = keyOf(order);

        require(order.owner != address(0), "WRONG_INPUT_OWNER");
        require(
            order.expiration >= block.timestamp + ORDER_MIN_AGE,
            "WRONG_EXPIRATION"
        );
        require(_orders[key].owner == address(0), "ORDER_EXIST");

        Config memory cfg = config;
        require(!cfg.paused, "LOB_PAUSED");
        uint256 fee = uint256(cfg.basisPointsRate).mul(order.inputAmount).div(
            FEE_UNIT
        );
        if (fee > cfg.maximumFee) {
            fee = cfg.maximumFee;
        }

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

        // save order info
        _orders[key] = order;
        _orderBalance[key] = uint256(order.inputAmount).sub(fee);
        emit OrderCreated(key, order, fee);
        _afterCreate(key, order.inputAmount, fee);
    }

    /**
     * @notice Cancel order
     */
    function cancelOrder(bytes32 key) external {
        require(msg.sender == _orders[key].owner, "INVALID_OWNER");
        uint256 balance = _orderBalance[key];
        _transferOutBalance(key, msg.sender, balance);
        _afterCancel(key, balance);
        emit OrderCancelled(key, balance);
    }

    /**
     * @notice Executes an order
     * @dev it can be called by anyone
     */
    function executeOrder(
        bytes32 key,
        IStrategy stategy,
        uint256 input,
        bytes memory data
    ) public {
        Order memory order = _orders[key];
        require(order.expiration >= block.timestamp, "ORDER_NOT_ACTIVE");
        // Pull amount to stegegy
        _transferOutBalance(key, address(stategy), input);

        uint256 before = TransferHelper.balanceOf(
            order.outputToken,
            address(this)
        );
        stategy.execute(order.inputToken, order.outputToken, data);
        uint256 output = TransferHelper
            .balanceOf(order.outputToken, address(this))
            .sub(before);

        // check bought
        uint256 expect = input.mul(order.minRate).div(1e18);
        require(output >= expect, "ORDER_OUTPUT_LESS");

        _afterExecute(key, input, output, _orderBalance[key]);

        emit OrderExecuted(key, input, output);
    }

    function getOrderInfo(bytes32 key)
        public
        view
        returns (Order memory order, uint256 balance)
    {
        order = _orders[key];
        balance = _orderBalance[key];
    }

    function isActiveOrder(bytes32 key) public view returns (bool) {
        return
            _orderBalance[key] > 0 &&
            _orders[key].expiration >= block.timestamp;
    }

    // function getActiveOrder

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

    function setConfig(Config calldata cfg) external onlyOwner {
        config = cfg;
        emit ConfigChanged(cfg);
    }

    function _transferOutBalance(
        bytes32 key,
        address to,
        uint256 amount
    ) private {
        _orderBalance[key] = _orderBalance[key].sub(amount); // INSUFFICIENT BALANCE
        TransferHelper.safeTransferTokenOrETH(
            _orders[key].inputToken,
            to,
            amount
        );
    }
}
