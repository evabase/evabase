//SPDX-License-Identifier: MIT
//Create by evabase.network core team.
pragma solidity ^0.8.0;

interface IEvaSafesFactory {
   
    /// @notice Emitted when the config of the factory is changed
    /// @param newConfig The new config address
    event ConfigChanged(address indexed newConfig);

   
    /// @notice Emitted when a safe wallet is created
    /// @param user The wallet owner
    /// @param wallet The user wallet address
    event WalletCreated(address indexed user, address wallet);

   
    /// @notice Returns a safe wallet address
    /// @param user The wallet owner
    /// @return wallet The user wallet address
    function get(address user) external view returns (address wallet);

   
    /// @notice Create a safe wallet for user
    /// @param user The wallet owner
    /// @return wallet The user wallet address
    function create(address user) external returns (address wallet);

   
    /// @notice Calculate out the address of safe wallet
    /// @param user The wallet owner
    /// @return wallet The user wallet address
    function calcSafes(address user) external view returns (address wallet);

   
    /// @notice Update the config of the factory
    /// @dev Must be called by the current owner
    /// @param _config The new config address
    function changeConfig(address _config) external;
}
