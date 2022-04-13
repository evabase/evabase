//SPDX-License-Identifier: MIT
//Create by evabase.network core team.
pragma solidity ^0.8.0;
import {FlowStatus, KeepNetWork} from "../lib/EvabaseHelper.sol";

interface IEvaFlowControler {
    //struct
    struct EvaFlowMeta {
        FlowStatus flowStatus;
        KeepNetWork keepNetWork;
        uint256 maxVaildBlockNumber;
        address admin;
        address lastKeeper;
        uint256 lastExecNumber;
        address lastVersionflow;
        string flowName;
    }

    struct EvaUserMeta {
        uint256 ethBal;
        uint256 gasTokenbal;
        uint8 vaildFlowsNum;
    }

    struct MinConfig {
        address feeRecived;
        address feeToken;
        uint64 minGasFundForUser;
        uint64 minGasFundOneFlow;
        uint16 PPB;
        uint16 blockCountPerTurn;
    }

    event FlowCreated(address indexed user, uint256 _flowId, address flowAdd);
    event FlowUpdated(address indexed user, uint256 _flowId, address flowAdd);
    event FlowPaused(address indexed user, uint256 _flowId);
    event FlowDestroyed(address indexed user, uint256 _flowId);
    event FlowExecuted(
        address indexed user,
        uint256 _flowId,
        bool sucesss,
        uint256 payAmountByETH,
        uint256 payAmountByFeeToken
    );

    event SetMinConfig(
        address indexed user,
        address feeRecived,
        address feeToken,
        uint64 minGasFundForUser,
        uint64 minGasFundOneFlow,
        uint16 PPB,
        uint16 blockCountPerTurn
    );

    function createFlow(
        string memory flowName,
        KeepNetWork keepNetWork,
        bytes memory flowCode
    ) external payable returns (uint256 _flowId, address add);

    function updateFlow(
        uint256 _flowId,
        string memory _flowName,
        bytes memory flowCode
    ) external;

    function pauseFlow(uint256 _flowId) external;

    function destroyFlow(uint256 _flowId) external;

    function createEvaSafes(address user) external;

    function execFlow(uint256 _flowId, bytes memory _inputData) external;

    function addFundByUser(
        address tokenAdress,
        uint256 amount,
        address user
    ) external payable;

    function withdrawFundByUser(address tokenAdress, uint256 amount) external;

    function withdrawPayment(address tokenAdress, uint256 amount) external;

    function getVaildFlowRange(uint256 fromIndex, uint256 endIndex)
        external
        view
        returns (uint256[] memory arr);

    function getIndexVaildFlow(uint256 _index)
        external
        view
        returns (uint256 value);

    function getAllVaildFlowSize() external view returns (uint256 size);

    function getFlowMetas(uint256 index)
        external
        view
        returns (EvaFlowMeta memory);

    function batchExecFlow(bytes memory _data, uint256 gasLimit) external;
}
