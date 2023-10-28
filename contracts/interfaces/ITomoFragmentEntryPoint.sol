// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {DataTypes} from "../libraries/DataTypes.sol";

/**
 * @title ITomoFragment
 * @author Tomo Protocol
 *
 * @notice This is the interface for the TomoSplit contract, the main entry point for Buy/Sell Fragment.
 * You'll find all the events and external functions, as well as the reasoning behind them here.
 */
interface ITomoFragmentEntryPoint {
    /**
     * @notice initialize smart contract.
     * @param newGovernanceContractAddress The governance address to set.
     * @param minPriceKeyCanFragment The Min Price of key can fragment.
     */
    function initialize(
        address newGovernanceContractAddress,
        uint256 minPriceKeyCanFragment
    ) external;

    /// ***************************************
    /// *****About Fragment Pool Liquidity*****
    /// ***************************************

    /**
     * @notice Buy And Fragment Key/Vote.
     * @param subject Identity of one tomo.
     * @param amount The buy amount.
     * @param fragmentAmount The amount of each key can fragment
     * @param maxAcceptPrice The max price that call can pay for amount key.
     * @param v The V of signature
     * @param r The r of signature
     * @param s The s of signature
     */
    function buyVotePassAndFragment(
        bytes32 subject,
        uint256 amount,
        uint256 fragmentAmount,
        uint256 maxAcceptPrice,
        uint8[] calldata v,
        bytes32[] calldata r,
        bytes32[] calldata s
    ) external payable;

    /**
     * @notice Sell the Fragment Key/Vote.
     *
     * @param subject Identity of one tomo.
     * @param amount The sell amount.
     * @param maxAcceptPrice The min price seller can accept.
     */
    function buyFragmentVotePass(
        bytes32 subject,
        uint256 amount,
        uint256 maxAcceptPrice
    ) external payable;

    /**
     * @notice Sell the Fragment Key/Vote.
     *
     * @param subject Identity of one tomo.
     * @param amount The sell amount.
     * @param minAcceptPrice The min price seller can accept.
     */
    function sellFragmentVotePass(
        bytes32 subject,
        uint256 amount,
        uint256 minAcceptPrice
    ) external;

    /**
     * @notice Sell the Key/Vote.
     * only can be called from FragmentPool address to help sell whole key to tomo
     *
     * @param subject Identity of one tomo.
     * @param seller The address of seller
     * @param amount The sell amount.
     */
    function sellVotePass(
        bytes32 subject,
        address seller,
        uint256 amount
    ) external;

    /**
     * @notice add eth liquidity for key pool.
     * only can be called from FragmentPool address to help sell whole key to tomo
     *
     * @param subject Identity of one tomo.
     */
    function addETHLiquidity(bytes32 subject) external payable;

    /**
     * @notice quit from liquidity provider, get back all votepass and eth reward.
     * send whole votepass to tomo contract, if have left fragment votepass, become a normal user who hold fragment vote pass, than can sell to other liquidity provider
     * only can be called from FragmentPool address to help sell whole key to tomo
     *
     * @param subject Identity of one tomo.
     */
    function quitFromLiquidityProvider(bytes32 subject) external;

    /// ***************************************
    /// *****About lock/burn/transfer**********
    /// ***************************************

    /**
     * @notice buy VotePass and set a lock time, can sell if timestame less than you set
     *
     * @param subject Identity of one tomo.
     * @param amount The buy amount.
     * @param maxAcceptPrice The max price that call can pay for amount key.
     * @param v The V of signature
     * @param r The r of signature
     * @param s The s of signature
     */
    function buyVotePassWithLockTimeStamp(
        bytes32 subject,
        uint256 amount,
        uint256 maxAcceptPrice,
        uint256 lockUntil,
        uint8[] calldata v,
        bytes32[] calldata r,
        bytes32[] calldata s
    ) external payable;

    /**
     * @notice sell Vote Pass after be unlocked
     *
     * @param lockIndex locke index
     * @param amount sell amount
     * @param minAcceptPrice minAcceptPrice The min price seller can accept.
     */
    function sellLockVotePass(
        uint256 lockIndex,
        uint256 amount,
        uint256 minAcceptPrice,
        address payable receiveFund
    ) external;

    /**
     * @notice transfer lock Vote Pass to other
     *
     * @param lockIndex locke index
     * @param to the address receipt lock vote pass
     */
    function transferLockVotePass(uint256 lockIndex, address to) external;

    /**
     * @notice get all lock index by address
     *
     * @param locker locker address
     */
    function getAllLockIndexByAddress(
        address locker
    ) external view returns (uint256[] memory);

    /**
     * @notice get Lock Info by index
     *
     * @param index LockIndex
     */
    function getLockInfoByIndex(
        uint256 index
    ) external view returns (DataTypes.VotePassLockInfo memory);
}
