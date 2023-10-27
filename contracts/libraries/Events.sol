// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {DataTypes} from "./DataTypes.sol";

library Events {
    /**
     * @dev Emitted when the governance address is changed. We emit the caller even though it should be the previous
     * governance address, as we cannot guarantee this will always be the case due to upgradeability.
     *
     * @param caller The caller who set the governance address.
     * @param prevGovernance The previous governance address.
     * @param newGovernance The new governance address set.
     * @param timestamp The current block timestamp.
     */
    event GovernanceSet(
        address indexed caller,
        address indexed prevGovernance,
        address indexed newGovernance,
        uint256 timestamp
    );

    event NewFragmentPoolCreate(
        bytes32 subject,
        address keyOwner,
        address creator,
        address poolAddress,
        uint256 fragmentAmount
    );

    event AddFragmentKeyLiquidity(
        address fragmentPoolAddress,
        uint256 fragmentKeyLiquidity
    );

    event BuyFragmentSuccess(
        bytes32 subject,
        address buyer,
        uint256 amount,
        uint256 price
    );

    event SellFragmentSuccess(
        bytes32 subject,
        address seller,
        uint256 amount,
        uint256 price
    );
}
