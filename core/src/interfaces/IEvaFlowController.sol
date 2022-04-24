//SPDX-License-Identifier: MIT
//Create by evabase.network core team.
pragma solidity ^0.8.0;
import {FlowStatus, KeepNetWork} from "../lib/EvabaseHelper.sol";

//struct
struct EvaFlowMeta {
    FlowStatus flowStatus;
    KeepNetWork keepNetWork;
    address admin;
    address lastKeeper;
    address lastVersionflow;
    uint256 lastExecNumber;
    uint256 maxVaildBlockNumber;
    string flowName;
    bytes checkData;
}

struct EvaUserMeta {
    uint120 ethBal;
    uint120 gasTokenBal;
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

interface IEvaFlowController {
    event FlowCreated(
        address indexed user,
        uint256 indexed _flowId,
        address flowAdd
    );
    event FlowUpdated(address indexed user, uint256 _flowId, address flowAdd);
    event FlowPaused(address indexed user, uint256 _flowId);
    event FlowStart(address indexed user, uint256 _flowId);
    event FlowDestroyed(address indexed user, uint256 _flowId);
    event FlowExecuteSuccess(
        address indexed user,
        uint256 indexed flowId,
        uint120 payAmountByETH,
        uint120 payAmountByFeeToken,
        uint256 gasUsed
    );
    event FlowExecuteFailed(
        address indexed user,
        uint256 indexed flowId,
        uint120 payAmountByETH,
        uint120 payAmountByFeeToken,
        uint256 gasUsed,
        string reason
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

    function registerFlow(
        string memory name,
        KeepNetWork keepNetWork,
        address flow,
        bytes memory checkdata
    ) external payable returns (uint256 flowId);

    function updateFlow(
        uint256 _flowId,
        string memory _flowName,
        bytes memory flowCode
    ) external;

    function startFlow(uint256 _flowId, bytes memory flowCode) external;

    function pauseFlow(uint256 _flowId, bytes memory flowCode) external;

    function destroyFlow(uint256 _flowId, bytes memory flowCode) external;

    function createEvaSafes(address user) external;

    function execFlow(
        address keeper,
        uint256 _flowId,
        bytes memory _inputData
    ) external;

    function addFundByUser(
        address tokenAdress,
        uint256 amount,
        address user
    ) external payable;

    function withdrawFundByUser(address tokenAdress, uint256 amount) external;

    function withdrawPayment(address tokenAdress, uint256 amount) external;

    function getVaildFlowRange(
        uint256 fromIndex,
        uint256 endIndex,
        KeepNetWork _keepNetWork
    ) external view returns (uint256[] memory arr);

    function getIndexVaildFlow(uint256 _index, KeepNetWork _keepNetWork)
        external
        view
        returns (uint256 value);

    function getAllVaildFlowSize(KeepNetWork _keepNetWork)
        external
        view
        returns (uint256 size);

    function getFlowMetas(uint256 index)
        external
        view
        returns (EvaFlowMeta memory);

    function batchExecFlow(
        address keeper,
        bytes memory _data,
        uint256 gasLimit
    ) external;

    function getSafes(address user) external view returns (address);
}
