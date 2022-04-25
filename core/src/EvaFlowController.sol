//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;
import "./interfaces/IEvaFlowController.sol";
import {IEvaSafesFactory} from "./interfaces/IEvaSafesFactory.sol";
import {FlowStatus, KeepNetWork, EvabaseHelper} from "./lib/EvabaseHelper.sol";
import {Utils} from "./lib/Utils.sol";
import {TransferHelper} from "./lib/TransferHelper.sol";
import {IEvaSafes} from "./interfaces/IEvaSafes.sol";
import {IEvaFlow} from "./interfaces/IEvaFlow.sol";
import {IEvabaseConfig} from "./interfaces/IEvabaseConfig.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract EvaFlowController is IEvaFlowController, Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    EvaFlowMeta[] public flowMetas;
    MinConfig public minConfig;
    mapping(address => EvaUserMeta) public userMetaMap;
    // bytes4 private constant FUNC_SELECTOR = bytes4(keccak256("execute(bytes)"));

    ////need exec flows
    using EvabaseHelper for EvabaseHelper.UintSet;
    mapping(KeepNetWork => EvabaseHelper.UintSet) vaildFlows;
    // EvabaseHelper.UintSet vaildFlows;
    uint256 private constant REGISTRY_GAS_OVERHEAD = 80_000;
    // using LibSingleList for LibSingleList.List;
    // using LibSingleList for LibSingleList.Iterate;
    // LibSingleList.List vaildFlows;

    uint256 public constant MAX_INT = 2 ^ (256 - 1);

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
        flowMetas.push(
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
            _minConfig.PPB,
            _minConfig.blockCountPerTurn
        );
    }

    function checkEnoughGas() internal view {
        //TODO: 需要修正
        bool isEnoughGas = true;
        unchecked {
            if (minConfig.feeToken == address(0)) {
                isEnoughGas =
                    (msg.value + userMetaMap[msg.sender].ethBal >=
                        minConfig.minGasFundForUser) &&
                    (msg.value + userMetaMap[msg.sender].ethBal >=
                        (userMetaMap[msg.sender].vaildFlowsNum + 1) *
                            minConfig.minGasFundOneFlow);
            } else {
                isEnoughGas =
                    (userMetaMap[msg.sender].gasTokenBal >=
                        minConfig.minGasFundForUser) &&
                    (userMetaMap[msg.sender].gasTokenBal >=
                        (userMetaMap[msg.sender].vaildFlowsNum + 1) *
                            minConfig.minGasFundOneFlow);
            }
        }

        require(isEnoughGas, "gas balance is not enough");
    }

    function _beforeCreateFlow(KeepNetWork _keepNetWork) internal {
        //check SafeWallet
        require(
            evaSafesFactory.get(msg.sender) != address(0),
            "safe wallet is 0x"
        );
        require(
            uint256(_keepNetWork) <= uint256(KeepNetWork.Others),
            "invalid netWork"
        );
    }

    function isValidFlow(address flow) public returns (bool) {
        return true; //TODO: 需要维护合法Flow清单
    }

    function _appendFee(address acct, uint256 amount) private {
        userMetaMap[msg.sender].ethBal += Utils.toUint120(amount);
    }

    function registerFlow(
        string memory name,
        KeepNetWork network,
        address flow,
        bytes memory checkdata
    ) external payable override returns (uint256 flowId) {
        require(isValidFlow(flow), "invalid flow");
        require(network <= KeepNetWork.Others, "invalid netWork");
        _appendFee(msg.sender, msg.value);
        userMetaMap[msg.sender].vaildFlowsNum += uint8(1); // 如果溢出则报错
        //TODO: 检查Gas费余额
        flowMetas.push(
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
        flowId = flowMetas.length - 1;
        vaildFlows[network].add(flowId);
        emit FlowCreated(msg.sender, flowId, flow);
    }

    function updateFlow(
        uint256 _flowId,
        string memory _flowName,
        bytes memory _flowCode
    ) external override nonReentrant {
        require(_flowId < flowMetas.length, "over bound");
        require(
            msg.sender == flowMetas[_flowId].admin,
            "flow's owner is not y"
        );
        require(
            FlowStatus.Active == flowMetas[_flowId].flowStatus ||
                FlowStatus.Paused == flowMetas[_flowId].flowStatus,
            "flow's status is error"
        );

        KeepNetWork _keepNetWork = flowMetas[_flowId].keepNetWork;

        _beforeCreateFlow(_keepNetWork);
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
        // vaildFlows.remove(_flowId);
        vaildFlows[_keepNetWork].remove(_flowId);
        flowMetas[_flowId].flowName = _flowName;
        flowMetas[_flowId].lastKeeper = address(0);
        flowMetas[_flowId].lastExecNumber = block.number;
        flowMetas[_flowId].lastVersionflow = addr;
        // vaildFlows.add(_flowId);
        vaildFlows[_keepNetWork].add(_flowId);

        emit FlowUpdated(msg.sender, _flowId, addr);
    }

    function pauseFlow(uint256 _flowId, bytes memory _flowCode)
        external
        override
    {
        require(_flowId < flowMetas.length, "over bound");
        require(
            userMetaMap[msg.sender].vaildFlowsNum > 0,
            "vaildFlowsNum should gt 0"
        );
        require(
            FlowStatus.Active == flowMetas[_flowId].flowStatus,
            "flow's status is error"
        );
        require(
            msg.sender == flowMetas[_flowId].admin || msg.sender == owner(),
            "flow's owner is not y"
        );
        flowMetas[_flowId].lastExecNumber = block.number;
        flowMetas[_flowId].flowStatus = FlowStatus.Paused;

        unchecked {
            userMetaMap[msg.sender].vaildFlowsNum =
                userMetaMap[msg.sender].vaildFlowsNum -
                1;
        }

        if (flowMetas[_flowId].lastVersionflow != address(0)) {
            // vaildFlows.remove(_flowId);
            KeepNetWork _keepNetWork = flowMetas[_flowId].keepNetWork;
            vaildFlows[_keepNetWork].remove(_flowId);
        }
        //pause flow IEvaFlow
        IEvaFlow(flowMetas[_flowId].lastVersionflow).pause(_flowId, _flowCode);

        emit FlowPaused(msg.sender, _flowId);
    }

    function startFlow(uint256 _flowId, bytes memory _flowCode)
        external
        override
    {
        require(_flowId < flowMetas.length, "over bound");

        require(
            msg.sender == flowMetas[_flowId].admin || msg.sender == owner(),
            "flow's owner is not y"
        );
        require(
            FlowStatus.Paused == flowMetas[_flowId].flowStatus,
            "flow's status is error"
        );
        flowMetas[_flowId].lastExecNumber = block.number;
        flowMetas[_flowId].flowStatus = FlowStatus.Active;

        unchecked {
            userMetaMap[msg.sender].vaildFlowsNum =
                userMetaMap[msg.sender].vaildFlowsNum +
                1;
        }

        if (flowMetas[_flowId].lastVersionflow != address(0)) {
            // vaildFlows.add(_flowId);
            KeepNetWork _keepNetWork = flowMetas[_flowId].keepNetWork;
            vaildFlows[_keepNetWork].add(_flowId);
        }

        //start flow IEvaFlow
        IEvaFlow(flowMetas[_flowId].lastVersionflow).start(_flowId, _flowCode);

        emit FlowStart(msg.sender, _flowId);
    }

    function destroyFlow(uint256 _flowId, bytes memory _flowCode)
        external
        override
    {
        require(_flowId < flowMetas.length, "over bound");
        require(
            msg.sender == flowMetas[_flowId].admin || msg.sender == owner(),
            "flow's owner is not y"
        );
        require(
            userMetaMap[msg.sender].vaildFlowsNum > 0,
            "vaildFlowsNum should gt 0"
        );
        if (flowMetas[_flowId].lastVersionflow != address(0)) {
            // vaildFlows.remove(_flowId);
            KeepNetWork _keepNetWork = flowMetas[_flowId].keepNetWork;
            vaildFlows[_keepNetWork].remove(_flowId);
        }

        flowMetas[_flowId].lastExecNumber = block.number;
        flowMetas[_flowId].flowStatus = FlowStatus.Destroyed;
        // flowMetas[_flowId].lastVersionflow = address(0);
        unchecked {
            userMetaMap[msg.sender].vaildFlowsNum =
                userMetaMap[msg.sender].vaildFlowsNum -
                1;
        }
        //destroy flow IEvaFlow
        IEvaFlow(flowMetas[_flowId].lastVersionflow).destroy(
            _flowId,
            _flowCode
        );
        emit FlowDestroyed(msg.sender, _flowId);
    }

    function addFundByUser(
        address tokenAdress,
        uint256 amount,
        address user
    ) public payable override nonReentrant {
        require(evaSafesFactory.get(user) != address(0), "safe wallet is 0x");

        unchecked {
            if (tokenAdress == address(0)) {
                require(msg.value == amount, "value is not equal");
                userMetaMap[user].ethBal =
                    userMetaMap[user].ethBal +
                    Utils.toUint120(msg.value);
            } else {
                require(tokenAdress == minConfig.feeToken, "error FeeToken");

                userMetaMap[user].gasTokenBal =
                    userMetaMap[user].gasTokenBal +
                    Utils.toUint120(amount);

                IERC20(tokenAdress).safeTransferFrom(
                    user,
                    address(this),
                    amount
                );
            }
        }
    }

    function withdrawFundByUser(address tokenAdress, uint256 amount)
        external
        override
        nonReentrant
    {
        require(
            evaSafesFactory.get(msg.sender) != address(0),
            "safe wallet is 0x"
        );
        unchecked {
            //        uint64 minGasFundForUser;
            // uint64 minGasFundOneFlow;
            uint256 minTotalFlow = userMetaMap[msg.sender].vaildFlowsNum *
                minConfig.minGasFundOneFlow;
            uint256 minTotalGas = minTotalFlow > minConfig.minGasFundForUser
                ? minTotalFlow
                : minConfig.minGasFundForUser;

            if (tokenAdress == address(0)) {
                require(userMetaMap[msg.sender].ethBal >= amount + minTotalGas);
                userMetaMap[msg.sender].ethBal =
                    userMetaMap[msg.sender].ethBal -
                    Utils.toUint120(amount);
                (bool sent, bytes memory data) = msg.sender.call{value: amount}(
                    ""
                );
                require(sent, "Failed to send Ether");
            } else {
                require(tokenAdress == minConfig.feeToken, "error FeeToken");

                require(userMetaMap[msg.sender].ethBal >= amount + minTotalGas);

                userMetaMap[msg.sender].gasTokenBal =
                    userMetaMap[msg.sender].gasTokenBal -
                    Utils.toUint120(amount);

                IERC20(tokenAdress).transfer(msg.sender, amount);
            }
        }
    }

    function withdrawPayment(address tokenAdress, uint256 amount)
        external
        override
        onlyOwner
    {
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

    function getIndexVaildFlow(uint256 _index, KeepNetWork _keepNetWork)
        external
        view
        override
        returns (uint256 value)
    {
        return vaildFlows[_keepNetWork].get(_index);
    }

    function getVaildFlowRange(
        uint256 fromIndex,
        uint256 endIndex,
        KeepNetWork _keepNetWork
    ) external view override returns (uint256[] memory arr) {
        return vaildFlows[_keepNetWork].getRange(fromIndex, endIndex);
    }

    function getAllVaildFlowSize(KeepNetWork _keepNetWork)
        external
        view
        override
        returns (uint256 size)
    {
        return vaildFlows[_keepNetWork].getSize();
    }

    function getFlowMetas(uint256 index)
        external
        view
        override
        returns (EvaFlowMeta memory)
    {
        return flowMetas[index];
    }

    function batchExecFlow(
        address keeper,
        bytes memory _data,
        uint256 gasLimit
    ) external override {
        uint256 gasTotal = 0;
        // uint256[] memory arr = Utils.decodeUints(_data);
        (uint256[] memory arr, bytes[] memory executeDataArray) = Utils
            ._decodeTwoArr(_data);

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
        require(config.isKeeper(msg.sender), "exect keeper is not whitelist");

        uint256 before = gasleft();

        EvaFlowMeta memory flow = flowMetas[flowId];

        require(flow.admin != address(0), "task not found");
        require(flow.flowStatus == FlowStatus.Active, "task is not active");
        require(keeper != flow.lastKeeper, "expect next keeper");
        require(flow.maxVaildBlockNumber >= block.number, "invalid task");
        // TODO: 检查是否 flow 的网络是否和 keeper 匹配

        IEvaSafes safes = IEvaSafes(evaSafesFactory.get(flow.admin));

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
        flowMetas[flowId].lastExecNumber = block.number;
        flowMetas[flowId].lastKeeper = keeper;

        uint256 usedGas = before - gasleft();

        uint120 payAmountByETH = 0;
        uint120 payAmountByFeeToken = 0;

        if (minConfig.feeToken == address(0)) {
            payAmountByETH = Utils.toUint120(calculatePaymentAmount(usedGas));
            uint120 bal = userMetaMap[flow.admin].ethBal;

            if (tx.origin == address(0)) {
                //是默认交易，在check完成后将模拟调用
                require(bal >= payAmountByETH, "insufficient fund");
            }

            userMetaMap[flow.admin].ethBal = bal < payAmountByETH
                ? 0
                : bal - payAmountByETH;
        } else {
            revert("TODO");
        }

        if (success) {
            emit FlowExecuteSuccess(
                flow.admin,
                flowId,
                payAmountByETH,
                payAmountByFeeToken,
                usedGas
            );
        } else {
            emit FlowExecuteFailed(
                flow.admin,
                flowId,
                payAmountByETH,
                payAmountByFeeToken,
                usedGas,
                failedReason
            );
        }
    }

    function calculatePaymentAmount(uint256 gasLimit)
        private
        view
        returns (uint96 payment)
    {
        uint256 total;
        unchecked {
            uint256 weiForGas = tx.gasprice *
                (gasLimit + REGISTRY_GAS_OVERHEAD);
            // uint256 premium = minConfig.add(config.paymentPremiumPPB);
            total = weiForGas * (minConfig.PPB);
        }
        //require(total <= LINK_TOTAL_SUPPLY, "payment greater than all LINK");
        return uint96(total); // LINK_TOTAL_SUPPLY < UINT96_MAX
    }

    function getSafes(address user) external view override returns (address) {
        return evaSafesFactory.get(user);
    }

    function getFlowCheckData(uint256 flowId)
        external
        view
        override
        returns (bytes memory)
    {
        return flowMetas[flowId].checkData;
    }

    // function execNftLimitOrderFlow(
    //     uint256 _flowId,
    //     uint256 _orderId,
    //     uint256 _value,
    //     address _admin,
    //     uint8 _marketType,
    //     bytes memory _execMarketData
    // ) external nonReentrant {
    //     require(config.isKeeper(msg.sender), "exect keeper is not whitelist");
    //     uint256 before = gasleft();
    //     EvaFlowMeta memory flowMeta = flowMetas[_flowId];
    //     bool _sucess;
    //     if (
    //         flowMeta.flowStatus == FlowStatus.Active &&
    //         flowMeta.maxVaildBlockNumber >= block.number
    //     ) {
    //         address safesAdd = evaSafesFactory.get(_admin);
    //         if (safesAdd != address(0)) {
    //             bytes[] memory data = new bytes[](1);
    //             data[0] = abi.encode(
    //                 flowMeta.lastVersionflow,
    //                 abi.encodeWithSelector(IEvaFlow.execute.selector, "")
    //             );

    //             try
    //                 IEvaSafes(safesAdd).multicallWithValue(_flowId, data)
    //             returns (bytes[] memory results) {
    //                 // update
    //                 flowMetas[_flowId].lastExecNumber = block.number;
    //                 flowMetas[_flowId].lastKeeper = msg.sender;
    //             } catch {
    //                 _sucess = false;
    //             }

    //             uint256 payAmountByETH = 0;
    //             uint256 payAmountByFeeToken = 0;
    //             uint256 afterGas = gasleft();

    //             unchecked {
    //                 if (minConfig.feeToken == address(0)) {
    //                     payAmountByETH = calculatePaymentAmount(
    //                         before - afterGas
    //                     );

    //                     require(payAmountByETH < userMetaMap[_admin].ethBal);
    //                     userMetaMap[_admin].ethBal =
    //                         userMetaMap[_admin].ethBal -
    //                         payAmountByETH;
    //                 } else {
    //                     //todo
    //                 }
    //             }
    //             emit FlowExecuted(
    //                 msg.sender,
    //                 _flowId,
    //                 _sucess,
    //                 payAmountByETH,
    //                 payAmountByFeeToken
    //             );
    //         }
    //     }
    // }

    // function addEvabaseFlowByOwner(
    //     address evabaseFlowAdd,
    //     KeepNetWork _keepNetWork,
    //     string memory name,
    //     bytes memory _checkdata
    // ) external onlyOwner {
    //     flowMetas.push(
    //         EvaFlowMeta({
    //             flowStatus: FlowStatus.Active,
    //             keepNetWork: _keepNetWork,
    //             maxVaildBlockNumber: MAX_INT,
    //             admin: msg.sender,
    //             lastKeeper: address(0),
    //             lastExecNumber: block.number,
    //             lastVersionflow: evabaseFlowAdd,
    //             flowName: name,
    //             checkData: _checkdata
    //         })
    //     );
    //     emit FlowCreated(msg.sender, flowMetas.length - 1, evabaseFlowAdd);
    // }
}
