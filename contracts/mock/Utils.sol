// SPDX-License-Identifier: GPL-2.0-or-later
// Copy from https://github.com/Uniswap/v3-periphery/blob/main/contracts/libraries/TransferHelper.sol
pragma solidity ^0.8.0;

library Utils {
    function getAvail(
        uint256 allVaildSize,
        uint256 keepBotSize,
        uint256 keepbotId,
        uint32 batch
    ) internal pure returns (uint256 start, uint256 end) {
        require(keepBotSize > 0 && allVaildSize > 0 && keepbotId > 0, "gt 0");
        if (allVaildSize > keepBotSize) {
            uint256 quotient = allVaildSize / keepBotSize;
            uint256 remainder = allVaildSize % keepBotSize;

            if (remainder != 0) {
                quotient++;
            }

            bool isUseBatch = batch < quotient;

            if (isUseBatch) {
                quotient = batch;
            }

            start = (keepbotId - 1) * quotient + 1;
            end = keepbotId * quotient;

            if (!isUseBatch && remainder != 0 && keepbotId == keepBotSize) {
                end = allVaildSize;
            }
        } else {
            start = keepbotId;
            end = keepbotId;
        }

        return (start, end);
    }
}
