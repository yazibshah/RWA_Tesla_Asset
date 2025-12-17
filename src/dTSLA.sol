// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {ConfirmedOwner} from "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import {
    FunctionsClient
} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/FunctionsClient.sol";
import {
    FunctionsRequest
} from "@chainlink/contracts/src/v0.8/functions/dev/v1_0_0/libraries/FunctionsRequest.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {
    AggregatorV3Interface
} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/*

*/

contract dTSLA is ConfirmedOwner, FunctionsClient, ERC20 {
    using FunctionsRequest for FunctionsRequest.Request;

    enum MintOrRedeem {
        Mint,
        Redeem
    }

    struct dTslaRequest {
        uint256 amountOfToken;
        address requester;
        MintOrRedeem mintOrRedeem;
    }

    uint256 constant PRECISION = 1e18;

    address constant SEPOLIA_FUNCTIONS_ROUTER =
        0xb83E47C2bC239B3bf370bc41e1459A34b41238D0;

    uint256 constant ADDITIONAL_FEE_PRICISION = 1e10;
    bytes32 constant DON_ID =
        hex"66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000";

    address constant SEPOLIA_TSLA_PRICE_FEED =
        0xc59E3633BAAC79493d908e63626716e204A45EdF;
    uint32 constant GAS_LIMIT = 300_000;
    uint64 immutable i_subId;
    uint256 constant COLLATERAL_RATIO = 200;
    uint256 constant COLLATERAL_PRICISION = 100;

    string private s_mintSourceCode;
    uint256 private s_portfolioBalance;
    mapping(bytes32 requestId => dTslaRequest request)
        private s_requestIdToRequest;

    constructor(
        string memory mintSourceCode,
        uint64 subId
    )
        ConfirmedOwner(msg.sender)
        FunctionsClient(SEPOLIA_FUNCTIONS_ROUTER)
        ERC20("dTSLA", "dTSLA")
    {
        s_mintSourceCode = mintSourceCode;
        i_subId = subId;
    }

    /* - send an HTTP request to:
    1. see how many TSLA is bought
    2. if enough TSLA is in the account.
    mint dTSLA.
    2 transaction functions
     */
    function sendMintRequest(
        uint256 amount
    ) external onlyOwner returns (bytes32) {
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(s_mintSourceCode);
        bytes32 requestId = _sendRequest(
            req.encodeCBOR(),
            i_subId,
            GAS_LIMIT,
            DON_ID
        );
        s_requestIdToRequest[requestId] = dTslaRequest(
            amount,
            msg.sender,
            MintOrRedeem.Mint
        );
        return requestId;
    }

    // Return the amount of TSLA Value (in USD) is stored in our broker.
    // if we have enough TSLA Value (in USD) then mint dTSLA
    function _mintFulfillRequest(
        bytes32 requestId,
        bytes memory response
    ) internal {
        uint256 amountOfTokensToMint = s_requestIdToRequest[requestId]
            .amountOfToken;
        s_portfolioBalance = uint256(bytes32(response));

        // if TSLA collateral (how much TSLA we have bought) > dTSLA to mint -> mint dTSLA
        // How much TSLA in $$ do we have?
        // How much dTSLA we want to mint?

        if (
            _getCollateralRatioAdjustedTotalBalance(amountOfTokensToMint) >
            s_portfolioBalance
        ) {}
    }

    /**
        * @notice User send a Request to sell TSLA for USDC (redemption token) 
        - This function have chainlink function call our alpaca (bank) and do following.
        1. Sell TSLA on the brokerage
        2. buy USDC on the brokerage
        3. send USDC to this contract for the user to withdraw.
    */
    function sendRedeemRequest() external {}

    function _redeemFulfillRequest(
        bytes32 requestId,
        bytes memory response
    ) internal {}

    function fulfillRequest(
        bytes32 requestId,
        bytes memory response,
        bytes memory /* error */
    ) internal override {
        if (s_requestIdToRequest[requestId].mintOrRedeem == MintOrRedeem.Mint) {
            _mintFulfillRequest(requestId, response);
        } else {
            _redeemFulfillRequest(requestId, response);
        }
    }

    function _getCollateralRatioAdjustedTotalBalance(
        uint256 amountOfTokensToMint
    ) internal view returns (uint256) {
        uint256 calculatedNewTotalValue = getCalculatedNewTotalValue(
            amountOfTokensToMint
        );

        return
            (calculatedNewTotalValue * COLLATERAL_RATIO) / COLLATERAL_PRICISION;
    }

    // The new expected total value in USD of all the dTSLA tokens combined
    function getCalculatedNewTotalValue(
        uint256 addedNumberOfTokens
    ) internal view returns (uint256) {
        return
            ((totalSupply() + addedNumberOfTokens) * getTslaPrice()) /
            PRECISION;
    }

    function getTslaPrice() public view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            SEPOLIA_TSLA_PRICE_FEED
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price) * ADDITIONAL_FEE_PRICISION;
    }
}
