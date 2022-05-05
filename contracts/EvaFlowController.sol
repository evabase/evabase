//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./interfaces/IEvaFlowController.sol";
import {IEvaSafesFactory} from "./interfaces/IEvaSafesFactory.sol";
import {FlowStatus, KeepNetWork, EvabaseHelper} from "./lib/EvabaseHelper.sol";
import {Utils} from "./lib/Utils.sol";
import {TransferHelper} from "./lib/TransferHelper.sol";
import {IEvaSafes} from "./interfaces/IEvaSafes.sol";
import "./interfaces/IEvabaseConfig.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract EvaFlowController is IEvaFlowController, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    EvaFlowMeta[] private _flowMetas;
    MinConfig public minConfig;
    mapping(address => EvaUserMeta) public userMetaMap;

    ////need exec flows
    using EvabaseHelper for EvabaseHelper.UintSet;
    mapping(KeepNetWork => EvabaseHelper.UintSet) private _vaildFlows;

    uint256 private constant _REGISTRY_GAS_OVERHEAD = 80_000;

    uint256 public constant MAX_INT = type(uint256).max;

    //可提取的手续费
    uint256 public paymentEthAmount;
    uint256 public paymentGasAmount;

    IEvaSafesFactory public evaSafesFactory;

    IEvabaseConfig public config;

    constructor(address _config, address _evaSafesFactory) {
        require(_evaSafesFactory != address(0), "addess is 0x");
        require(_config != address(0), "addess is 0x");
        evaSafesFactory = IEvaSafesFactory(_evaSafesFactory);
        config = IEvabaseConfig(_config);
        _flowMetas.push(
            EvaFlowMeta({
                flowStatus: FlowStatus.Unknown,
                keepNetWork: KeepNetWork.ChainLink,
                maxVaildBlockNumber: MAX_INT,
                admin: msg.sender,
                lastKeeper: address(0),
                lastExecNumber: block.number,
                lastVersionflow: address(0),
                flowName: "init",
                checkData: ""
            })
        );
    }

    function setMinConfig(MinConfig memory _minConfig) external onlyOwner {
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

    function _checkEnoughGas() internal view {
        // 需要修正
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
        IEvaSafes safes = IEvaSafes(msg.sender);
        require(safes.isEvaSafes(), "should be safes");
    }

    function isValidFlow(address flow) public pure returns (bool) {
        require(flow != address(0), "flow is 0x");
        return true; //TODO: 需要维护合法Flow清单
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
        userMetaMap[msg.sender].vaildFlowsNum += uint8(1); // 如果溢出则报错
        //检查Gas费余额是否足够
        _checkEnoughGas();
        _flowMetas.push(
            EvaFlowMeta({
                flowStatus: FlowStatus.Active,
                keepNetWork: network,
                maxVaildBlockNumber: MAX_INT,
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
    ) external override nonReentrant {
        require(_flowId < _flowMetas.length, "over bound");
        // address safeWallet = evaSafesFactory.get(msg.sender);
        // require(safeWallet != address(0), "safe wallet is 0x");
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
        require(msg.sender == _flowMetas[_flowId].admin || msg.sender == owner(), "flow's owner is not y");
        _flowMetas[_flowId].lastExecNumber = block.number;
        _flowMetas[_flowId].flowStatus = FlowStatus.Paused;

        userMetaMap[msg.sender].vaildFlowsNum = userMetaMap[msg.sender].vaildFlowsNum - 1;

        if (_flowMetas[_flowId].lastVersionflow != address(0)) {
            // _vaildFlows.remove(_flowId);
            KeepNetWork keepNetWork = _flowMetas[_flowId].keepNetWork;
            _vaildFlows[keepNetWork].remove(_flowId);
        }
        //pause flow IEvaFlow
        // IEvaFlow(_flowMetas[_flowId].lastVersionflow).pause(_flowId, _flowCode);

        emit FlowPaused(msg.sender, _flowId);
    }

    function startFlow(uint256 _flowId) external override {
        require(_flowId < _flowMetas.length, "over bound");

        require(msg.sender == _flowMetas[_flowId].admin || msg.sender == owner(), "flow's owner is not y");
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

    function destroyFlow(uint256 _flowId) external override {
        require(_flowId < _flowMetas.length, "over bound");
        require(msg.sender == _flowMetas[_flowId].admin || msg.sender == owner(), "flow's owner is not y");
        require(userMetaMap[msg.sender].vaildFlowsNum > 0, "vaildFlowsNum should gt 0");
        if (_flowMetas[_flowId].lastVersionflow != address(0)) {
            // _vaildFlows.remove(_flowId);
            KeepNetWork keepNetWork = _flowMetas[_flowId].keepNetWork;
            _vaildFlows[keepNetWork].remove(_flowId);
        }

        _flowMetas[_flowId].lastExecNumber = block.number;
        _flowMetas[_flowId].flowStatus = FlowStatus.Destroyed;
        // _flowMetas[_flowId].lastVersionflow = address(0);

        userMetaMap[msg.sender].vaildFlowsNum = userMetaMap[msg.sender].vaildFlowsNum - 1;

        emit FlowDestroyed(msg.sender, _flowId);
    }

    function addFundByUser(
        address tokenAdress,
        uint256 amount,
        // address user
        address flowAdmin
    ) public payable override nonReentrant {
        // address safeWallet = evaSafesFactory.get(user);
        // require(safeWallet != address(0), "safe wallet is 0x");
        // require(msg.sender == flowAdmin, "flow's owner is not y");
        // require(evaSafesFactory.get(user) != address(0), "safe wallet is 0x");

        if (tokenAdress == address(0)) {
            require(msg.value == amount, "value is not equal");

            userMetaMap[flowAdmin].ethBal = userMetaMap[flowAdmin].ethBal + Utils.toUint120(msg.value);
        } else {
            require(tokenAdress == minConfig.feeToken, "error FeeToken");

            userMetaMap[flowAdmin].gasTokenBal = userMetaMap[flowAdmin].gasTokenBal + Utils.toUint120(amount);

            IERC20(tokenAdress).safeTransferFrom(msg.sender, address(this), amount);
        }
    }

    function withdrawFundByUser(address tokenAdress, uint256 amount) external override nonReentrant {
        address safeWallet = msg.sender;
        // require(safeWallet != address(0), "safe wallet is 0x");
        // require(msg.sender == flowAdmin, "flow's owner is not y");

        uint256 minTotalFlow = userMetaMap[safeWallet].vaildFlowsNum * minConfig.minGasFundOneFlow;
        uint256 minTotalGas = minTotalFlow > minConfig.minGasFundForUser ? minTotalFlow : minConfig.minGasFundForUser;

        if (tokenAdress == address(0)) {
            require(userMetaMap[safeWallet].ethBal >= amount + minTotalGas);
            userMetaMap[safeWallet].ethBal = userMetaMap[safeWallet].ethBal - Utils.toUint120(amount);
            (bool sent, ) = safeWallet.call{value: amount}("");
            require(sent, "Failed to send Ether");
        } else {
            require(tokenAdress == minConfig.feeToken, "error FeeToken");

            require(userMetaMap[safeWallet].ethBal >= amount + minTotalGas);

            userMetaMap[safeWallet].gasTokenBal = userMetaMap[safeWallet].gasTokenBal - Utils.toUint120(amount);

            IERC20(tokenAdress).transfer(safeWallet, amount);
        }
    }

    function withdrawPayment(address tokenAdress, uint256 amount) external override onlyOwner {
        if (tokenAdress == address(0)) {
            require(paymentEthAmount >= amount, "");
            TransferHelper.safeTransferETH(msg.sender, amount);
            // (bool sent, ) = msg.sender.call{value: amount}("");
            // require(sent, "Failed to send Ether");
        } else {
            require(tokenAdress == minConfig.feeToken, "error FeeToken");
            require(paymentGasAmount >= amount, "");
            IERC20(tokenAdress).transfer(msg.sender, amount);
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
        uint256 gasLimit
    ) external override {
        uint256 gasTotal = 0;
        // uint256[] memory arr = Utils.decodeUints(data);
        (uint256[] memory arr, bytes[] memory executeDataArray) = Utils._decodeTwoArr(data);

        require(arr.length == executeDataArray.length, "arr is empty");

        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] > 0) {
                uint256 before = gasleft();
                execFlow(keeper, arr[i], executeDataArray[i]);
                if (gasTotal + before - gasleft() > gasLimit) {
                    return;
                }
            }
        }
    }

    function execFlow(
        address keeper,
        uint256 flowId,
        bytes memory execData
    ) public override nonReentrant {
        KeepStruct memory ks = config.getKeepBot(msg.sender);

        require(ks.isActive, "exect keeper is not whitelist");

        uint256 before = gasleft();

        EvaFlowMeta memory flow = _flowMetas[flowId];

        require(flow.admin != address(0), "task not found");
        require(flow.flowStatus == FlowStatus.Active, "task is not active");
        require((keeper != flow.lastKeeper ||  flow.keepNetWork != KeepNetWork.ChainLink), "expect next keeper");
        require(flow.maxVaildBlockNumber >= block.number, "invalid task");
        // 检查是否 flow 的网络是否和 keeper 匹配
        require(flow.keepNetWork == ks.keepNetWork, "invalid keepNetWork");

        //  flow 必须被 Safes 创建，否则无法执行execFlow
        IEvaSafes safes = IEvaSafes(flow.admin);
        bool success;
        string memory failedReason;
        try safes.execFlow(flow.lastVersionflow, execData) {
            success = true;
        } catch Error(string memory reason) {
            failedReason = reason; // revert or require
        } catch {
            failedReason = "F"; //assert
        }

        // update
        _flowMetas[flowId].lastExecNumber = block.number;
        _flowMetas[flowId].lastKeeper = keeper;

        uint256 usedGas = before - gasleft();

        uint120 payAmountByETH = 0;
        uint120 payAmountByFeeToken = 0;

        if (minConfig.feeToken == address(0)) {
            payAmountByETH = Utils.toUint120(_calculatePaymentAmount(usedGas));
            uint120 bal = userMetaMap[flow.admin].ethBal;

            if (tx.origin == address(0)) {
                //是默认交易，在check完成后将模拟调用
                require(bal >= payAmountByETH, "insufficient fund");
            }

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

    function _calculatePaymentAmount(uint256 gasLimit) private view returns (uint96 payment) {
        uint256 total;

        uint256 weiForGas = tx.gasprice * (gasLimit + _REGISTRY_GAS_OVERHEAD);
        // uint256 premium = minConfig.add(config.paymentPremiumPPB);
        total = weiForGas * (minConfig.ppb);

        //require(total <= LINK_TOTAL_SUPPLY, "payment greater than all LINK");
        return uint96(total); // LINK_TOTAL_SUPPLY < UINT96_MAX
    }

    function getSafes(address user) external view override returns (address) {
        return evaSafesFactory.get(user);
    }

    function getFlowCheckInfo(uint256 flowId) external view override returns (address flow, bytes memory checkData) {
        flow = _flowMetas[flowId].lastVersionflow;
        checkData = _flowMetas[flowId].checkData;
    }
}
