// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

/**
 * @title DataTypes
 * @author Tomo Protocol
 *
 * @notice A standard library of data types used throughout the TomoFragment.
 */
library DataTypes {
    enum TomoHubEntryPointState {
        Open,
        Paused
    }

    struct FragmentConfig {
        bytes32 subject;
        uint256 holdAmount;
        address poolCreator;
        address fragmentPoolAddress;
    }

    struct VotePassLockInfo {
        bytes32 subject;
        uint256 amount;
        uint256 lockUntil;
        address owner;
    }

    struct Share {
        uint256 _amount;
        uint256 _timeStamp;
        uint256 _deadline;
        address _liquidityProvider;
    }
}
