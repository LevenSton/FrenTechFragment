// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {VersionedInitializable} from "../upgradeablity/VersionedInitializable.sol";
import {ITomoFragmentEntryPoint} from "../interfaces/ITomoFragmentEntryPoint.sol";
import {ITomoFragmentPool} from "../interfaces/ITomoFragmentPool.sol";
import {TomoFragmentStorage} from "./storage/TomoFragmentStorage.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Errors} from "../libraries/Errors.sol";
import {Events} from "../libraries/Events.sol";
import {ITomo} from "../interfaces/ITomo.sol";

contract TomoFragmentEntryPoint is
    VersionedInitializable,
    TomoFragmentStorage,
    ITomoFragmentEntryPoint
{
    uint256 internal constant REVISION = 1;
    address internal immutable TOMO_IMPL;
    address internal immutable TOMO_FRAGMENT_POOL_IMPL;

    /**
     * @dev The constructor sets the immutable Tomo implementations.
     *
     * @param tomoImpl The Tomo Protocol implementation address.
     * @param tomoFragmentPoolImpl The Tomo FragmentPool implementation address.
     * @param keyMinPrice The min price of one key can Fragment
     */
    constructor(
        address tomoImpl,
        address tomoFragmentPoolImpl,
        uint256 keyMinPrice
    ) {
        if (tomoImpl == address(0)) revert Errors.InitParamsInvalid();
        TOMO_IMPL = tomoImpl;
        TOMO_FRAGMENT_POOL_IMPL = tomoFragmentPoolImpl;
        _minPriceKeyCanFragment = keyMinPrice;
    }

    /// @inheritdoc ITomoFragmentEntryPoint
    function initialize(
        address newGovernanceContractAddress,
        uint256 minPriceKeyCanFragment
    ) external override initializer {
        _setGovernance(newGovernanceContractAddress);
        _minPriceKeyCanFragment = minPriceKeyCanFragment;
    }

    /// @inheritdoc ITomoFragmentEntryPoint
    function buyVotePassAndFragment(
        bytes32 subject,
        uint256 amount,
        uint256 fragmentAmount,
        uint256 maxAcceptPrice,
        uint8[] calldata v,
        bytes32[] calldata r,
        bytes32[] calldata s
    ) external payable override {
        uint256 currentPrice = ITomo(TOMO_IMPL).getBuyPrice(subject, 0);
        if (currentPrice < _minPriceKeyCanFragment)
            revert Errors.KeyPriceTooLowCanNotBeFragment();

        uint256 priceAfterFee = ITomo(TOMO_IMPL).getBuyPriceAfterFee(
            subject,
            amount
        );
        if (msg.value < priceAfterFee) revert Errors.FundsNotEnough();
        if (priceAfterFee > maxAcceptPrice)
            revert Errors.LargeThanMaxAcceptPrice();
        ITomo(TOMO_IMPL).buyVotePass{value: msg.value}(
            subject,
            amount,
            v,
            r,
            s
        );
        _sendToTomoFragmentPool(subject, amount, fragmentAmount);
    }

    /// @inheritdoc ITomoFragmentEntryPoint
    function buyFragmentVotePass(
        bytes32 subject,
        uint256 amount,
        uint256 maxAcceptPrice
    ) external payable override {
        address poolAddress = _subjectToFragmentPool[subject]
            .fragmentPoolAddress;
        if (poolAddress == address(0)) revert Errors.FragmentPoolNotExist();
        uint256 buyPrice = ITomoFragmentPool(poolAddress).buyFragmentVotePass{
            value: msg.value
        }(amount, maxAcceptPrice, payable(msg.sender));
        _emitBuyFragmentSuccess(subject, msg.sender, amount, buyPrice);
    }

    /// @inheritdoc ITomoFragmentEntryPoint
    function sellFragmentVotePass(
        bytes32 subject,
        uint256 amount,
        uint256 minAcceptPrice
    ) external override {
        address poolAddress = _subjectToFragmentPool[subject]
            .fragmentPoolAddress;
        if (poolAddress == address(0)) revert Errors.FragmentPoolNotExist();
        uint256 sellPrice = ITomoFragmentPool(poolAddress).sellFragmentVotePass(
            amount,
            minAcceptPrice,
            payable(msg.sender)
        );
        _emitSellFragmentSuccess(subject, msg.sender, amount, sellPrice);
    }

    /// @inheritdoc ITomoFragmentEntryPoint
    function sellVotePass(
        bytes32 subject,
        address seller,
        uint256 amount
    ) external override {
        if (_fragmentPoolToSubject[msg.sender] != subject)
            revert Errors.CallerNeedBeFragmentPool();

        uint256 sellPriceAfterFee = ITomo(TOMO_IMPL).getSellPriceAfterFee(
            subject,
            amount
        );
        ITomo(TOMO_IMPL).sellVotePass(subject, amount);
        (bool success, ) = seller.call{value: sellPriceAfterFee}("");
        if (!success) revert Errors.SendETHFailed();
    }

    /// ****************************
    /// *****INTERNAL FUNCTIONS*****
    /// ****************************

    function _sendToTomoFragmentPool(
        bytes32 subject,
        uint256 amount,
        uint256 fragmentAmount
    ) internal {
        if (_subjectToFragmentPool[subject].poolCreator != address(0)) {
            uint256 fragmentParam = ITomoFragmentPool(
                _subjectToFragmentPool[subject].fragmentPoolAddress
            ).getFragmentParam();
            ITomoFragmentPool(
                _subjectToFragmentPool[subject].fragmentPoolAddress
            ).addKeyLiquidity(msg.sender, fragmentParam * amount);
        } else {
            // create new subject fragment pool
            address newFragmentPool = Clones.clone(TOMO_FRAGMENT_POOL_IMPL);

            ITomoFragmentPool(newFragmentPool).initialize(
                subject,
                msg.sender,
                fragmentAmount,
                amount
            );
            _subjectToFragmentPool[subject].subject = subject;
            address subjectOwner = ITomo(TOMO_IMPL).getSubjectOwner(subject);
            _subjectToFragmentPool[subject].subjectOwner = subjectOwner;
            _subjectToFragmentPool[subject].poolCreator = msg.sender;
            _subjectToFragmentPool[subject]
                .fragmentPoolAddress = newFragmentPool;
            _fragmentPoolToSubject[newFragmentPool] = subject;
            _emitCreateNewFragmentPool(
                subject,
                subjectOwner,
                msg.sender,
                newFragmentPool,
                fragmentAmount
            );
        }
        _subjectToFragmentPool[subject].holdAmount += amount;
        _emitAddKeyLiquidity(
            _subjectToFragmentPool[subject].fragmentPoolAddress,
            amount
        );
    }

    function _emitCreateNewFragmentPool(
        bytes32 subject,
        address keyOwner,
        address creator,
        address poolAddress,
        uint256 fragmentAmount
    ) private {
        emit Events.NewFragmentPoolCreate(
            subject,
            keyOwner,
            creator,
            poolAddress,
            fragmentAmount
        );
    }

    function _emitBuyFragmentSuccess(
        bytes32 subject,
        address buyer,
        uint256 amount,
        uint256 price
    ) private {
        emit Events.BuyFragmentSuccess(subject, buyer, amount, price);
    }

    function _emitSellFragmentSuccess(
        bytes32 subject,
        address seller,
        uint256 amount,
        uint256 price
    ) private {
        emit Events.SellFragmentSuccess(subject, seller, amount, price);
    }

    function _emitAddKeyLiquidity(
        address poolAddress,
        uint256 liquidity
    ) private {
        emit Events.AddFragmentKeyLiquidity(poolAddress, liquidity);
    }

    function _setGovernance(address newGovernance) internal {
        address prevGovernance = _governance;
        _governance = newGovernance;
        emit Events.GovernanceSet(
            msg.sender,
            prevGovernance,
            newGovernance,
            block.timestamp
        );
    }

    function getRevision() internal pure virtual override returns (uint256) {
        return REVISION;
    }
}
