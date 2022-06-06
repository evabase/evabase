//SPDX-License-Identifier: MIT
//Create by evabase.network core team.
pragma solidity ^0.8.0;

interface IEvaSafesFactory {
    event ConfigChanged(address indexed newConfig);

    event WalletCreated(address indexed user, address wallet);

    function get(address user) external view returns (address wallet);

    function create(address user) external returns (address wallet);

    function calcSafes(address user) external view returns (address wallet);

    function changeConfig(address _config) external;
}
