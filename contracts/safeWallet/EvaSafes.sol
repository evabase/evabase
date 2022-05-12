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
        require(owner == _msgSender(), "forbidden");
        _;
    }

    modifier onlyController() {
        require(!revoked && IEvabaseConfig(config).isActiveControler(msg.sender), "forbidden");
        _;
    }

    // called once by the factory at time of deployment
    function initialize(address _admin, address _config) external override initializer {
        require(owner == address(0), "forbidden");
        owner = _admin;
        config = _config;
    }

    function setRevoke(bool revoke) external onlyOwner {
        revoked = revoke;
        emit Revoked(revoke);
    }

    function proxy(
        address dest,
        HowToCall howToCall,
        bytes memory data
    ) external payable override onlyOwner returns (bytes memory ret) {
        if (howToCall == HowToCall.Call) {
            ret = dest.functionCallWithValue(data, msg.value);
        } else if (howToCall == HowToCall.DelegateCall) {
            ret = dest.functionDelegateCall(data);
        } else {
            revert("F");
        }
    }

    function execFlow(address flow, bytes calldata execData)
        external
        override
        onlyController
        returns (bytes memory result)
    {
        result = flow.functionCall(abi.encodeWithSignature("execute(bytes)", execData));
    }

    function withdraw(address token, uint256 amount) external onlyOwner {
        if (token == address(0)) {
            TransferHelper.safeTransferETH(msg.sender, amount);
        } else {
            TransferHelper.safeTransfer(token, msg.sender, amount);
        }
    }

    function isEvaSafes() external pure override returns (bool) {
        return true;
    }

    /**
    @dev can receive ETH, owner can refund.
   */
    receive() external payable {} // solhint-disable no-empty-blocks
}
