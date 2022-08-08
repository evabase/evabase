//SPDX-License-Identifier: MIT
//Create by Openflow.network core team.
pragma solidity ^0.8.0;
import "../venders/chainlink/AggregatorV3Interface.sol";

contract ChainLinkDataFeedGetter {
    ///@notice wrap chainlink dataFeed
    function latestRoundAnswer(AggregatorV3Interface dataFeed) external view returns (int256) {
        (, int256 answer, , uint256 updatedAt, ) = dataFeed.latestRoundData();
        // solhint-disable not-rely-on-time
        require(updatedAt + 24 hours >= block.timestamp, "bad data feed");
        return answer;
    }

    ///@notice When comparing to a constant, you need to zoom in decimals times
    function decimals(AggregatorV3Interface dataFeed) external view returns (uint8) {
        return dataFeed.decimals();
    }
}
