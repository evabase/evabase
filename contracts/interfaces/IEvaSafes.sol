//SPDX-License-Identifier: MIT
//Create by evabase.network core team.
pragma solidity ^0.8.0;

enum HowToCall {
    Call,
    DelegateCall
}

interface IEvaSafes {
    /**
     * @notice Returns the owner of the safe wallet
     * @return address The address of the wallet owner
     */
    function owner() external view returns (address);

    /**
     * @notice Sets the initial config for the safe wallet
     * @param admin The wallet owner
     * @param agent The agent address
     */
    function initialize(address admin, address agent) external;

    /**
     * @notice Call other contract
     * @param dest The implementation contract
     * @param howToCall The function for calling other contract
     * @param data Any data to be passed through to the implementation contract
     */
    function proxy(
        address dest,
        HowToCall howToCall,
        bytes memory data
    ) external payable returns (bytes memory);

    /**
     * @notice Unique function
     * @return bool Returns true if its type is EvaSafes
     */
    function isEvaSafes() external pure returns (bool);
}
