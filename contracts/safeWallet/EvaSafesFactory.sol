//SPDX-License-Identifier: MIT
//Create by evabase.network core team.
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import {IEvaSafesFactory} from "../interfaces/IEvaSafesFactory.sol";
import {IEvabaseConfig} from "../interfaces/IEvabaseConfig.sol";
import {IEvaSafes} from "../interfaces/IEvaSafes.sol";
import {EvaSafes} from "./EvaSafes.sol";

contract EvaSafesFactory is IEvaSafesFactory, Ownable, ReentrancyGuard {
    address public config;
    mapping(address => address) public evaSafesMap;
    address[] public allWallets;

    constructor(address _config) {
        config = _config;
    }

    function changeConfig(address _config) external override onlyOwner {
        config = _config;
        emit ConfigChanged(_config);
    }

    /**
     * @notice create a safe wallet for user
     * @param user is the wallet owner.
     * @param wallet return the user wallet address.
     */
    function create(address user) external override nonReentrant returns (address wallet) {
        require(user != address(0), "zero address");
        require(evaSafesMap[user] == address(0), "wallet exists");

        bytes memory bytecode = type(EvaSafes).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(user));
        // solhint-disable no-inline-assembly
        assembly {
            wallet := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
        IEvaSafes(wallet).initialize(user, config);
        evaSafesMap[user] = wallet;
        allWallets.push(wallet);

        emit WalletCreated(user, wallet, allWallets.length);
    }

    function get(address user) external view override returns (address wallet) {
        return evaSafesMap[user];
    }

    function codeHash() public pure returns (bytes32) {
        return keccak256(type(EvaSafes).creationCode);
    }

    function calcSafes(address user) external view override returns (address wallet) {
        wallet = address(
            uint160(
                uint256(
                    keccak256(
                        abi.encodePacked(
                            hex"ff",
                            address(this),
                            keccak256(abi.encodePacked(user)),
                            // SafeWallet Contract object Hash
                            codeHash()
                        )
                    )
                )
            )
        );
        // return address(uint160(uint256(_data)));
    }
}
