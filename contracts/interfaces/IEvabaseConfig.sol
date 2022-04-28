//SPDX-License-Identifier: MIT
//Create by evabase.network core team.
pragma solidity ^0.8.0;
import {KeepNetWork} from "../lib/EvabaseHelper.sol";

struct KeepStruct {
    bool isActive;
    KeepNetWork keepNetWork;
}

interface IEvabaseConfig {
    event AddKeeper(address indexed user, address keeper, KeepNetWork keepNetWork);
    event RemoveKeeper(address indexed user, address keeper);
    event AddBatchKeeper(address indexed user, address[] keeper, KeepNetWork[] keepNetWork);
    event RemoveBatchKeeper(address indexed user, address[] keeper);

    // event SetMinGasTokenBal(address indexed user, uint256 amount);
    // event SetMinGasEthBal(address indexed user, uint256 amount);
    // event SetFeeToken(address indexed user, address feeToken);

    // event SetWalletFactory(address indexed user, address factory);
    event SetControl(address indexed user, address control);
    event SetBatchFlowNum(address indexed user, uint32 num);

    function control() external view returns (address);

    function setControl(address control) external;

    // function getWalletFactory() external view returns (address);

    // function setWalletFactory(address factory) external;

    function isKeeper(address query) external view returns (bool);

    function addKeeper(address keeper, KeepNetWork keepNetWork) external;

    function removeKeeper(address keeper) external;

    function addBatchKeeper(address[] memory arr, KeepNetWork[] memory keepNetWork) external;

    function removeBatchKeeper(address[] memory arr) external;

    function setBatchFlowNum(uint32 num) external;

    function batchFlowNum() external view returns (uint32);

    function keepBotSizes(KeepNetWork keepNetWork) external view returns (uint32);

    function getKeepBot(address add) external view returns (KeepStruct memory);

    function isActiveControler(address add) external view returns (bool);

    // function getKeepBotSize() external view returns (uint32);

    // function getAllKeepBots() external returns (address[] memory);

    // function setMinGasTokenBal(uint256 amount) external;

    // function setMinGasEthBal(uint256 amount) external;

    // function setFeeToken(address feeToken) external;

    // function getMinGasTokenBal() external view returns (uint256);

    // function getMinGasEthBal() external view returns (uint256);

    // function setFeeRecived(address feeRecived) external;

    // function setPaymentPrePPB(uint256 amount) external;

    // function setBlockCountPerTurn(uint256 count) external;

    // function getFeeToken() external view returns (address);

    // function getFeeRecived() external view returns (address);

    // event SetPaymentPrePPB(address indexed user, uint256 amount);
    // event SetFeeRecived(address indexed user, address feeRecived);
    // event SetBlockCountPerTurn(address indexed user, uint256 count);
}
