//SPDX-License-Identifier: MIT
//Create by evabase.network core team.
pragma solidity ^0.8.0;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {Context} from "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {TransferHelper} from "../lib/TransferHelper.sol";
import "../interfaces/IEvaSafes.sol";
import {IEvabaseConfig} from "../interfaces/IEvabaseConfig.sol";

contract EvaSafes is IEvaSafes, Context, Initializable {
    using Address for address;
    event Revoked(bool revoked);

    address public owner;
    address public config;
    /* Whether access has been revoked. */
    bool public revoked;

    modifier onlyOwner() {
        require(owner == _msgSender(), "only owner can exec.");
        _;
    }

    modifier onlyController() {
        require(
            IEvabaseConfig(config).isActiveControler(msg.sender) && revoked,
            "only call by Controller"
        );
        _;
    }

    // called once by the factory at time of deployment
    function initialize(address _admin, address _config)
        external
        override
        initializer
    {
        owner = _admin;
        config = _config;
        revoked = true;
    }

    function setRevoke(bool revoke) external onlyOwner {
        revoked = revoke;
        emit Revoked(revoke);
    }

    function proxy(
        address dest,
        HowToCall howToCall,
        bytes memory data
    ) external override onlyOwner returns (bytes memory ret) {
        if (howToCall == HowToCall.Call) {
            ret = dest.functionCall(data);
        } else if (howToCall == HowToCall.DelegateCall) {
            ret = dest.functionDelegateCall(data);
        } else {
            revert("F");
        }
    }

    function execTask(address flow, bytes calldata execData)
        external
        override
        onlyController
    {
        flow.functionCall(abi.encodeWithSignature("execute(bytes)", execData));
    }

    function refund(address token, uint256 amount) external onlyOwner {
        TransferHelper.safeTransfer(token, msg.sender, amount);
    }

    function refundETH(uint256 amount) external onlyOwner {
        TransferHelper.safeTransferETH(msg.sender, amount);
    }

    /**
    @dev can receive ETH, owner can refund.
   */
    receive() external payable {}
}
