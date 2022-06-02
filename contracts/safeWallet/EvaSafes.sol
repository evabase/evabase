//SPDX-License-Identifier: MIT
//Create by evabase.network core team.
pragma solidity ^0.8.0;

import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {TransferHelper} from "../lib/TransferHelper.sol";
import "../interfaces/IEvaSafes.sol";
import {IEvabaseConfig} from "../interfaces/IEvabaseConfig.sol";

contract EvaSafes is IEvaSafes {
    using Address for address;
    event Revoked(bool revoked);

    bytes32 private constant _FLOW_EXECUTOR = keccak256("FLOW_EXECUTOR");

    address public override owner;
    address public config;
    /* Whether access has been revoked. */
    bool public revoked;

    modifier onlyOwner() {
        require(owner == msg.sender, "forbidden");
        _;
    }

    // called once by the factory at time of deployment
    function initialize(address _admin, address _config) external override {
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
    ) external payable override returns (bytes memory ret) {
        require(
            msg.sender == owner || msg.sender == IEvabaseConfig(config).getAddressItem(_FLOW_EXECUTOR),
            "only for owner or executor"
        );
        if (howToCall == HowToCall.Call) {
            ret = dest.functionCallWithValue(data, msg.value);
        } else if (howToCall == HowToCall.DelegateCall) {
            ret = dest.functionDelegateCall(data);
        } else {
            revert("F");
        }
    }

    function withdraw(address token, uint256 amount) external onlyOwner {
        TransferHelper.safeTransferTokenOrETH(token, msg.sender, amount);
    }

    function isEvaSafes() external pure override returns (bool) {
        return true;
    }

    /**
    @dev can receive ETH, owner can refund.
   */
    receive() external payable {} // solhint-disable no-empty-blocks
}
