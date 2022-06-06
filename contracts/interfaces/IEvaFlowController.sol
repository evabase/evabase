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
    uint120 gasTokenBal; //keep
    uint8 vaildFlowsNum;
}

struct MinConfig {
    address feeRecived;
    address feeToken;
    uint64 minGasFundForUser;
    uint64 minGasFundOneFlow;
    uint16 ppb;
    uint16 blockCountPerTurn;
}

interface IEvaFlowController {
    event FlowOperatorChanged(address op, bool removed);
    event FlowCreated(address indexed user, uint256 indexed flowId, address flowAdd, bytes checkData, uint256 fee);
    event FlowUpdated(address indexed user, uint256 flowId, address flowAdd);
    event FlowClosed(address indexed user, uint256 flowId);
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
        uint16 ppb,
        uint16 blockCountPerTurn
    );

    function registerFlow(
        string memory name,
        KeepNetWork keepNetWork,
        address flow,
        bytes memory checkdata
    ) external payable returns (uint256 flowId);

    function closeFlow(uint256 flowId) external;

    function closeFlowWithGas(uint256 flowId, uint256 before) external;

    function execFlow(
        address keeper,
        uint256 flowId,
        bytes memory inputData
    ) external;

    function depositFund(address flowAdmin) external payable;

    function withdrawFund(address recipient, uint256 amount) external;

    function withdrawPayment(uint256 amount) external;

    function getIndexVaildFlow(uint256 index, KeepNetWork keepNetWork) external view returns (uint256 value);

    function getAllVaildFlowSize(KeepNetWork keepNetWork) external view returns (uint256 size);

    function getFlowMetas(uint256 index) external view returns (EvaFlowMeta memory);

    function getFlowMetaSize() external view returns (uint256);

    function batchExecFlow(address keeper, bytes memory data) external;

    function getFlowCheckInfo(uint256 flowId) external view returns (address flow, bytes memory checkData);
}
