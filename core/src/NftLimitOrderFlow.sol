// SPDX-License-Identifier: GPL-2.0-or-later
// Copy from https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/TransferHelper.sol
pragma solidity ^0.8.0;
import "./interfaces/IEvaFlow.sol";
import "./lib/Utils.sol";
// import {FlowStatus, AssetType, EvabaseHelper} from "./lib/EvabaseHelper.sol";
import {IEvaSafesFactory} from "./interfaces/IEvaSafesFactory.sol";
// import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";

// import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

contract NftLimitOrderFlow is IEvaFlow {
    using AddressUpgradeable for address;
    event OrderExecute(
        address indexed user,
        Order order,
        uint256 amount,
        uint256 value
    );
    enum AssetType {
        ERC721,
        ERC1155,
        ERC20,
        Others
    }
    event OrderCancel(address indexed user, Order order);
    event OrderCreated(address indexed user, Order order);
    struct Order {
        address owner;
        address assetToken;
        AssetType assetType;
        uint256 amount;
        uint256 price;
        uint256 orderTime;
        uint256 duration;
        uint256 salt;
    }
    IEvaSafesFactory public evaSafesFactory;
    address public _owner;
    bool isInitialized;

    mapping(bytes32 => bool) public orderExist;

    function initialize(address _evaSafesFactory) public {
        // constructor(address _evaSafesFactory) {
        require(isInitialized == false, "Already initialized");
        require(_evaSafesFactory != address(0), "addess is 0x");
        isInitialized = true;
        evaSafesFactory = IEvaSafesFactory(_evaSafesFactory);
        _owner = msg.sender;
    }

    function owner() public view override returns (address) {
        return _owner;
    }

    function ownerWalletSafes() public view override returns (address) {
        return evaSafesFactory.calcSafes(msg.sender);
    }

    function check(bytes memory checkData)
        external
        view
        override
        returns (bool needExecute, bytes memory executeData)
    {
        return (false, bytes(""));
    }

    function multicall(bytes memory data) external override {
        require(_owner == msg.sender, "only owner can call this function");
        (address target, bytes memory input) = abi.decode(
            data,
            (address, bytes)
        );
        require(target != address(this), "FORBIDDEN safes address");
        require(target != _owner, "FORBIDDEN self");
        target.functionCall(input, "CallFailed");

        return;
    }

    function execute(bytes memory executeData) external override {
        (Order memory order, bytes memory signature, bytes[] memory data) = abi
            .decode(executeData, (Order, bytes, bytes[]));
        // _atomicMatch(order, signature, data, _assetTokenIds);
        _atomicMatch(order, signature, data);
    }

    function destroy() external override {
        require(_owner == msg.sender, "only owner can call this function");
        // selfdestruct(payable(msg.sender));
        return;
    }

    function cancelOrder(Order memory order) external {
        require(tx.origin == order.owner, "only owner can cancel order");
        require(orderExist[hashOrder(order)], "order not exist");
        orderExist[hashOrder(order)] = false;
        emit OrderCancel(msg.sender, order);
    }

    function _atomicMatch(
        Order memory _order,
        bytes memory _signature,
        bytes[] memory _data
    ) internal returns (bytes[] memory results) {
        require(orderExist[hashOrder(_order)], "order not exist");
        require(_order.owner != address(0), "order owner addrss is 0x");
        uint256 _amount = _order.amount;
        require(_amount > 0, "execute amount gt 0");
        // require(_assetTokenIds.length == _data.length, "length should be same");

        require(
            _order.orderTime + _order.duration >= block.timestamp,
            "order time is end"
        );
        require(
            msg.sender == evaSafesFactory.calcSafes(_order.owner),
            " should exected by safes"
        );
        results = new bytes[](_data.length);
        uint256 total = 0;
        for (uint256 i = 0; i < _data.length; i++) {
            (address target, bytes memory input, uint256 value) = abi.decode(
                _data[i],
                (address, bytes, uint256)
            );
            require(target != address(this), "FORBIDDEN safes address");
            require(target != msg.sender, "FORBIDDEN self");
            results[i] = target.functionCallWithValue(
                // target,
                input,
                value,
                "CallFailed"
            );
            unchecked {
                total += value;
            }
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

        emit OrderExecute(msg.sender, _order, _data.length, total);
    }

    function newOrder(Order memory order) external returns (bytes32) {
        require(order.amount > 0, "amount must be greater than 0");
        require(order.price > 0, "price must be greater than 0");
        require(order.owner != address(0), "owner is 0x");
        require(order.assetToken != address(0), "owner is 0x");
        require(order.duration > 10 minutes, " duration > 10 minutes");
        // Order memory order = Order(
        //     _owner,
        //     _assetToken,
        //     _assetType,
        //     _amount,
        //     _price,
        //     block.timestamp,
        //     duration
        // );
        // orders[nonce++] = order;
        require(!orderExist[hashOrder(order)], "order exist");
        require(
            evaSafesFactory.calcSafes(order.owner) != address(0),
            "Safes not exist"
        );
        bytes32 hash = hashOrder(order);
        orderExist[hash] = true;
        emit OrderCreated(_owner, order);
        return hash;
    }

    function hashOrder(Order memory order) public pure returns (bytes32) {
        return
            keccak256(
                abi.encodePacked( // order
                    order.owner,
                    order.assetToken,
                    order.assetType,
                    order.amount,
                    order.price,
                    order.orderTime,
                    order.duration,
                    order.salt
                )
            );
    }

    function verifyOrder(Order memory order, bytes memory signature)
        public
        pure
        returns (bool)
    {
        bytes32 messageHash = hashOrder(order);
        bytes32 ethSignedMessageHash = Utils.getEthSignedMessageHash(
            messageHash
        );

        return
            Utils.recoverSigner(ethSignedMessageHash, signature) == order.owner;
    }
}
