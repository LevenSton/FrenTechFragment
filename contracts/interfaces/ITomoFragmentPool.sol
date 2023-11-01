// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {DataTypes} from "../libraries/DataTypes.sol";

/**
 * @title ITomoFragmentPool
 * @author Tomo Protocol
 *
 * @notice This is the interface for the TomoFragmentPool contract, the pool of key Fragment.
 * You'll find all the events and external functions, as well as the reasoning behind them here.
 */
interface ITomoFragmentPool {
    /**
     * @notice Buy And Fragment Key/Vote.
     * @param subject Identity of one tomo.
     * @param fragmentParam The param which one key can split to
     * @param protocolFeeAddress The protocol fee Address.
     */
    function initialize(
        bytes32 subject,
        uint256 fragmentParam,
        address protocolFeeAddress
    ) external;

    /**
     * @notice Sell the Fragment Key/Vote.
     *
     * @param amount The sell amount.
     * @param maxAcceptPrice The min price seller can accept.
     * @param buyer The address of buyer
     */
    function buyFragmentVotePass(
        uint256 amount,
        uint256 maxAcceptPrice,
        address payable buyer
    ) external payable returns (uint256);

    /**
     * @notice Sell the Fragment Key/Vote.
     *
     * @param amount The sell amount.
     * @param minAcceptPrice The min price seller can accept.
     * @param seller The seller address.
     */
    function sellFragmentVotePass(
        uint256 amount,
        uint256 minAcceptPrice,
        address payable seller
    ) external returns (uint256);

    /**
     * @notice Add Key/Vote liquidity. all liquidity provider share all _currentLiquidity and eth in contract, so not record the fragment balance of liquidity provider
     *
     * @param liquidityProvider The liquidity provider address.
     * @param keyAmount The key amount
     * @param deadline The deadline this liquidity can quit
     */
    function addKeyLiquidity(
        address liquidityProvider,
        uint256 keyAmount,
        uint256 deadline
    ) external;

    /**
     * @notice Add ETH liquidity.
     *
     * @param ethLiquidityProvider The eth provider address.
     * @param deadline The deadline this liquidity can quit
     */
    function addETHLiquidity(
        address payable ethLiquidityProvider,
        uint256 deadline
    ) external payable returns (uint256);

    /**
     * @notice get fragment param.
     */
    function _fragmentParam() external view returns (uint256);

    /**
     * @notice quit from liquidity provider, get back all votepass and eth reward.
     * if hold amount large than _fragmentParam, sell whole votepass to tomo contract, if any left fragment votepass, sell to other liquidity provider
     *
     * @param quitor Address who want to quit liquidity provider.
     */
    function quitFromLiquidityProvider(address payable quitor) external;

    /**
     * @notice query how mant fragment votepass and eth can get if quit the liquidity
     *
     * @param quitor Address who want to quit liquidity provider.
     */
    function getVotePassAndEthIfQuit(
        address quitor
    ) external view returns (uint256, uint256, uint256, uint256);

    function getSellPriceAfterFee(
        uint256 amount
    ) external view returns (uint256, uint256);

    function getBuyPriceAfterFee(
        uint256 amount
    ) external view returns (uint256, uint256);
}
