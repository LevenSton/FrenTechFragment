// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {VersionedInitializable} from "../upgradeablity/VersionedInitializable.sol";
import {ITomoFragmentEntryPoint} from "../interfaces/ITomoFragmentEntryPoint.sol";
import {ITomoFragmentPool} from "../interfaces/ITomoFragmentPool.sol";
import {TomoFragmentStorage} from "./storage/TomoFragmentStorage.sol";
import {DataTypes} from "../libraries/DataTypes.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Errors} from "../libraries/Errors.sol";
import {Events} from "../libraries/Events.sol";
import {ITomo} from "../interfaces/ITomo.sol";

contract TomoFragmentEntryPoint is
    VersionedInitializable,
    TomoFragmentStorage,
    ITomoFragmentEntryPoint
{
    using EnumerableSet for EnumerableSet.UintSet;

    uint256 internal constant REVISION = 1;
    address internal immutable TOMO_IMPL;
    address internal immutable TOMO_FRAGMENT_POOL_IMPL;

    /**
     * @dev The constructor sets the immutable Tomo implementations.
     *
     * @param tomoImpl The Tomo Protocol implementation address.
     * @param tomoFragmentPoolImpl The Tomo FragmentPool implementation address.
     */
    constructor(address tomoImpl, address tomoFragmentPoolImpl) {
        if (tomoImpl == address(0)) revert Errors.InitParamsInvalid();
        TOMO_IMPL = tomoImpl;
        TOMO_FRAGMENT_POOL_IMPL = tomoFragmentPoolImpl;
    }

    /// @inheritdoc ITomoFragmentEntryPoint
    function initialize(
        address newGovernanceContractAddress,
        uint256 minPriceKeyCanFragment
    ) external override initializer {
        _setGovernance(newGovernanceContractAddress);
        _minPriceKeyCanFragment = minPriceKeyCanFragment;
    }

    /// ***************************************
    /// *****About Fragment Pool Liquidity*****
    /// ***************************************

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
        //check if the key price enough for fragmention
        uint256 currentPrice = ITomo(TOMO_IMPL).getBuyPrice(subject, 0);
        if (currentPrice < _minPriceKeyCanFragment)
            revert Errors.KeyPriceTooLowCanNotBeFragment();

        //check if msg.value enough to buy amount key
        uint256 priceAfterFee = ITomo(TOMO_IMPL).getBuyPriceAfterFee(
            subject,
            amount
        );
        if (msg.value < priceAfterFee) revert Errors.FundsNotEnough();
        //check if price lower than maxAcceptPrice
        if (priceAfterFee > maxAcceptPrice)
            revert Errors.LargeThanMaxAcceptPrice();
        //buy amount key
        ITomo(TOMO_IMPL).buyVotePass{value: msg.value}(
            subject,
            amount,
            v,
            r,
            s
        );
        //record to fragment pool
        _sendToTomoFragmentPool(subject, amount, fragmentAmount);
    }

    /// @inheritdoc ITomoFragmentEntryPoint
    function buyFragmentVotePass(
        bytes32 subject,
        uint256 amount,
        uint256 maxAcceptPrice
    ) external payable override {
        //check if subject fragment pool exist
        address poolAddress = _subjectToFragmentPool[subject]
            .fragmentPoolAddress;
        if (poolAddress == address(0)) revert Errors.FragmentPoolNotExist();
        //buy amount fragment key
        uint256 buyPrice = ITomoFragmentPool(poolAddress).buyFragmentVotePass{
            value: msg.value
        }(amount, maxAcceptPrice, payable(msg.sender));
        //emit event
        _emitTradeFragmentSuccess(subject, msg.sender, amount, buyPrice, true);
    }

    /// @inheritdoc ITomoFragmentEntryPoint
    function sellFragmentVotePass(
        bytes32 subject,
        uint256 amount,
        uint256 minAcceptPrice
    ) external override {
        //check if subject fragment pool exist
        address poolAddress = _subjectToFragmentPool[subject]
            .fragmentPoolAddress;
        if (poolAddress == address(0)) revert Errors.FragmentPoolNotExist();
        //sell amount fragment key
        uint256 sellPrice = ITomoFragmentPool(poolAddress).sellFragmentVotePass(
            amount,
            minAcceptPrice,
            payable(msg.sender)
        );
        //emit event
        _emitTradeFragmentSuccess(
            subject,
            msg.sender,
            amount,
            sellPrice,
            false
        );
    }

    /// @inheritdoc ITomoFragmentEntryPoint
    //only call from fragment pool contract address
    function sellVotePass(
        bytes32 subject,
        address seller,
        uint256 amount
    ) external override {
        if (_fragmentPoolToSubject[msg.sender] != subject)
            revert Errors.CallerNeedBeFragmentPool();
        if (_subjectToFragmentPool[subject].holdAmount < amount)
            revert Errors.VotePassNotEnough();

        uint256 sellPriceAfterFee = ITomo(TOMO_IMPL).getSellPriceAfterFee(
            subject,
            amount
        );
        _subjectToFragmentPool[subject].holdAmount -= amount;
        ITomo(TOMO_IMPL).sellVotePass(subject, amount);
        (bool success, ) = seller.call{value: sellPriceAfterFee}("");
        if (!success) revert Errors.SendETHFailed();
    }

    /// @inheritdoc ITomoFragmentEntryPoint
    function addETHLiquidity(bytes32 subject) external payable override {
        address poolAddress = _subjectToFragmentPool[subject]
            .fragmentPoolAddress;
        if (poolAddress == address(0)) revert Errors.FragmentPoolNotExist();
        uint256 liquidityKeyAmount = ITomoFragmentPool(poolAddress)
            .addETHLiquidity{value: msg.value}(payable(msg.sender));

        _emitAddKeyLiquidity(
            poolAddress,
            msg.sender,
            liquidityKeyAmount,
            block.timestamp
        );
    }

    /// @inheritdoc ITomoFragmentEntryPoint
    function quitFromLiquidityProvider(bytes32 subject) external override {
        address poolAddress = _subjectToFragmentPool[subject]
            .fragmentPoolAddress;
        if (poolAddress == address(0)) revert Errors.FragmentPoolNotExist();
        ITomoFragmentPool(poolAddress).quitFromLiquidityProvider(
            payable(msg.sender)
        );
    }

    /// ***************************************
    /// *****About lock/burn/transfer**********
    /// ***************************************

    /// @inheritdoc ITomoFragmentEntryPoint
    function buyVotePassWithLockTimeStamp(
        bytes32 subject,
        uint256 amount,
        uint256 maxAcceptPrice,
        uint256 lockUntil,
        uint8[] calldata v,
        bytes32[] calldata r,
        bytes32[] calldata s
    ) external payable override {
        uint256 priceAfterFee = ITomo(TOMO_IMPL).getBuyPriceAfterFee(
            subject,
            amount
        );
        if (msg.value < priceAfterFee) revert Errors.FundsNotEnough();
        //check if price lower than maxAcceptPrice
        if (priceAfterFee > maxAcceptPrice)
            revert Errors.LargeThanMaxAcceptPrice();
        //buy amount key
        ITomo(TOMO_IMPL).buyVotePass{value: msg.value}(
            subject,
            amount,
            v,
            r,
            s
        );
        _recordLockVotePassInfo(subject, amount, lockUntil);
    }

    /// @inheritdoc ITomoFragmentEntryPoint
    function sellLockVotePass(
        uint256 lockIndex,
        uint256 amount,
        uint256 minAcceptPrice,
        address payable receiveFund
    ) external override {
        if (_indexToVotePassLockInfo[lockIndex].owner != msg.sender)
            revert Errors.NotLockOwner();
        if (_indexToVotePassLockInfo[lockIndex].lockUntil < block.timestamp)
            revert Errors.CanNotSellBeforeDeadline();

        uint256 lockAmount = _indexToVotePassLockInfo[lockIndex].amount;
        if (amount > _indexToVotePassLockInfo[lockIndex].amount)
            revert Errors.VotePassNotEnough();

        bytes32 subject = _indexToVotePassLockInfo[lockIndex].subject;
        uint256 sellPriceAfterFee = ITomo(TOMO_IMPL).getSellPriceAfterFee(
            subject,
            lockAmount
        );
        if (sellPriceAfterFee < minAcceptPrice)
            revert Errors.LessThanMinAcceptPrice();
        if (lockAmount == amount) {
            delete _indexToVotePassLockInfo[lockIndex];
            _userVotePassLockIds[msg.sender].remove(lockIndex);
        }
        _indexToVotePassLockInfo[lockIndex].amount -= amount;
        ITomo(TOMO_IMPL).sellVotePass(subject, amount);
        (bool success, ) = receiveFund.call{value: sellPriceAfterFee}("");
        if (!success) revert Errors.SendETHFailed();
        _emitSellLockVotePass(
            subject,
            lockIndex,
            amount,
            sellPriceAfterFee,
            msg.sender
        );
    }

    /// @inheritdoc ITomoFragmentEntryPoint
    function transferLockVotePass(
        uint256 lockIndex,
        address to
    ) external override {
        if (_indexToVotePassLockInfo[lockIndex].owner != msg.sender)
            revert Errors.NotLockOwner();
        if (_indexToVotePassLockInfo[lockIndex].amount == 0)
            revert Errors.NotAvaiableAmount();
        if (!_userVotePassLockIds[msg.sender].contains(lockIndex))
            revert Errors.NotContrainThisLockIndex();
        if (_userVotePassLockIds[to].contains(lockIndex))
            revert Errors.AlreadyContrainThisLockIndex();

        _userVotePassLockIds[msg.sender].remove(lockIndex);
        _userVotePassLockIds[to].add(lockIndex);
        _emitTransferLockVotePass(lockIndex, msg.sender, to);
    }

    /// ****************************
    /// *****QUERY VIEW FUNCTIONS***
    /// ****************************

    /// @inheritdoc ITomoFragmentEntryPoint
    function getAllLockIndexByAddress(
        address locker
    ) external view override returns (uint256[] memory) {
        return _userVotePassLockIds[locker].values();
    }

    /// @inheritdoc ITomoFragmentEntryPoint
    function getLockInfoByIndex(
        uint256 index
    ) external view override returns (DataTypes.VotePassLockInfo memory) {
        return _indexToVotePassLockInfo[index];
    }

    /// ****************************
    /// *****INTERNAL FUNCTIONS*****
    /// ****************************

    function _recordLockVotePassInfo(
        bytes32 subject,
        uint256 amount,
        uint256 lockUntil
    ) private {
        DataTypes.VotePassLockInfo
            storage vpLockInfo = _indexToVotePassLockInfo[_globalLockIndex];
        vpLockInfo.subject = subject;
        vpLockInfo.amount = amount;
        vpLockInfo.lockUntil = lockUntil;
        vpLockInfo.owner = msg.sender;
        _userVotePassLockIds[msg.sender].add(_globalLockIndex);
        _globalLockIndex++;
    }

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
            _subjectToFragmentPool[subject].poolCreator = msg.sender;
            _subjectToFragmentPool[subject]
                .fragmentPoolAddress = newFragmentPool;
            _fragmentPoolToSubject[newFragmentPool] = subject;
            _emitCreateNewFragmentPool(
                subject,
                msg.sender,
                newFragmentPool,
                fragmentAmount
            );
        }
        _subjectToFragmentPool[subject].holdAmount += amount;
        _emitAddKeyLiquidity(
            _subjectToFragmentPool[subject].fragmentPoolAddress,
            msg.sender,
            amount,
            block.timestamp
        );
    }

    function _emitCreateNewFragmentPool(
        bytes32 subject,
        address creator,
        address poolAddress,
        uint256 fragmentAmount
    ) private {
        emit Events.NewFragmentPoolCreate(
            subject,
            creator,
            poolAddress,
            fragmentAmount
        );
    }

    function _emitTradeFragmentSuccess(
        bytes32 subject,
        address seller,
        uint256 amount,
        uint256 price,
        bool bBuy
    ) private {
        emit Events.TradeFragmentSuccess(subject, seller, amount, price, bBuy);
    }

    function _emitAddKeyLiquidity(
        address poolAddress,
        address liquidityProvider,
        uint256 liquidity,
        uint256 timeStamp
    ) private {
        emit Events.AddFragmentKeyLiquidity(
            poolAddress,
            liquidityProvider,
            liquidity,
            timeStamp
        );
    }

    function _emitSellLockVotePass(
        bytes32 subject,
        uint256 lockIndex,
        uint256 amount,
        uint256 sellPrice,
        address seller
    ) private {
        emit Events.SellLockVotePass(
            subject,
            lockIndex,
            amount,
            sellPrice,
            seller
        );
    }

    function _emitTransferLockVotePass(
        uint256 lockIndex,
        address from,
        address to
    ) private {
        emit Events.TransferLockVotePass(lockIndex, from, to);
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
