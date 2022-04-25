// SPDX-License-Identifier: GPL-2.0-or-later
// Copy from https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/TransferHelper.sol
pragma solidity ^0.8.0;
import "../../interfaces/IEvaFlow.sol";
import "../../interfaces/EIP712.sol";
import "../../lib/Utils.sol";
import {IEvabaseConfig} from "../../interfaces/IEvabaseConfig.sol";
import {IEvaSafes} from "../../interfaces/IEvaSafes.sol";
import {IEvaFlowController} from "../../interfaces/IEvaFlowController.sol";
import {IEvaSafesFactory} from "../../interfaces/IEvaSafesFactory.sol";
// import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

contract NftLimitOrderFlow is IEvaFlow, EIP712 {
    using AddressUpgradeable for address;

    event OrderExecute(
        address indexed user,
        Order order,
        uint256 amount,
        uint256 value
    );

    event OrderCancel(
        address indexed user,
        uint256 indexed flowId,
        Order order
    );

    event OrderPause(address indexed user, uint256 indexed flowId, Order order);
    event OrderStart(address indexed user, uint256 indexed flowId, Order order);
    event OrderCreated(
        address indexed user,
        uint256 indexed flowId,
        bytes32 _byte32,
        Order order
    );
    struct Order {
        address owner; //拥有人
        address assetToken; //资产合约地址
        uint256 amount; //NFT数量
        uint256 price; //NFT价格
        uint256 expireTime; //订单过期时间 s
        uint256 tokenId;
        uint256 salt; //随机数
    }
    bytes32 constant ORDER_TYPEHASH =
        keccak256(
            "Order(address owner,address assetToken,uint256 amount,uint256 price,uint256 expireTime,uint256 tokenId,uint256 salt)"
        );
    IEvaSafesFactory public evaSafesFactory;
    IEvabaseConfig public config;
    address public _owner;
    bool isInitialized;

    struct OrderExist {
        bool exist; //是否存在
        uint256 amount; //已购NFT数量
    }

    // mapping(bytes32 => bool) public orderExist;
    mapping(bytes32 => OrderExist) public orderExists;

    function initialize(
        address _config,
        address _evaSafesFactory,
        string memory name,
        string memory version
    ) public {
        // constructor(address _evaSafesFactory) {
        require(isInitialized == false, "Already initialized");
        require(_evaSafesFactory != address(0), "addess is 0x");
        require(_config != address(0), "addess is 0x");
        isInitialized = true;
        config = IEvabaseConfig(_config);
        evaSafesFactory = IEvaSafesFactory(_evaSafesFactory);
        _owner = msg.sender;
        init(name, version);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function check(bytes memory checkData)
        external
        view
        override
        returns (bool needExecute, bytes memory executeData)
    {
        return (false, bytes(""));
    }

    function multicall(address target, bytes memory callData)
        external
        override
    {
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
        (Order memory order, bytes memory signature, bytes[] memory data) = abi
            .decode(executeData, (Order, bytes, bytes[]));
        // _atomicMatch(order, signature, data, _assetTokenIds);
        _atomicMatch(order, signature, data);
    }

    function create(uint256 flowId, bytes memory extraData)
        external
        returns (bytes memory checkData)
    {
        require(extraData.length > 0, "extraData size >0");
        require(
            config.isActiveControler(msg.sender),
            "sender is  active controler"
        );
        //bytes memory input = abi.encode(_flowCode, _value);
        (bytes memory _input, uint256 _value) = abi.decode(
            extraData,
            (bytes, uint256)
        );
        require(_input.length > 0, "_input size >0");
        Order memory order = abi.decode(_input, (Order));
        require(tx.origin == order.owner, "only owner can cancel order");

        require(order.amount > 0, "amount must be greater than 0");
        require(order.price > 0, "price must be greater than 0");

        require(order.assetToken != address(0), "assetToken is 0x");
        require(order.expireTime > block.timestamp, "order time is end");

        unchecked {
            uint256 total = order.amount * order.price;
            require(
                total <= _value,
                "order amount*price must be less than or equal to msg.value"
            );
        }

        require(!orderExists[hashOrder(order)].exist, "order exist");
        require(
            evaSafesFactory.get(order.owner) != address(0),
            "Safes not exist"
        );
        bytes32 hash = hashOrder(order);
        orderExists[hash] = OrderExist({exist: true, amount: 0});

        //addFundByUser( address tokenAdress, uint256 amount,address user
        // bytes memory data = abi.encodeWithSelector(
        //     IEvaFlowController.addFundByUser.selector,
        //     address(0),
        //     fee,
        //     order.owner
        // );

        // bytes memory result = config.control().functionCallWithValue(
        //     data,
        //     fee,
        //     "CallFailed"
        // );
        // require(
        //     !Utils.hashCompareInternal(result, bytes("CallFailed")),
        //     "cancel Order failed"
        // );

        emit OrderCreated(msg.sender, flowId, hash, order);
        return abi.encodePacked(hash);
    }

    function pause(uint256 flowId, bytes memory extraData) external {
        require(extraData.length > 0, "extraData size >0");
        require(
            config.isActiveControler(msg.sender),
            "sender is  active controler"
        );
        Order memory order = abi.decode(extraData, (Order));
        require(tx.origin == order.owner, "only owner can cancel order");
        emit OrderPause(msg.sender, flowId, order);
    }

    function start(uint256 flowId, bytes memory extraData) external {
        require(extraData.length > 0, "extraData size >0");
        require(
            config.isActiveControler(msg.sender),
            "sender is  active controler"
        );
        Order memory order = abi.decode(extraData, (Order));
        require(tx.origin == order.owner, "only owner can cancel order");
        emit OrderStart(msg.sender, flowId, order);
    }

    function destroy(uint256 flowId, bytes memory extraData) external {
        require(extraData.length > 0, "extraData size >0");
        require(
            config.isActiveControler(msg.sender),
            "sender is  active controler"
        );

        Order memory order = abi.decode(extraData, (Order));
        require(tx.origin == order.owner, "only owner can cancel order");
        require(orderExists[hashOrder(order)].exist, "order not exist");
        require(
            evaSafesFactory.get(order.owner) != address(0),
            "Safes not exist"
        );
        orderExists[hashOrder(order)].exist = false;
        unchecked {
            uint256 remain = order.amount -
                orderExists[hashOrder(order)].amount;
            require(remain > 0, "remain Nft amount not enough");
            uint256 remainEth = remain * order.price;
            //withdraw ETH
            // bytes memory data = abi.encodeWithSelector(
            //     IEvaSafes.refundETH.selector,
            //     remainEth
            // );

            // bytes memory result = evaSafesFactory.get(order.owner).functionCall(
            //     data,
            //     "CallFailed"
            // );
            // require(
            //     !Utils.hashCompareInternal(result, bytes("CallFailed")),
            //     "cancel Order failed"
            // );
        }

        emit OrderCancel(msg.sender, flowId, order);
    }

    // function cancelOrder(Order memory order) external {

    // }

    function _atomicMatch(
        Order memory _order,
        bytes memory _signature,
        bytes[] memory _data
    ) internal returns (bytes[] memory results) {
        require(orderExists[hashOrder(_order)].exist, "order not exist");
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

        unchecked {
            require(
                _data.length <=
                    _order.amount - orderExists[hashOrder(_order)].amount,
                "Exceeded purchase"
            );

            results = new bytes[](_data.length);
            uint256 total = 0;
            for (uint256 i = 0; i < _data.length; i++) {
                (address target, bytes memory input, uint256 value) = abi
                    .decode(_data[i], (address, bytes, uint256));
                require(target != address(this), "FORBIDDEN safes address");
                require(target != msg.sender, "FORBIDDEN self");
                results[i] = target.functionCallWithValue(
                    // target,
                    input,
                    value,
                    "CallFailed"
                );
                require(
                    !Utils.hashCompareInternal(results[i], bytes("CallFailed")),
                    "_atomicMatch failed"
                );

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

            orderExists[hashOrder(_order)].amount =
                _order.amount -
                _data.length;

            emit OrderExecute(msg.sender, _order, _data.length, total);
        }
    }

    // function newOrder(Order memory order, uint256 fee)
    //     external
    //     payable
    //     returns (bytes32)
    // {}

    function hashOrder(Order memory order) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode( // order
                    ORDER_TYPEHASH,
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

    function verifyOrder(Order memory order, bytes memory signature)
        public
        view
        returns (bool)
    {
        bytes32 messageHash = hashOrder(order);
        // bytes32 ethSignedMessageHash = Utils.getEthSignedMessageHash(
        //     messageHash
        // );

        bytes32 ethSignedMessageHash = _hashTypedDataV4(messageHash);

        return
            SignatureChecker.isValidSignatureNow(
                order.owner,
                ethSignedMessageHash,
                signature
            );
        // return
        //     Utils.recoverSigner(ethSignedMessageHash, signature) == order.owner;
    }
}
