// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import "@openzeppelin/contracts/utils/Context.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Errors} from "../../libraries/Errors.sol";

/**
 * @title FeeSplitter
 * @dev This contract allows to split Ether payments among a group of accounts. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 *
 * The split can be in equal parts or in any other arbitrary proportion. The way this is specified is by assigning each
 * account to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned.
 *
 * `FeeSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 *
 * NOTE: This contract assumes that ERC20 tokens will behave similarly to native tokens (Ether). Rebasing tokens, and
 * tokens that apply fees during transfers, are likely to not be supported as expected. If in doubt, we encourage you
 * to run tests before sending real value to this contract.
 *
 * To help liquidity provider to distribute fee
 */
contract FeeSplitter is Context {
    using EnumerableSet for EnumerableSet.UintSet;

    uint256 public constant BPS_MAX = 10000;

    uint256 private _totalShare;

    uint256 private _globalLiquidityIndex;

    struct Share {
        uint256 _amount;
        uint256 _timeStamp;
        address _liquidityProvider;
    }
    mapping(uint256 => Share) internal _liquidityIndexToShare;
    mapping(address => EnumerableSet.UintSet) internal _userLiquidityLockIds;
    EnumerableSet.UintSet internal _allLiquidityIndex;

    function _addLiquidityProvider(
        address liquidityProvider,
        uint256 shares,
        uint256 timeStamp,
        uint256 deadline
    ) internal {
        Share storage share = _liquidityIndexToShare[_globalLiquidityIndex];
        share._amount = shares;
        share._liquidityProvider = liquidityProvider;
        share._timeStamp = timeStamp;

        _userLiquidityLockIds[liquidityProvider].add(_globalLiquidityIndex);
        _allLiquidityIndex.add(_globalLiquidityIndex);

        _totalShare += shares;
        _globalLiquidityIndex++;
    }

    //quit from liquidity provider, and get back the fragment vote pass and eth reward.
    function _quitFromLiquidity(
        address liquidityProvider,
        uint256 currentLiquidity
    ) internal view returns (uint256, uint256) {
        //get all liquidity provider effective time
        uint256 totalProviderEffectiveTime = _getTotalProviderEffectiveTime();

        //get user liquidity provider effective time and total share amount
        (
            uint256 userShareAmount,
            uint256 userEffectiveTime
        ) = _getUserShareAndEffectiveTime(liquidityProvider);

        //calculate how many the fragment vote pass can get
        uint256 liquidityGet = (currentLiquidity *
            userShareAmount *
            userEffectiveTime) / (_totalShare * totalProviderEffectiveTime);

        //calculate how many the eth can get
        uint256 ethGet = (address(this).balance *
            userShareAmount *
            userEffectiveTime) / (_totalShare * totalProviderEffectiveTime);

        return (liquidityGet, ethGet);
    }

    function _deleteQuitorLiquidityInfo(address liquidityProvider) internal {
        uint256 userLength = _userLiquidityLockIds[liquidityProvider].length();
        for (uint256 i = 0; i < userLength; i++) {
            uint256 index = _userLiquidityLockIds[liquidityProvider].at(i);
            _allLiquidityIndex.remove(index);
            delete _liquidityIndexToShare[index];
        }
        delete _userLiquidityLockIds[liquidityProvider];
    }

    /// ***************************************
    /// *****Private Function**********
    /// ***************************************

    function _getTotalProviderEffectiveTime() private view returns (uint256) {
        uint256 allLength = _allLiquidityIndex.length();
        uint256 totalProviderEffectiveTime = 0;
        for (uint256 i = 0; i < allLength; i++) {
            totalProviderEffectiveTime +=
                block.timestamp -
                _liquidityIndexToShare[_allLiquidityIndex.at(i)]._timeStamp;
        }
        return totalProviderEffectiveTime;
    }

    function _getUserShareAndEffectiveTime(
        address liquidityProvider
    ) private view returns (uint256, uint256) {
        //get user liquidity provider effective time and total share amount
        uint256 userLength = _userLiquidityLockIds[liquidityProvider].length();
        uint256 userShareAmount = 0;
        uint256 userEffectiveTime = 0;
        for (uint256 i = 0; i < userLength; i++) {
            uint256 index = _userLiquidityLockIds[liquidityProvider].at(i);
            userShareAmount += _liquidityIndexToShare[index]._amount;
            userEffectiveTime +=
                block.timestamp -
                _liquidityIndexToShare[index]._timeStamp;
        }
        return (userShareAmount, userEffectiveTime);
    }
}
