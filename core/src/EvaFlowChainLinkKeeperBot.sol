//SPDX-License-Identifier: MIT
//Create by Openflow.network core team.
pragma solidity ^0.8.0;
import {KeeperRegistryInterface} from "./keeper/chainlink/KeeperRegistryInterface.sol";
import {KeeperCompatibleInterface} from "./keeper/chainlink/KeeperCompatibleInterface.sol";
import {EvaKeepBotBase} from "./keeper/EvaKeepBotBase.sol";
import {IEvabaseConfig} from "./interfaces/IEvabaseConfig.sol";
import {EvaFlowChecker} from "./EvaFlowChecker.sol";
import {IEvaFlowControler} from "./interfaces/IEvaFlowControler.sol";
// import {KeeperRegistryBaseInterface} from "./keeper/chainlink/KeeperRegistryInterface.sol";
import {IEvaFlow} from "./interfaces/IEvaFlow.sol";
import {LinkTokenInterface} from "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import {UpkeepRegistrationRequestsInterface} from "./keeper/chainlink/UpkeepRegistrationRequestsInterface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EvaFlowChainLinkKeeperBot is
    EvaKeepBotBase,
    KeeperCompatibleInterface,
    Ownable
{
    uint32 private constant CHECK_GAS_LIMIT = 2_000_000;
    uint32 private constant EXEC_GAS_LIMIT = 2_000_000;
    // KeeperRegistryInterface private immutable keeperRegistryInterface;
    uint32 public keepBotId;
    uint256 public chainLinkKeepId;
    address public linkToken;
    uint256 lastBlockNum;
    KeeperRegistryInterface private immutable keeperRegistry;
    address private regiesterRequest;

    constructor(
        address _config,
        address _evaFlowChecker,
        address _evaFlowControler,
        address _linkToken,
        address _keeperRegistry,
        address _regiesterRequest
    ) {
        require(_evaFlowControler != address(0), "addess is 0x");
        require(_config != address(0), "addess is 0x");
        require(_evaFlowChecker != address(0), "addess is 0x");
        require(_linkToken != address(0), "addess is 0x");
        require(_keeperRegistry != address(0), "addess is 0x");
        require(_regiesterRequest != address(0), "addess is 0x");
        evaFlowControler = IEvaFlowControler(_evaFlowControler);
        config = IEvabaseConfig(_config);
        evaFlowChecker = EvaFlowChecker(_evaFlowChecker);

        keeperRegistry = KeeperRegistryInterface(_keeperRegistry);
        regiesterRequest = _regiesterRequest;
    }

    function checkUpkeep(bytes calldata checkData)
        external
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        unchecked {
            upkeepNeeded = block.number - lastBlockNum >= 10;
        }

        if (upkeepNeeded) {
            (upkeepNeeded, performData) = _check(checkData);
        }
    }

    function performUpkeep(bytes calldata performData) external override {
        _exec(performData);
    }

    function _check(bytes memory checkdata)
        internal
        override
        returns (bool needExec, bytes memory execdata)
    {
        (bool needExec, bytes memory execData) = evaFlowChecker.check(
            keepBotId,
            CHECK_GAS_LIMIT,
            checkdata
        );

        return (needExec, execData);
    }

    function _exec(bytes memory execdata) internal override {
        lastBlockNum = block.number;
        evaFlowChecker.setLastMoveTime();
        batchExec(execdata);
    }

    function batchExec(bytes memory data) internal {
        require(data.length > 0, "exec data should not null");
        address keeper = tx.origin;
        (address payee, bool active, uint96 balance) = keeperRegistry
            .getKeeperInfo(keeper);
        require(active, "not active chianlink active");

        //todo

        uint256 gasTotal = 0;
        uint256[] memory arr = evaFlowChecker.decodeUints(data);
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] > 0) {
                uint256 before = gasleft();
                evaFlowControler.execFlow(arr[i]);
                if (gasTotal + before - gasleft() > EXEC_GAS_LIMIT) {
                    return;
                }
            }
        }
    }

    function registerTask(bytes memory checkData)
        external
        onlyOwner
        returns (uint256 thirdId)
    {
        uint256 linkTokenAmount = 5 * 1e18;
        //check balance
        LinkTokenInterface link = LinkTokenInterface(linkToken);
        require(
            link.balanceOf(address(this)) >= linkTokenAmount,
            "insufficient LINK"
        );

        bytes memory callInput = abi.encodeWithSelector(
            UpkeepRegistrationRequestsInterface.register.selector,
            "T",
            hex"efaebfb59113bbba19dada14b745015c7afec8bb03c6192fb20bc99302a1d6493f185837865aa75406da8e2184d05225a78cec5d018d25939fb342cd0bc3a765a287ab7c6d410157134d9e30435a6a1cde9b66addcd028ad",
            address(this),
            uint32(EXEC_GAS_LIMIT),
            address(this),
            checkData,
            uint96(linkTokenAmount),
            uint8(0)
        );

        require(
            link.transferAndCall(regiesterRequest, linkTokenAmount, callInput),
            "chainlink upkeeps register failed"
        );

        bytes32 hash = keccak256(
            abi.encode(address(this), EXEC_GAS_LIMIT, address(this), checkData)
        );
        (address admin, ) = UpkeepRegistrationRequestsInterface(
            regiesterRequest
        ).getPendingRequest(hash);
        require(admin == address(0), "need chainlink approved");

        uint256 nextId = KeeperRegistryInterface(keeperRegistry)
            .getUpkeepCount();
        chainLinkKeepId = nextId - 1;
        config.addKeeper(address(this));
        keepBotId = config.keepBotSize() + 1;
        return chainLinkKeepId;
    }

    function cancelTask() external onlyOwner {
        KeeperRegistryInterface(keeperRegistry).cancelUpkeep(chainLinkKeepId);
        config.removeKeeper(address(this));
    }
}
