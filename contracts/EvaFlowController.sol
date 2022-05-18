//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./interfaces/IEvaFlowController.sol";
import {IEvaSafesFactory} from "./interfaces/IEvaSafesFactory.sol";
import {FlowStatus, KeepNetWork, EvabaseHelper} from "./lib/EvabaseHelper.sol";
import {Utils} from "./lib/Utils.sol";
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

    //Withdrawable fees
    uint256 public paymentEthAmount;
    uint256 public paymentGasAmount;

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

    function setFlowOperators(address op, bool remove) external onlyOwner {
        if (remove) {
            flowOperators[op] = true;
        } else {
            delete flowOperators[op];
        }
        emit FlowOperatorChanged(op, remove);
    }

    function _checkEnoughGas() internal view {
        bool isEnoughGas = true;
        if (minConfig.feeToken == address(0)) {
            isEnoughGas =
                (userMetaMap[msg.sender].ethBal >= minConfig.minGasFundForUser) &&
                (userMetaMap[msg.sender].ethBal >= userMetaMap[msg.sender].vaildFlowsNum * minConfig.minGasFundOneFlow);
        } else {
            isEnoughGas =
                (userMetaMap[msg.sender].gasTokenBal >= minConfig.minGasFundForUser) &&
                (userMetaMap[msg.sender].gasTokenBal >=
                    userMetaMap[msg.sender].vaildFlowsNum * minConfig.minGasFundOneFlow);
        }

        require(isEnoughGas, "gas balance is not enough");
    }

    function _beforeCreateFlow(KeepNetWork _keepNetWork) internal view {
        require(uint256(_keepNetWork) <= uint256(KeepNetWork.Others), "invalid netWork");
        require(IEvaSafes(msg.sender).isEvaSafes(), "should be safes");
    }

    function isValidFlow(address flow) public pure returns (bool) {
        require(flow != address(0), "flow is 0x");
        return true; //TODO: Valid Flows
    }

    function _appendFee(address acct, uint256 amount) private {
        userMetaMap[acct].ethBal += Utils.toUint120(amount);
    }

    function registerFlow(
        string memory name,
        KeepNetWork network,
        address flow,
        bytes memory checkdata
    ) external payable override returns (uint256 flowId) {
        require(isValidFlow(flow), "invalid flow");
        _beforeCreateFlow(network);
        _appendFee(msg.sender, msg.value);
        userMetaMap[msg.sender].vaildFlowsNum += uint8(1); // Error if overflow
        //Check if the Gas fee balance is sufficient
        _checkEnoughGas();
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

    function updateFlow(
        uint256 _flowId,
        string memory _flowName,
        bytes memory _flowCode
    ) external override {
        require(_flowId < _flowMetas.length, "over bound");
        require(msg.sender == _flowMetas[_flowId].admin, "flow's owner is not y");
        require(
            FlowStatus.Active == _flowMetas[_flowId].flowStatus || FlowStatus.Paused == _flowMetas[_flowId].flowStatus,
            "flow's status is error"
        );

        KeepNetWork keepNetWork = _flowMetas[_flowId].keepNetWork;

        _beforeCreateFlow(keepNetWork);
        //create
        address addr;
        uint256 size;
        // solhint-disable no-inline-assembly
        assembly {
            addr := create(0, add(_flowCode, 0x20), mload(_flowCode))
            size := extcodesize(addr)
            if iszero(extcodesize(addr)) {
                revert(0, 0)
            }
        }
        // _vaildFlows.remove(_flowId);
        _vaildFlows[keepNetWork].remove(_flowId);
        _flowMetas[_flowId].flowName = _flowName;
        _flowMetas[_flowId].lastKeeper = address(0);
        _flowMetas[_flowId].lastExecNumber = block.number;
        _flowMetas[_flowId].lastVersionflow = addr;
        // _vaildFlows.add(_flowId);
        _vaildFlows[keepNetWork].add(_flowId);

        emit FlowUpdated(msg.sender, _flowId, addr);
    }

    function pauseFlow(uint256 _flowId) external override {
        require(_flowId < _flowMetas.length, "over bound");
        require(userMetaMap[msg.sender].vaildFlowsNum > 0, "vaildFlowsNum should gt 0");
        require(FlowStatus.Active == _flowMetas[_flowId].flowStatus, "flow's status is error");
        _requireFlowOperator(_flowMetas[_flowId].admin);
        _flowMetas[_flowId].lastExecNumber = block.number;
        _flowMetas[_flowId].flowStatus = FlowStatus.Paused;

        userMetaMap[msg.sender].vaildFlowsNum = userMetaMap[msg.sender].vaildFlowsNum - 1;

        if (_flowMetas[_flowId].lastVersionflow != address(0)) {
            // _vaildFlows.remove(_flowId);
            KeepNetWork keepNetWork = _flowMetas[_flowId].keepNetWork;
            _vaildFlows[keepNetWork].remove(_flowId);
        }
        emit FlowPaused(msg.sender, _flowId);
    }

    function startFlow(uint256 _flowId) external override {
        require(_flowId < _flowMetas.length, "over bound");

        _requireFlowOperator(_flowMetas[_flowId].admin);
        require(FlowStatus.Paused == _flowMetas[_flowId].flowStatus, "flow's status is error");
        _flowMetas[_flowId].lastExecNumber = block.number;
        _flowMetas[_flowId].flowStatus = FlowStatus.Active;

        userMetaMap[msg.sender].vaildFlowsNum = userMetaMap[msg.sender].vaildFlowsNum + 1;

        if (_flowMetas[_flowId].lastVersionflow != address(0)) {
            // _vaildFlows.add(_flowId);
            KeepNetWork keepNetWork = _flowMetas[_flowId].keepNetWork;
            _vaildFlows[keepNetWork].add(_flowId);
        }

        emit FlowStart(msg.sender, _flowId);
    }

    function destroyFlow(uint256 flowId) external override {
        EvaFlowMeta memory meta = _flowMetas[flowId];
        _requireFlowOperator(meta.admin);
        require(meta.flowStatus != FlowStatus.Destroyed, "have destroyed");
        _destroyFlow(flowId, meta);
    }

    function _destroyFlow(uint256 flowId, EvaFlowMeta memory meta) internal {
        // remove from valid when flow is active.
        if (meta.flowStatus == FlowStatus.Active) {
            userMetaMap[meta.admin].vaildFlowsNum -= 1;
            _vaildFlows[meta.keepNetWork].remove(flowId);
        }
        _flowMetas[flowId].flowStatus = FlowStatus.Destroyed;
        emit FlowDestroyed(meta.admin, flowId);
    }

    function addFundByUser(
        address tokenAdress,
        uint256 amount,
        address flowAdmin
    ) public payable override {
        if (tokenAdress == address(0)) {
            require(msg.value == amount, "value is not equal");

            userMetaMap[flowAdmin].ethBal = userMetaMap[flowAdmin].ethBal + Utils.toUint120(msg.value);
        } else {
            require(tokenAdress == minConfig.feeToken, "error FeeToken");

            userMetaMap[flowAdmin].gasTokenBal = userMetaMap[flowAdmin].gasTokenBal + Utils.toUint120(amount);

            TransferHelper.safeTransferFrom(tokenAdress, msg.sender, address(this), amount);
        }
    }

    function withdrawFundByUser(address tokenAdress, uint256 amount) external override {
        address safeWallet = msg.sender;

        uint256 minTotalFlow = userMetaMap[safeWallet].vaildFlowsNum * minConfig.minGasFundOneFlow;
        uint256 minTotalGas = minTotalFlow > minConfig.minGasFundForUser ? minTotalFlow : minConfig.minGasFundForUser;

        if (tokenAdress == address(0)) {
            require(userMetaMap[safeWallet].ethBal >= amount + minTotalGas, "withdraw too big");
            userMetaMap[safeWallet].ethBal -= Utils.toUint120(amount);
            TransferHelper.safeTransferETH(safeWallet, amount);
        } else {
            require(tokenAdress == minConfig.feeToken, "error FeeToken");
            require(userMetaMap[safeWallet].ethBal >= amount + minTotalGas, "withdraw too big");

            userMetaMap[safeWallet].gasTokenBal -= Utils.toUint120(amount);

            TransferHelper.safeTransfer(tokenAdress, safeWallet, amount);
        }
    }

    function withdrawPayment(address tokenAdress, uint256 amount) external override onlyOwner {
        if (tokenAdress == address(0)) {
            require(paymentEthAmount >= amount, "");
            TransferHelper.safeTransferETH(msg.sender, amount);
        } else {
            require(tokenAdress == minConfig.feeToken, "error FeeToken");
            require(paymentGasAmount >= amount, "");
            TransferHelper.safeTransfer(tokenAdress, msg.sender, amount);
        }
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

    function batchExecFlow(
        address keeper,
        bytes memory data,
        uint256
    ) external override {
        (uint256[] memory arr, bytes[] memory executeDataArray) = Utils._decodeTwoArr(data);
        require(arr.length == executeDataArray.length, "invalid array len");
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] > 0) {
                execFlow(keeper, arr[i], executeDataArray[i]);
            }
        }
    }

    function execFlow(
        address keeper,
        uint256 flowId,
        bytes memory execData
    ) public override {
        EvaFlowMeta memory flow = _flowMetas[flowId];
        KeepStruct memory ks = config.getKeepBot(msg.sender);

        // Let pre-execution pass
        // solhint-disable avoid-tx-origin
        if (tx.origin != address(0)) {
            // Check if the flow's network matches the keeper
            require(flow.keepNetWork == ks.keepNetWork, "invalid keepNetWork");
            require(ks.isActive, "exect keeper is not whitelist");
        }

        uint256 before = gasleft();

        if (flow.keepNetWork != KeepNetWork.Evabase) {
            require((keeper != flow.lastKeeper), "expect next keeper");
        }

        // update first.
        _flowMetas[flowId].lastExecNumber = block.number;
        _flowMetas[flowId].lastKeeper = keeper;

        bool success;
        string memory failedReason;
        {
            address executor = config.getAddressItem(_FLOW_EXECUTOR);
            try IEvaFlowExecutor(executor).execute(flow, execData) returns (bool needCloseFlow) {
                if (needCloseFlow) {
                    _destroyFlow(flowId, flow);
                }
                success = true;
            } catch Error(string memory reason) {
                failedReason = reason; // revert or require
            } catch {
                failedReason = "Reverted"; //assert
            }
        }

        uint256 usedGas = before - gasleft();

        uint120 payAmountByETH = 0;
        uint120 payAmountByFeeToken = 0;

        if (minConfig.feeToken == address(0)) {
            payAmountByETH = _calculatePaymentAmount(usedGas);
            uint120 bal = userMetaMap[flow.admin].ethBal;

            require(bal >= payAmountByETH, "insufficient fund");
            userMetaMap[flow.admin].ethBal = bal < payAmountByETH ? 0 : bal - payAmountByETH;
        } else {
            revert("TODO");
        }

        if (success) {
            emit FlowExecuteSuccess(flow.admin, flowId, payAmountByETH, payAmountByFeeToken, usedGas);
        } else {
            emit FlowExecuteFailed(flow.admin, flowId, payAmountByETH, payAmountByFeeToken, usedGas, failedReason);
        }
    }

    function _calculatePaymentAmount(uint256 gasLimit) private view returns (uint120 payment) {
        uint256 weiForGas = tx.gasprice * (gasLimit + _REGISTRY_GAS_OVERHEAD);
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
