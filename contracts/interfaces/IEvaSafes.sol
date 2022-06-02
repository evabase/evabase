//SPDX-License-Identifier: MIT
//Create by evabase.network core team.
pragma solidity ^0.8.0;

enum HowToCall {
    Call,
    DelegateCall
}

interface IEvaSafes {
    function owner() external view returns (address);

    function initialize(address admin, address agent) external;

    function proxy(
        address dest,
        HowToCall howToCall,
        bytes memory data
    ) external payable returns (bytes memory);

    function isEvaSafes() external pure returns (bool);
}
