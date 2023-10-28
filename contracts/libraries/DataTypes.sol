// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

/**
 * @title DataTypes
 * @author Tomo Protocol
 *
 * @notice A standard library of data types used throughout the TomoFragment.
 */
library DataTypes {
    struct FragmentConfig {
        bytes32 subject;
        uint256 holdAmount;
        address poolCreator;
        address fragmentPoolAddress;
    }
}
