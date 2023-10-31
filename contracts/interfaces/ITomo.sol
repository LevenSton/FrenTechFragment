// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

/**
 * @title ITomo
 * @author Tomo Protocol
 *
 */
interface ITomo {
    /**
     * @notice Buy Key/Vote.
     *
     * @param subject Identity of one tomo.
     * @param amount The buy amount.
     * @param v v of signature.
     * @param r r of signature.
     * @param s s of signature.
     */
    function buyVotePass(
        bytes32 subject,
        uint256 amount,
        uint8[] calldata v,
        bytes32[] calldata r,
        bytes32[] calldata s
    ) external payable;

    /**
     * @notice Sell Key/Vote.
     *
     * @param subject Identity of one tomo.
     * @param amount The sell amount
     */
    function sellVotePass(bytes32 subject, uint256 amount) external;

    /**
     * @notice get total price with buy amout key of subject.
     *
     * @param subject Identity of one tomo.
     * @param amount The buy amount
     */
    function getBuyPrice(
        bytes32 subject,
        uint256 amount
    ) external view returns (uint256);

    /**
     * @notice get total price with sell amout key of subject.
     *
     * @param subject Identity of one tomo.
     * @param amount The sell amount
     */
    function getSellPrice(
        bytes32 subject,
        uint256 amount
    ) external view returns (uint256);

    /**
     * @notice get total price after fee with buy amout key of subject.
     *
     * @param subject Identity of one tomo.
     * @param amount The buy amount
     */
    function getBuyPriceAfterFee(
        bytes32 subject,
        uint256 amount
    ) external view returns (uint256);

    /**
     * @notice get total price after fee with sell amout key of subject.
     *
     * @param subject Identity of one tomo.
     * @param amount The sell amount
     */
    function getSellPriceAfterFee(
        bytes32 subject,
        uint256 amount
    ) external view returns (uint256);

    /**
     * @notice get SubjectOwner of one subject.
     *
     * @param subject Identity of one tomo.
     */
    function getSubjectOwner(bytes32 subject) external view returns (address);

    /**
     * @notice get eth balance of one subject.
     *
     * @param subject Identity of one tomo.
     */
    function getSubjectETHBalance(
        bytes32 subject
    ) external view returns (uint256);

    /**
     * @notice get supply of one subject.
     *
     * @param subject Identity of one tomo.
     */
    function getSubjectSupply(bytes32 subject) external view returns (uint256);

    /**
     * @notice get balance of one subject a account  hold.
     *
     * @param subject Identity of one tomo.
     * @param account Address of account.
     */
    function getSubjectBalanceOf(
        bytes32 subject,
        address account
    ) external view returns (uint256);

    function getPrice(
        uint256 supply,
        uint256 amount
    ) external pure returns (uint256);
}
