//SPDX-License-Identifier: MIT
//author: Evabase core team

pragma solidity ^0.8.0;

interface IWalletSafes {
    function transferToken(
        address token,
        address to,
        uint256 amount
    ) external;
}

/// @title A flow template code
/// @author devysq@gmail.com
/// @notice Explain to an end user what this does
/// @dev Explain to a developer any extra details
abstract contract FlowBase {
    mapping(bytes32 => bytes32) configs;

    constructor() {
        // safe check
        require(_owner != address(0), "owner is empty");
        require(_safes != address(0), "safes is empty");
    }

    function checkFlowInternal(bytes calldata callData)
        internal
        virtual
        returns (bool needExec, bytes memory execData);

    function execFlowInternal(bytes memory execData) internal virtual;

    function owner() internal pure virtual returns (address);

    function walletSafes() internal pure virtual returns (address);

    /// @notice set or update one config
    /// @dev the config  can only be set by the owner.
    /// @param key is config key
    /// @param value is config value
    function setConfig(bytes32 key, bytes32 value) external {
        require(msg.sender == owner(), "FLOW:only by owner");
        configs[key] = value;
    }

    function getUintVar(bytes32 key) public view returns (uint256) {
        return uint256(configs[key]);
    }

    function getAddrVar(bytes32 key) internal view returns (address) {
        return address(uint160(uint256(configs[key])));
    }

    /// @notice Check whether Flow should be excute now.
    /// @dev This part works at off-chain and is not allowed to be executed on chain.
    /// @return needExec return whether should be execte.
    /// @return execData return the input data when call `execute` function on chain.
    function check(bytes calldata checkData)
        external
        returns (bool needExec, bytes memory execData)
    {
        require(
            msg.sender == 0x0000000000000000000000000000000000000000,
            "FLOW:only off-chain"
        );

        return checkFlowInternal(checkData);
    }

    function execute(bytes memory execData) external {
        require(
            msg.sender == owner() || // call by owner
                msg.sender == walletSafes() || //on-chain
                msg.sender == 0x0000000000000000000000000000000000000000, //off-chain
            "FLOW:only by owner or safes"
        );
        execFlowInternal(execData);
    }

    function _requestToken(
        address token,
        address to,
        uint256 amount
    ) internal {
        require(address(to) != address(0), "FLOW:to is empty");
        IWalletSafes(walletSafes()).transferToken(token, to, amount);
    }
}
