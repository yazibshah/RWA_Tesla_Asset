// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";

/*

*/

contract dTSLA is ConfirmedOwner {
    constructor() ConfirmedOwner(msg.sender) {}

    /* - send an HTTP request to:
    1. see how many TSLA is bought
    2. if enough TSLA is in the account.
    mint dTSLA.
    2 transaction functions
     */
    function sendMintRequest(uint256 amount) external onlyOwner {}

    function _mintFulfillRequest() internal {}

    /**
        * @notice User send a Request to sell TSLA for USDC (redemption token) 
        - This function have chainlink function call our alpaca (bank) and do following.
        1. Sell TSLA on the brokerage
        2. buy USDC on the brokerage
        3. send USDC to this contract for the user to withdraw.
    */
    function sendRedeemRequest() external {}

    function _redeemFulfillRequest() internal {}
}
