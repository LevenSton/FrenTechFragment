// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {ITomoFragmentPool} from "../interfaces/ITomoFragmentPool.sol";
import {Errors} from "../libraries/Errors.sol";
import {Events} from "../libraries/Events.sol";
import {ITomo} from "../interfaces/ITomo.sol";
import {FeeSplitter} from "./payment/FeeSplitter.sol";
import {TomoFragmentEntryPoint} from "./TomoFragmentEntryPoint.sol";

contract TomoFragmentPool is FeeSplitter, ITomoFragmentPool {
    address public immutable TOMO_FRAGMENT_ENTRYPOINT;
    address public immutable TOMO_IMPL;

    uint256 public constant _keyLiquidityFeePercent = 300;
    uint256 public constant _ethLiquidityFeePercent = 500;
    uint256 public constant _protocolFeePercent = 200;

    address internal _protocolFeeAddress;

    bool private _initialized;
    address _subjectOwner;
    bytes32 _subject;

    uint256 _totalSupply;
    uint256 _currentLiquidity;
    uint256 _fragmentParam; //how mant fragment one key can split
    mapping(address => uint256) public _fragBalance;
    mapping(address => bool) public _bLiquidityProvider;

    /**
     * @dev The constructor sets the immutable TomoFragmentHub and Tomo implementations.
     *
     * @param tomoFragmentEntryPoint The Tomo FragmentHub address.
     * @param tomoImpl The Tomo Protocol implementation address
     */
    constructor(address tomoFragmentEntryPoint, address tomoImpl) {
        if (tomoImpl == address(0) || tomoFragmentEntryPoint == address(0))
            revert Errors.InitParamsInvalid();
        TOMO_FRAGMENT_ENTRYPOINT = tomoFragmentEntryPoint;
        TOMO_IMPL = tomoImpl;
        _initialized = true;
    }

    /// @inheritdoc ITomoFragmentPool
    function initialize(
        bytes32 subject,
        address keyLiquidityProvider,
        uint256 fragmentParam,
        uint256 keyAmount
    ) external override {
        if (_initialized) revert Errors.Initialized();
        _initialized = true;
        address subjectOwner = ITomo(TOMO_IMPL).getSubjectOwner(subject);
        if (subjectOwner == address(0)) revert Errors.SubjectNotExist();
        _subjectOwner = subjectOwner;
        _subject = subject;
        uint256 total = keyAmount * fragmentParam;
        //_fragBalance[liquidityProvider] = total;
        _bLiquidityProvider[keyLiquidityProvider] = true;
        _totalSupply = total;
        _currentLiquidity = total;
        _fragmentParam = fragmentParam;

        uint256 keyPrice = ITomo(TOMO_IMPL).getBuyPrice(_subject, 0);
        _addPayee(keyLiquidityProvider, keyPrice * keyAmount, block.timestamp);
    }

    /// @inheritdoc ITomoFragmentPool
    function buyFragmentVotePass(
        uint256 amount,
        uint256 maxAcceptPrice,
        address payable buyer
    ) external payable override returns (uint256) {
        if (msg.sender != TOMO_FRAGMENT_ENTRYPOINT)
            revert Errors.NotTomoFragmentEntryPoint();
        if (_currentLiquidity < amount) revert Errors.LiquidityNotEnough();
        if (_bLiquidityProvider[buyer])
            revert Errors.LiquidityProviderCanNotBuy();
        if (amount > _fragmentParam)
            revert Errors.CanNotBuyExceedFragmentParam();
        (uint256 price, uint256 priceAfterFee) = getBuyPriceAfterFee(amount);

        if (msg.value < priceAfterFee) revert Errors.FundsNotEnough();
        if (priceAfterFee > maxAcceptPrice)
            revert Errors.LargeThanMaxAcceptPrice();

        _fragBalance[buyer] += amount;
        _currentLiquidity -= amount;
        //refund eth if any left
        if (msg.value > priceAfterFee) {
            (bool success, ) = buyer.call{value: msg.value - priceAfterFee}("");
            if (!success) revert Errors.SendETHFailed();
        }
        (bool success1, ) = _protocolFeeAddress.call{
            value: (price * _protocolFeePercent) / BPS_MAX
        }("");
        if (!success1) revert Errors.SendETHFailed();
        return priceAfterFee;
    }

    /// @inheritdoc ITomoFragmentPool
    function sellFragmentVotePass(
        uint256 amount,
        uint256 minAcceptPrice,
        address payable seller
    ) external override returns (uint256) {
        if (msg.sender != TOMO_FRAGMENT_ENTRYPOINT)
            revert Errors.NotTomoFragmentEntryPoint();
        if (_bLiquidityProvider[seller])
            revert Errors.LiquidityProviderCanNotSell();
        if (amount > _fragBalance[seller]) revert Errors.NotEnoughFragment();
        bool bSellWholeKey = false;
        uint256 priceSellToTomo = 0;
        if (amount > _fragmentParam) {
            (priceSellToTomo, amount) = sellToTomo(amount, seller);
            bSellWholeKey = true;
        }
        (uint256 price, uint256 priceAfterFee) = getSellPriceAfterFee(amount);
        if (priceAfterFee < minAcceptPrice && !bSellWholeKey) {
            revert Errors.LessThanMinAcceptPrice();
        }
        if (bSellWholeKey) {
            if (address(this).balance < priceAfterFee) {
                return priceSellToTomo;
            }
        }
        return
            sellFragmentKey(
                amount,
                priceSellToTomo,
                price,
                priceAfterFee,
                seller
            );
    }

    /// @inheritdoc ITomoFragmentPool
    function addKeyLiquidity(
        address keyLiquidityProvider,
        uint256 keyAmount
    ) external override {
        if (msg.sender != TOMO_FRAGMENT_ENTRYPOINT)
            revert Errors.NotTomoFragmentEntryPoint();
        uint256 total = keyAmount * _fragmentParam;
        //_fragBalance[liquidityProvider] = total;
        _bLiquidityProvider[keyLiquidityProvider] = true;
        _totalSupply += total;
        _currentLiquidity += total;

        uint256 keyPrice = ITomo(TOMO_IMPL).getBuyPrice(_subject, 0);
        _addPayee(keyLiquidityProvider, keyPrice * keyAmount, block.timestamp);
    }

    /// @inheritdoc ITomoFragmentPool
    function addETHLiquidity(
        address ethLiquidityProvider
    ) external payable override {
        if (msg.sender != TOMO_FRAGMENT_ENTRYPOINT)
            revert Errors.NotTomoFragmentEntryPoint();
        _addPayee(ethLiquidityProvider, msg.value, block.timestamp);
    }

    /// @inheritdoc ITomoFragmentPool
    function getFragmentParam() external view override returns (uint256) {
        return _fragmentParam;
    }

    receive() external payable virtual {
        revert Errors.NotReceiveETHDirectly();
    }

    /// ****************************
    /// *****INTERNAL FUNCTIONS*****
    /// ****************************

    function sellFragmentKey(
        uint256 amount,
        uint256 priceSellToTomo,
        uint256 price,
        uint256 priceAfterFee,
        address payable seller
    ) private returns (uint256) {
        _currentLiquidity += amount;
        _fragBalance[seller] -= amount;
        (bool success, ) = seller.call{value: priceAfterFee}("");
        (bool success1, ) = _protocolFeeAddress.call{
            value: (price * _protocolFeePercent) / BPS_MAX
        }("");
        if (!success1 && !success) revert Errors.SendETHFailed();
        return priceSellToTomo + priceAfterFee;
    }

    function sellToTomo(
        uint256 amount,
        address payable seller
    ) private returns (uint256, uint256) {
        uint256 wholeKeyAmount = amount / _fragmentParam;
        uint256 sellPrice = ITomo(TOMO_IMPL).getSellPrice(
            _subject,
            wholeKeyAmount
        );
        TomoFragmentEntryPoint(TOMO_FRAGMENT_ENTRYPOINT).sellVotePass(
            _subject,
            seller,
            wholeKeyAmount
        );
        uint256 sellAmount = wholeKeyAmount * _fragmentParam;
        _totalSupply -= sellAmount;
        _currentLiquidity -= sellAmount;
        _fragBalance[seller] -= sellAmount;
        return (sellPrice, amount - sellAmount);
    }

    function getSellPriceAfterFee(
        uint256 amount
    ) private view returns (uint256, uint256) {
        uint256 keyPrice = ITomo(TOMO_IMPL).getBuyPrice(_subject, 0);
        uint256 price = (keyPrice * amount) / _fragmentParam;
        uint256 fee = (price *
            (_keyLiquidityFeePercent +
                _ethLiquidityFeePercent +
                _protocolFeePercent)) / BPS_MAX;
        return (price, price - fee);
    }

    function getBuyPriceAfterFee(
        uint256 amount
    ) private view returns (uint256, uint256) {
        uint256 keyPrice = ITomo(TOMO_IMPL).getBuyPrice(_subject, 0);
        uint256 price = (keyPrice * amount) / _fragmentParam;
        uint256 fee = (price *
            (_keyLiquidityFeePercent +
                _ethLiquidityFeePercent +
                _protocolFeePercent)) / BPS_MAX;
        return (price, price + fee);
    }
}
