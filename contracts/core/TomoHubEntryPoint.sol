// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {VersionedInitializable} from "../upgradeablity/VersionedInitializable.sol";
import {ITomoHubEntryPoint} from "../interfaces/ITomoHubEntryPoint.sol";
import {ITomoFragmentPool} from "../interfaces/ITomoFragmentPool.sol";
import {TomoHubStorage} from "./storage/TomoHubStorage.sol";
import {DataTypes} from "../libraries/DataTypes.sol";
import {EnumerableSet} from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Errors} from "../libraries/Errors.sol";
import {Events} from "../libraries/Events.sol";
import {ITomo} from "../interfaces/ITomo.sol";

contract TomoHubEntryPoint is
    VersionedInitializable,
    TomoHubStorage,
    ITomoHubEntryPoint
{
    using EnumerableSet for EnumerableSet.UintSet;

    uint256 internal constant ONE_WEEK = 7 days;
    uint256 internal constant REVISION = 1;
    address internal immutable TOMO_IMPL;
    address internal immutable TOMO_FRAGMENT_POOL_IMPL;

    modifier onlyGov() {
        _validateCallerIsGovernance();
        _;
    }

    modifier whenNotPaused() {
        _validateNotPaused();
        _;
    }

    /**
     * @dev The constructor sets the immutable Tomo implementations.
     *
     * @param tomoImpl The Tomo Protocol implementation address.
     * @param tomoFragmentPoolImpl The Tomo FragmentPool implementation address.
     */
    constructor(address tomoImpl, address tomoFragmentPoolImpl) {
        if (tomoImpl == address(0) || tomoFragmentPoolImpl == address(0))
            revert Errors.InitParamsInvalid();
        TOMO_IMPL = tomoImpl;
        TOMO_FRAGMENT_POOL_IMPL = tomoFragmentPoolImpl;
    }

    /// @inheritdoc ITomoHubEntryPoint
    function initialize(
        address governanceContractAddress,
        address protocolFeeAddress
    ) external override initializer {
        _setState(DataTypes.TomoHubEntryPointState.Paused);
        _setGovernance(governanceContractAddress);
        _setProtocolFeeAddress(protocolFeeAddress);
    }

    /// ***********************
    /// *****GOV FUNCTIONS*****
    /// ***********************

    function setGovernance(address newGovernance) external override onlyGov {
        _setGovernance(newGovernance);
    }

    function setProtocolFeeAddress(
        address newProtocolFeeAddress
    ) external override onlyGov {
        _setProtocolFeeAddress(newProtocolFeeAddress);
    }

    function setState(
        DataTypes.TomoHubEntryPointState newState
    ) external override onlyGov {
        _setState(newState);
    }

    function setMinPriceKeyCanFragment(
        uint256 minPrice
    ) external override onlyGov {
        _setMinPriceKeyCanFragment(minPrice);
    }

    /// ***************************************
    /// *****About Fragment Pool Liquidity*****
    /// ***************************************

    /// @inheritdoc ITomoHubEntryPoint
    function buyVotePassAndFragment(
        bytes32 subject,
        uint256 amount,
        uint256 fragmentAmount,
        //uint256 deadline,
        uint256 maxAcceptPrice,
        uint8[] calldata v,
        bytes32[] calldata r,
        bytes32[] calldata s
    ) external payable override whenNotPaused {
        // if (block.timestamp + ONE_WEEK < deadline)
        //     revert Errors.DeadLineNeedMoreThanOneWeek();
        //check if the key price enough for fragmention
        uint256 currentPrice = ITomo(TOMO_IMPL).getBuyPrice(subject, 1);
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

    /// @inheritdoc ITomoHubEntryPoint
    function buyFragmentVotePass(
        bytes32 subject,
        uint256 amount,
        uint256 maxAcceptPrice
    ) external payable override whenNotPaused {
        //check if subject fragment pool exist
        address poolAddress = _subjectToFragmentPool[subject]
            .fragmentPoolAddress;
        if (poolAddress == address(0)) revert Errors.FragmentPoolNotExist();
        if (amount == 0) revert Errors.CanNotTradeZeroAmount();
        //buy amount fragment key
        uint256 buyPrice = ITomoFragmentPool(poolAddress).buyFragmentVotePass{
            value: msg.value
        }(amount, maxAcceptPrice, payable(msg.sender));
        //emit event
        _emitTradeFragmentSuccess(subject, msg.sender, amount, buyPrice, true);
    }

    /// @inheritdoc ITomoHubEntryPoint
    function sellFragmentVotePass(
        bytes32 subject,
        uint256 amount,
        uint256 minAcceptPrice
    ) external override whenNotPaused {
        //check if subject fragment pool exist
        address poolAddress = _subjectToFragmentPool[subject]
            .fragmentPoolAddress;
        if (poolAddress == address(0)) revert Errors.FragmentPoolNotExist();
        if (amount == 0) revert Errors.CanNotTradeZeroAmount();
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

    /// @inheritdoc ITomoHubEntryPoint
    //only call from fragment pool contract address
    function sellVotePass(
        bytes32 subject,
        uint256 amount,
        address payable seller
    ) external override whenNotPaused {
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

    /// @inheritdoc ITomoHubEntryPoint
    function addETHLiquidity(
        bytes32 subject
    ) external payable override whenNotPaused {
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

    /// @inheritdoc ITomoHubEntryPoint
    function quitFromLiquidityProvider(
        bytes32 subject
    ) external override whenNotPaused {
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

    /// @inheritdoc ITomoHubEntryPoint
    function buyVotePassWithLockTimeStamp(
        bytes32 subject,
        uint256 amount,
        uint256 maxAcceptPrice,
        uint256 lockUntil,
        uint8[] calldata v,
        bytes32[] calldata r,
        bytes32[] calldata s
    ) external payable override whenNotPaused {
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
        _emitBuyVotePassWithTimeStamp(subject, amount, lockUntil, msg.sender);
    }

    /// @inheritdoc ITomoHubEntryPoint
    function sellLockVotePass(
        uint256 lockIndex,
        uint256 amount,
        uint256 minAcceptPrice,
        address payable receiveFund
    ) external override whenNotPaused {
        if (_indexToVotePassLockInfo[lockIndex].owner != msg.sender)
            revert Errors.NotLockOwner();
        if (block.timestamp < _indexToVotePassLockInfo[lockIndex].lockUntil)
            revert Errors.CanNotSellBeforeDeadline();

        uint256 lockAmount = _indexToVotePassLockInfo[lockIndex].amount;
        if (amount > lockAmount) revert Errors.VotePassNotEnough();

        bytes32 subject = _indexToVotePassLockInfo[lockIndex].subject;
        uint256 sellPriceAfterFee = ITomo(TOMO_IMPL).getSellPriceAfterFee(
            subject,
            amount
        );
        if (sellPriceAfterFee < minAcceptPrice)
            revert Errors.LessThanMinAcceptPrice();
        if (lockAmount == amount) {
            delete _indexToVotePassLockInfo[lockIndex];
            _userVotePassLockIds[msg.sender].remove(lockIndex);
        } else {
            _indexToVotePassLockInfo[lockIndex].amount -= amount;
        }
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

    /// @inheritdoc ITomoHubEntryPoint
    function transferLockVotePass(
        uint256 lockIndex,
        address to
    ) external override whenNotPaused {
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

    /// @inheritdoc ITomoHubEntryPoint
    function getAllLockIndexByAddress(
        address locker
    ) external view override returns (uint256[] memory) {
        return _userVotePassLockIds[locker].values();
    }

    /// @inheritdoc ITomoHubEntryPoint
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
        //uint256 deadline,
        uint256 fragmentAmount
    ) internal {
        if (_subjectToFragmentPool[subject].fragmentPoolAddress == address(0)) {
            // create new subject fragment pool
            address newFragmentPool = Clones.clone(TOMO_FRAGMENT_POOL_IMPL);

            ITomoFragmentPool(newFragmentPool).initialize(
                subject,
                fragmentAmount,
                amount,
                msg.sender,
                _protocolFeeAddress
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
        } else {
            ITomoFragmentPool(
                _subjectToFragmentPool[subject].fragmentPoolAddress
            ).addKeyLiquidity(msg.sender, amount);
        }
        _subjectToFragmentPool[subject].holdAmount += amount;
        _emitAddKeyLiquidity(
            _subjectToFragmentPool[subject].fragmentPoolAddress,
            msg.sender,
            amount,
            block.timestamp
        );
    }

    function _emitBuyVotePassWithTimeStamp(
        bytes32 subject,
        uint256 amount,
        uint256 lockUntil,
        address buyer
    ) private {
        emit Events.BuyVotePassWithTimeStamp(subject, amount, lockUntil, buyer);
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

    function _setProtocolFeeAddress(address newProtocolFeeAddress) internal {
        address preProtocolFeeAddress = _protocolFeeAddress;
        _protocolFeeAddress = newProtocolFeeAddress;
        emit Events.ProcotolFeeAddressSet(
            msg.sender,
            preProtocolFeeAddress,
            newProtocolFeeAddress,
            block.timestamp
        );
    }

    function _validateCallerIsGovernance() internal view {
        if (msg.sender != _governance) revert Errors.NotGovernance();
    }

    function _setState(DataTypes.TomoHubEntryPointState newState) internal {
        DataTypes.TomoHubEntryPointState prevState = _state;
        _state = newState;
        emit Events.StateSet(msg.sender, prevState, newState, block.timestamp);
    }

    function _setMinPriceKeyCanFragment(uint256 newPrice) internal {
        uint256 prevMinPrice = _minPriceKeyCanFragment;
        _minPriceKeyCanFragment = newPrice;
        emit Events.MinPriceKeyCanFragment(
            msg.sender,
            prevMinPrice,
            _minPriceKeyCanFragment,
            block.timestamp
        );
    }

    function getRevision() internal pure virtual override returns (uint256) {
        return REVISION;
    }

    function _validateNotPaused() internal view {
        if (_state == DataTypes.TomoHubEntryPointState.Paused)
            revert Errors.Paused();
    }
}
