//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./interfaces/IEvaFlowController.sol";
import {IEvaSafesFactory} from "./interfaces/IEvaSafesFactory.sol";
import {FlowStatus, KeepNetWork, EvabaseHelper} from "./lib/EvabaseHelper.sol";
import "./lib/MathConv.sol";
import {TransferHelper} from "./lib/TransferHelper.sol";
import {IEvaSafes} from "./interfaces/IEvaSafes.sol";
import "./interfaces/IEvabaseConfig.sol";
import "./interfaces/IEvaFlowExecutor.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract EvaFlowController is IEvaFlowController, OwnableUpgradeable {
    EvaFlowMeta[] private _flowMetas;
    MinConfig public minConfig;
    mapping(address => EvaUserMeta) public userMetaMap;

    //need exec flows
    using EvabaseHelper for EvabaseHelper.UintSet;
    mapping(KeepNetWork => EvabaseHelper.UintSet) private _vaildFlows;

    uint256 private constant _REGISTRY_GAS_OVERHEAD = 80_000;
    uint256 private constant _MAX_INT = type(uint256).max;
    bytes32 private constant _FLOW_EXECUTOR = keccak256("FLOW_EXECUTOR");

    IEvaSafesFactory public evaSafesFactory;
    IEvabaseConfig public config;
    mapping(address => bool) public flowOperators;

    event FlowOperatorChanged(address op, bool removed);

    function initialize(address _config, address _evaSafesFactory) external initializer {
        require(_evaSafesFactory != address(0), "addess is 0x");
        require(_config != address(0), "addess is 0x");
        __Ownable_init();
        evaSafesFactory = IEvaSafesFactory(_evaSafesFactory);
        config = IEvabaseConfig(_config);

        EvaFlowMeta memory f;
        _flowMetas.push(f); //storage a solt, flow id starts with 1.

        flowOperators[msg.sender] = true;
    }

    function setMinConfig(MinConfig memory _minConfig) external onlyOwner {
        require(_minConfig.ppb >= 10000 && _minConfig.ppb <= 15000, "invalid ppb");
        minConfig = _minConfig;
        emit SetMinConfig(
            msg.sender,
            _minConfig.feeRecived,
            _minConfig.feeToken,
            _minConfig.minGasFundForUser,
            _minConfig.minGasFundOneFlow,
            _minConfig.ppb,
            _minConfig.blockCountPerTurn
        );
    }

    function setFlowOperators(address op, bool isAdd) external onlyOwner {
        if (isAdd) {
            flowOperators[op] = true;
        } else {
            delete flowOperators[op];
        }
        emit FlowOperatorChanged(op, isAdd);
    }

    function _beforeCreateFlow(KeepNetWork _keepNetWork) internal view {
        require(uint256(_keepNetWork) <= uint256(KeepNetWork.Others), "invalid netWork");
        require(IEvaSafes(msg.sender).isEvaSafes(), "should be safes");
    }

    function isValidFlow(address flow) public view returns (bool) {
        require(flow != address(0), "flow is 0x");
        require(flow != address(this), "invalid flow");
        return true; //TODO: Valid Flows
    }

    function _changeFund(uint256 amount, bool withdraw) private {
        if (withdraw) {
            userMetaMap[msg.sender].ethBal -= MathConv.toU120(amount);
        } else {
            userMetaMap[msg.sender].ethBal += MathConv.toU120(amount);
        }
        EvaUserMeta memory user = userMetaMap[msg.sender];

        //after fee check
        //Check if the Gas fee balance is sufficient
        bool isEnoughGas = (user.ethBal >= minConfig.minGasFundForUser) &&
            (user.ethBal >= user.vaildFlowsNum * minConfig.minGasFundOneFlow);
        require(isEnoughGas, "not enough fund");
    }

    function registerFlow(
        string memory name,
        KeepNetWork network,
        address flow,
        bytes memory checkdata
    ) external payable override returns (uint256 flowId) {
        require(isValidFlow(flow), "invalid flow");
        _beforeCreateFlow(network);
        userMetaMap[msg.sender].vaildFlowsNum += uint8(1); // Error if overflow
        _changeFund(msg.value, false);

        _flowMetas.push(
            EvaFlowMeta({
                flowStatus: FlowStatus.Active,
                keepNetWork: network,
                maxVaildBlockNumber: _MAX_INT,
                admin: msg.sender,
                lastKeeper: address(0),
                lastExecNumber: 0,
                lastVersionflow: flow,
                flowName: name,
                checkData: checkdata
            })
        );
        flowId = _flowMetas.length - 1;
        _vaildFlows[network].add(flowId);
        emit FlowCreated(msg.sender, flowId, flow, checkdata, msg.value);
    }

    function closeFlow(uint256 flowId) external override {
        closeFlowWithGas(flowId, 0);
    }

    function closeFlowWithGas(uint256 flowId, uint256 before) public override {
        EvaFlowMeta memory meta = _flowMetas[flowId];
        _requireFlowOperator(meta.admin);
        require(meta.flowStatus != FlowStatus.Closed, "have closeed");
        _closeFlow(flowId, meta);
        if (before != 0) {
            uint256 usedGas = before - gasleft();
            _updateUserFund(meta.admin, usedGas);
        }
    }

    function _closeFlow(uint256 flowId, EvaFlowMeta memory meta) internal {
        // remove from valid when flow is active.
        if (meta.flowStatus == FlowStatus.Active) {
            userMetaMap[meta.admin].vaildFlowsNum -= 1;
            _vaildFlows[meta.keepNetWork].remove(flowId);
        }
        _flowMetas[flowId].flowStatus = FlowStatus.Closed;
        emit FlowClosed(meta.admin, flowId);
    }

    function depositFund(address flowAdmin) public payable override {
        userMetaMap[flowAdmin].ethBal += MathConv.toU120(msg.value);
    }

    function withdrawFund(address recipient, uint256 amount) external override {
        require(recipient != address(0), "invalid address");
        _changeFund(amount, true);
        TransferHelper.safeTransferETH(recipient, amount);
    }

    function withdrawPayment(uint256 amount) external override onlyOwner {
        TransferHelper.safeTransferETH(msg.sender, amount);
    }

    function getIndexVaildFlow(uint256 index, KeepNetWork keepNetWork) external view override returns (uint256 value) {
        return _vaildFlows[keepNetWork].get(index);
    }

    function getVaildFlowRange(
        uint256 fromIndex,
        uint256 endIndex,
        KeepNetWork keepNetWork
    ) external view override returns (uint256[] memory arr) {
        return _vaildFlows[keepNetWork].getRange(fromIndex, endIndex);
    }

    function getAllVaildFlowSize(KeepNetWork keepNetWork) external view override returns (uint256 size) {
        return _vaildFlows[keepNetWork].getSize();
    }

    function getFlowMetas(uint256 index) external view override returns (EvaFlowMeta memory) {
        return _flowMetas[index];
    }

    function getFlowMetaSize() external view override returns (uint256) {
        return _flowMetas.length;
    }

    function batchExecFlow(address keeper, bytes memory data) external override {
        (uint256[] memory arr, bytes[] memory executeDataArray) = abi.decode(data, (uint256[], bytes[]));
        require(arr.length == executeDataArray.length, "invalid array len");

        KeepInfo memory ks = config.getKeepBot(msg.sender);
        require(ks.isActive, "exect keeper is not whitelist");

        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] > 0) {
                _execFlow(ks, keeper, arr[i], executeDataArray[i]);
            }
        }
    }

    function execFlow(
        address keeper,
        uint256 flowId,
        bytes memory execData
    ) public override {
        _execFlow(config.getKeepBot(msg.sender), keeper, flowId, execData);
    }

    function _execFlow(
        KeepInfo memory ks,
        address keeper,
        uint256 flowId,
        bytes memory execData
    ) private {
        EvaFlowMeta memory flow = _flowMetas[flowId];

        // solhint-disable avoid-tx-origin
        bool isOffChain = tx.origin == address(0);
        // Let pre-execution pass

        if (!isOffChain) {
            // Check if the flow's network matches the keeper
            require(flow.keepNetWork == ks.keepNetWork, "invalid keepNetWork");
        }

        uint256 before = gasleft();

        if (flow.keepNetWork != KeepNetWork.Evabase) {
            require((keeper != flow.lastKeeper), "expect next keeper");
        }

        // update first.
        _flowMetas[flowId].lastExecNumber = block.number;
        _flowMetas[flowId].lastKeeper = keeper;

        bool success;
        bool needClose;
        string memory failedReason;
        {
            address executor = config.getAddressItem(_FLOW_EXECUTOR);
            try IEvaFlowExecutor(executor).execute(flow, execData) returns (bool needCloseFlow) {
                needClose = needCloseFlow;
                success = true;
            } catch Error(string memory reason) {
                failedReason = reason; // revert or require
            } catch {
                failedReason = "Reverted"; //assert
            }
        }

        uint256 usedGas = before - gasleft();

        (uint120 payAmountByETH, uint120 payAmountByFeeToken) = _updateUserFund(flow.admin, usedGas);

        if (success) {
            emit FlowExecuteSuccess(flow.admin, flowId, payAmountByETH, payAmountByFeeToken, usedGas);
        } else {
            if (isOffChain) {
                revert(failedReason);
            }
            emit FlowExecuteFailed(flow.admin, flowId, payAmountByETH, payAmountByFeeToken, usedGas, failedReason);
        }

        if (needClose && !isOffChain) {
            // don't close flow when try execute on off-chain
            _closeFlow(flowId, flow);
        }
    }

    function _updateUserFund(address admin, uint256 usedGas)
        internal
        returns (uint120 payAmountByETH, uint120 payAmountByFeeToken)
    {
        // solhint-disable avoid-tx-origin
        bool isOffChain = tx.origin == address(0);
        payAmountByETH = _calculatePaymentAmount(usedGas);
        uint120 bal = userMetaMap[admin].ethBal;

        if (isOffChain) {
            uint256 minPay = payAmountByETH > minConfig.minGasFundOneFlow
                ? payAmountByETH
                : minConfig.minGasFundOneFlow;
            require(bal >= minPay, "insufficient fund");
        }
        userMetaMap[admin].ethBal = bal < payAmountByETH ? 0 : bal - payAmountByETH;
    }

    function _calculatePaymentAmount(uint256 gasLimit) private view returns (uint120 payment) {
        uint256 price = tx.gasprice == 0 ? 1 gwei : tx.gasprice;
        uint256 weiForGas = price * (gasLimit + _REGISTRY_GAS_OVERHEAD);
        uint256 total = (weiForGas * minConfig.ppb) / 10000;
        return uint120(total);
    }

    function getSafes(address user) external view override returns (address) {
        return evaSafesFactory.get(user);
    }

    function getFlowCheckInfo(uint256 flowId) external view override returns (address flow, bytes memory checkData) {
        flow = _flowMetas[flowId].lastVersionflow;
        checkData = _flowMetas[flowId].checkData;
    }

    function _requireFlowOperator(address flowAdmin) private view {
        require(flowAdmin == msg.sender || flowOperators[msg.sender], "only for op/admin");
    }
}
