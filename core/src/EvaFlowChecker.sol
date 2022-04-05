//SPDX-License-Identifier: MIT
//Create by Openflow.network core team.
pragma solidity ^0.8.0;
import {IEvabaseConfig} from "./interfaces/IEvabaseConfig.sol";
import {IEvaFlow} from "./interfaces/IEvaFlow.sol";
import {IEvaFlowControler} from "./interfaces/IEvaFlowControler.sol";

contract EvaFlowChecker {
    IEvabaseConfig public config;
    IEvaFlowControler public evaFlowControler;

    uint32 public constant checkGasLimitMin = 4_000_0;
    uint32 private constant GAS_LIMIT = 2_000_000;
    uint256 public lastMoveTime;

    constructor(address _config, address _evaFlowControler) {
        require(_evaFlowControler != address(0), "addess is 0x");
        require(_config != address(0), "addess is 0x");

        evaFlowControler = IEvaFlowControler(_evaFlowControler);
        config = IEvabaseConfig(_config);
        lastMoveTime = block.timestamp;
    }

    function check(
        uint256 keepbotId,
        uint256 checkGasLimit,
        bytes memory checkdata
    ) external returns (bool needExec, bytes memory execData) {
        uint32 batch = config.batchFlowNum();
        uint32 keepBotSize = config.keepBotSize();
        uint256 allVaildSize = evaFlowControler.getAllVaildFlowSize();
        uint256 bot1start = getRandomStart(allVaildSize);
        (uint256 start, uint256 end) = getAvailCircle(
            allVaildSize,
            keepBotSize,
            keepbotId,
            batch,
            bot1start
        );

        uint256[] memory tmp = ring(start, end, allVaildSize, checkdata);
        execData = encodeUints(tmp);

        return (needExec, execData);
    }

    function setLastMoveTime() external {
        if (block.timestamp - lastMoveTime >= 10 seconds) {
            lastMoveTime = block.timestamp;
        }
    }

    function ring(
        uint256 start,
        uint256 end,
        uint256 allVaildSize,
        bytes memory checkdata
    ) internal view returns (uint256[] memory tmp) {
        uint256 j = 0;
        uint256 length = 0;
        if (start > end) {
            // start - allVaildSize
            length = allVaildSize - start + end + 1;
            tmp = new uint256[](length);
            (tmp, j) = addVaildFlowIndex(
                start,
                allVaildSize,
                tmp,
                checkdata,
                j
            );
            // 0 - end
            (tmp, j) = addVaildFlowIndex(0, end, tmp, checkdata, j);
        } else {
            length = end - start;
            tmp = new uint256[](length);
            addVaildFlowIndex(start, end, tmp, checkdata, j);
        }

        return tmp;
    }

    function addVaildFlowIndex(
        uint256 start,
        uint256 end,
        uint256[] memory tmp,
        bytes memory checkdata,
        uint256 j
    ) internal view returns (uint256[] memory arr, uint256 k) {
        uint256 totalGas;
        for (uint256 i = start; i < end; i++) {
            uint256 beforGas = gasleft();
            uint256 index = evaFlowControler.getIndexVaildFlow(i);

            // checkGasLimit/checkdata?
            if (index != uint256(0)) {
                (bool needExec, ) = IEvaFlow(
                    evaFlowControler.getFlowMetas(index).lastVersionflow
                ).check(checkdata);
                uint256 afterGas = gasleft();
                totalGas = totalGas + beforGas - afterGas;
                if (totalGas > GAS_LIMIT || afterGas < checkGasLimitMin) {
                    return (tmp, j);
                }
                if (needExec) {
                    tmp[j++] = index;
                }
            }
        }

        return (tmp, j);
    }

    function getAvailCircle(
        uint256 allVaildSize,
        uint256 keepBotSize,
        uint256 keepbotN,
        uint32 batch,
        uint256 bot1start
    ) internal view returns (uint256 botNIndexS, uint256 botNIndexE) {
        require(keepBotSize > 0 && allVaildSize > 0 && keepbotN > 0, "gt 0");

        unchecked {
            uint256 quotient = allVaildSize / keepBotSize;
            uint256 remainder = allVaildSize % keepBotSize;

            if (remainder != 0) {
                quotient++;
            }

            bool isUseBatch = batch < quotient;

            if (isUseBatch) {
                quotient = batch;
            }

            //first find should index
            botNIndexS = bot1start + (keepbotN - 1) * quotient;
            botNIndexE = bot1start + keepbotN * quotient;

            //Both of these are outside the circle
            if (botNIndexS >= allVaildSize) {
                botNIndexS = botNIndexS - allVaildSize;
                botNIndexE = botNIndexE - allVaildSize;

                if (botNIndexS > bot1start) {
                    botNIndexS = botNIndexS % allVaildSize;
                    botNIndexE = botNIndexE % allVaildSize;
                }
            } else {
                if (botNIndexE > allVaildSize) {
                    botNIndexE = botNIndexE - allVaildSize - 1;
                    if (botNIndexE >= bot1start) {
                        botNIndexE = bot1start;
                    }
                }
            }
        }

        return (botNIndexS, botNIndexE);
    }

    function getRandomStart(uint256 flowSize)
        internal
        view
        returns (uint256 index)
    {
        if (block.timestamp - lastMoveTime >= 10 seconds) {
            index =
                uint256(keccak256(abi.encodePacked(block.timestamp))) %
                flowSize;
        } else {
            index =
                uint256(keccak256(abi.encodePacked(lastMoveTime))) %
                flowSize;
        }
    }

    function encodeUints(uint256[] memory _uint)
        public
        pure
        returns (bytes memory)
    {
        return (abi.encode(_uint));
    }

    function decodeUints(bytes memory data)
        public
        pure
        returns (uint256[] memory _uint2)
    {
        _uint2 = abi.decode(data, (uint256[]));
    }
}
