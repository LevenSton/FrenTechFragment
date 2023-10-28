// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {DataTypes} from "../../libraries/DataTypes.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/**
 * @title TomoHubStorage
 * @author Tomo Protocol
 *
 * @notice This is an abstract contract that *only* contains storage for the TomoFragment contract. This
 * *must* be inherited last (bar interfaces) in order to preserve the TomoFragment storage layout. Adding
 * storage variables should be done solely at the bottom of this contract.
 */
abstract contract TomoHubStorage {
    //map for subject to pool
    mapping(bytes32 => DataTypes.FragmentConfig)
        internal _subjectToFragmentPool;
    //map for pool to subject
    mapping(address => bytes32) internal _fragmentPoolToSubject;

    mapping(uint256 => DataTypes.VotePassLockInfo)
        internal _indexToVotePassLockInfo;
    mapping(address => EnumerableSet.UintSet) internal _userVotePassLockIds;

    uint256 internal _globalLockIndex;

    uint256 internal _minPriceKeyCanFragment;
    address internal _governance;
}
