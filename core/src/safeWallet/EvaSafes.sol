//SPDX-License-Identifier: MIT
//Create by evabase.network core team.
pragma solidity ^0.8.0;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {TransferHelper} from "../lib/TransferHelper.sol";

import {IEvaSafes} from "../interfaces/IEvaSafes.sol";
import {IEvabaseConfig} from "../interfaces/IEvabaseConfig.sol";

contract EvaSafes is IEvaSafes, Context, Initializable {
    address public override owner;
    address public config;
    address public factory;
    uint256 private s_currentTask;
    // mapping(address => bool) control;
    /* Whether access has been revoked. */
    bool public revoked;

    constructor() {
        factory = _msgSender();
    }

    enum HowToCall {
        Call,
        DelegateCall
    }

    modifier onlyOwner() {
        require(owner == _msgSender(), "only owner can exec.");
        _;
    }

    event Revoked(bool revoked);
    // event SetControl(address add, bool revoked);

    modifier onlyController() {
        require(
            IEvabaseConfig(config).isActiveControler(msg.sender) && revoked,
            "only call by Controller"
        );
        _;
    }

    modifier onlyControllerOrOwner() {
        require(
            owner == _msgSender() ||
                (IEvabaseConfig(config).isActiveControler(msg.sender) &&
                    revoked),
            "only call by Controller or owner"
        );
        _;
    }

    // called once by the factory at time of deployment
    function initialize(address _admin, address _config)
        external
        override
        initializer
    {
        // require(_msgSender() == factory, "only factory can exec "); // sufficient check
        require(owner == address(0), "owner should zero address");
        owner = _admin;
        config = _config;
        revoked = true;
        // control[_control] = true;
    }

    function setRevoke(bool revoke) external override onlyOwner {
        revoked = revoke;
        emit Revoked(revoke);
    }

    // function setControl(address add, bool revoke) external override onlyOwner {
    //     control[add] = revoke;
    //     emit SetControl(add, revoke);
    // }

    function refund(address token, uint256 amount) external onlyOwner {
        if (amount > 0)
            TransferHelper.safeTransfer(token, _msgSender(), amount);
    }

    function proxy(
        address dest,
        HowToCall howToCall,
        bytes memory data
    ) public onlyControllerOrOwner returns (bool result) {
        bytes memory ret;
        if (howToCall == HowToCall.Call) {
            (result, ret) = dest.call(data);
        } else if (howToCall == HowToCall.DelegateCall) {
            (result, ret) = dest.delegatecall(data);
        }
        return result;
    }

    function refundETH(uint256 amount) external payable onlyOwner {
        if (address(this).balance >= amount) {
            TransferHelper.safeTransferETH(_msgSender(), amount);
        } else {
            TransferHelper.safeTransferETH(_msgSender(), address(this).balance);
        }
    }

    function multicall(uint256 taskId, bytes[] calldata data)
        external
        override
        onlyControllerOrOwner
        returns (bytes[] memory results)
    {
        require(s_currentTask == 0, "doing task");
        s_currentTask = taskId; //set exec context

        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (address target, bytes memory input) = abi.decode(
                data[i],
                (address, bytes)
            );
            require(target != address(this), "FORBIDDEN safes address");
            require(target != _msgSender(), "FORBIDDEN self");
            results[i] = Address.functionCall(target, input, "CallFailed");
        }
        s_currentTask = 0; //release
    }

    function multicallWithValue(uint256 taskId, bytes[] calldata data)
        external
        override
        onlyControllerOrOwner
        returns (bytes[] memory results)
    {
        require(s_currentTask == 0, "doing task");
        s_currentTask = taskId; //set exec context

        results = new bytes[](data.length);
        for (uint256 i = 0; i < data.length; i++) {
            (address target, bytes memory input, uint256 amount) = abi.decode(
                data[i],
                (address, bytes, uint256)
            );
            require(target != address(this), "FORBIDDEN safes address");
            require(target != _msgSender(), "FORBIDDEN self");
            results[i] = Address.functionCallWithValue(
                target,
                input,
                amount,
                "CallFailed"
            );
        }
        s_currentTask = 0; //release
    }

    /** getter */

    function getRunningTask() external view override returns (uint256) {
        return s_currentTask;
    }

    /**
    @dev can receive ETH, owner can refund.
   */
    receive() external payable {}
}
