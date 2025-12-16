// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/libraries/FunctionsRequest.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/*

*/

contract dTSLA is ConfirmedOwner, FunctionsClient, ERC20{

    using FunctionsRequest for FunctionsRequest.Request;

    enum MintOrRedeem {
        Mint,
        Redeem
    }

    struct dTslaRequest{
        uint256 amountOfToken;
        address requester;
        MintOrRedeem mintOrRedeem;
    }

    address  constant SEPOLIA_FUNCTIONS_ROUTER = 0xb83E47C2bC239B3bf370bc41e1459A34b41238D0;
    bytes32 constant DON_ID= hex"66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000";
    uint32 constant GAS_LIMIT = 300_000;
    uint64 immutable i_subId;

    string private s_mintSourceCode;
    uint256 private s_portfolioBalance;
    mapping(bytes32 requestId => dTslaRequest request) private s_requestIdToRequest;

    constructor(string memory mintSourceCode, uint64 subId) ConfirmedOwner(msg.sender) FunctionsClient(SEPOLIA_FUNCTIONS_ROUTER){
        s_mintSourceCode= mintSourceCode;
        i_subId = subId;
    }

    /* - send an HTTP request to:
    1. see how many TSLA is bought
    2. if enough TSLA is in the account.
    mint dTSLA.
    2 transaction functions
     */
    function sendMintRequest(uint256 amount) external onlyOwner {
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(s_mintSourceCode);
        bytes32 requestId = _sendRequest(req.encodeCBOR(),i_subId,GAS_LIMIT, DON_ID);  
        s_requestIdToRequest[requestId] = dTslaRequest({amount, msg.sender, MintOrRedeem.mint});
        return requestId;
    }

    // Return the amount of TSLA Value (in USD) is stored in our broker.
    // if we have enough TSLA Value (in USD) then mint dTSLA
    function _mintFulfillRequest(bytes32 requestId, bytes memory response) internal {
        uint256 amountOfTokensToMint = s_requestIdToRequest[requestId].amountOfToken;
        s_portfolioBalance = uint256(bytes32(response));

        // if TSLA collateral (how much TSLA we have bought) > dTSLA to mint -> mint dTSLA
        // How much TSLA in $$ do we have?
        // How much dTSLA we want to mint?

        if(_getCollateralRatioAdjustedTotalBalance(amountOfTokensToMint) > s_portfolioBalance){
            
        }
    }

    /**
        * @notice User send a Request to sell TSLA for USDC (redemption token) 
        - This function have chainlink function call our alpaca (bank) and do following.
        1. Sell TSLA on the brokerage
        2. buy USDC on the brokerage
        3. send USDC to this contract for the user to withdraw.
    */
    function sendRedeemRequest() external {} 

    function _redeemFulfillRequest(bytes32 requestId, bytes memory response) internal {}

    function fulfilRequest(bytes requestId, bytes memory response, bytes memory /* error */) internal override {
        if(s_requestIdToRequest[requestId].mintOrRedeem == MintOrRedeem.mint){
            _mintFulfillRequest(requestId, response);
        }else{
            _redeemFulfillRequest(requestId, response);
        }
    } 

    function _getCollateralRatioAdjustedTotalBalance(uint256 amountOfTokensToMint) view internal returns(uint256){
        uint256 calculatedNewTotalValue = getCalculatedNewTotalValue(amountOfTokensToMint);
        
    }

    // The new expected total value in USD of all the dTSLA tokens combined
    function getCalculatedNewTotalValue(uint256 addedNumberOfTokens) internal view returns(uint256){
        return ((totalSupply() + addedNumberOfTokens) * getTslaPrice()) / PRECISION;
    }

}