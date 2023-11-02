// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import {ITomoFragmentPool} from "../interfaces/ITomoFragmentPool.sol";
import {Errors} from "../libraries/Errors.sol";
import {Events} from "../libraries/Events.sol";
import {ITomo} from "../interfaces/ITomo.sol";
import {FeeSplitter} from "./payment/FeeSplitter.sol";
import {TomoHubEntryPoint} from "./TomoHubEntryPoint.sol";

contract TomoFragmentPool is FeeSplitter, ITomoFragmentPool {
    address public immutable TOMO_HUB_ENTRYPOINT;
    address public immutable TOMO_IMPL;

    uint256 public constant _liquidityProviderFeePercent = 800;
    uint256 public constant _protocolFeePercent = 200;

    address internal _protocolFeeAddress;

    bool private _initialized;
    address public _subjectOwner;
    bytes32 public _subject;

    uint256 public _totalSupply;
    uint256 public _currentLiquidity;
    uint256 public _fragmentParam; //how mant fragment one key can split
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
        TOMO_HUB_ENTRYPOINT = tomoFragmentEntryPoint;
        TOMO_IMPL = tomoImpl;
        _initialized = true;
    }

    /// @inheritdoc ITomoFragmentPool
    function initialize(
        bytes32 subject,
        uint256 fragmentParam,
        address protocolFeeAddress
    ) external override {
        if (_initialized) revert Errors.Initialized();
        _initialized = true;
        address subjectOwner = ITomo(TOMO_IMPL).getSubjectOwner(subject);
        //when kol not jump in, the subject owner is empty, can not revert.
        //if (subjectOwner == address(0)) revert Errors.SubjectNotExist();
        _protocolFeeAddress = protocolFeeAddress;
        _subjectOwner = subjectOwner;
        _subject = subject;
        _fragmentParam = fragmentParam;
    }

    /// @inheritdoc ITomoFragmentPool
    function buyFragmentVotePass(
        uint256 amount,
        uint256 maxAcceptPrice,
        address payable buyer
    ) external payable override returns (uint256) {
        if (msg.sender != TOMO_HUB_ENTRYPOINT)
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
        if (msg.sender != TOMO_HUB_ENTRYPOINT)
            revert Errors.NotTomoFragmentEntryPoint();
        if (_bLiquidityProvider[seller])
            revert Errors.LiquidityProviderCanNotSell();
        if (amount > _fragBalance[seller]) revert Errors.NotEnoughFragment();

        return _sellFragmentKey(amount, minAcceptPrice, seller);
    }

    /// @inheritdoc ITomoFragmentPool
    function addKeyLiquidity(
        address keyLiquidityProvider,
        uint256 keyAmount,
        uint256 deadline
    ) external override {
        if (msg.sender != TOMO_HUB_ENTRYPOINT)
            revert Errors.NotTomoFragmentEntryPoint();
        uint256 total = keyAmount * _fragmentParam;
        //all liquidity provider share all _currentLiquidity and eth in contract, so not record the fragment balance of liquidity provider
        //_fragBalance[liquidityProvider] = total;
        _bLiquidityProvider[keyLiquidityProvider] = true;
        _totalSupply += total;
        _currentLiquidity += total;

        _addLiquidityProvider(
            keyLiquidityProvider,
            keyAmount * _fragmentParam,
            block.timestamp,
            deadline
        );
    }

    /// @inheritdoc ITomoFragmentPool
    function addETHLiquidity(
        address payable ethLiquidityProvider,
        uint256 deadline
    ) external payable override returns (uint256) {
        if (msg.sender != TOMO_HUB_ENTRYPOINT)
            revert Errors.NotTomoFragmentEntryPoint();
        uint256 currentSupply = ITomo(TOMO_IMPL).getSubjectSupply(_subject);
        if (currentSupply == 0) revert Errors.SupplyCanNotBeZero();
        uint256 keyPrice = ITomo(TOMO_IMPL).getPrice(currentSupply - 1, 1);
        //if msg.value less than one split key, revert.
        if (msg.value * _fragmentParam < keyPrice)
            revert Errors.ETHValueTooLow();
        uint256 liquidityKeyAmount = (msg.value * _fragmentParam) / keyPrice;
        if (msg.value > (liquidityKeyAmount * keyPrice) / _fragmentParam) {
            uint256 left = msg.value -
                (liquidityKeyAmount * keyPrice) /
                _fragmentParam;
            (bool success, ) = ethLiquidityProvider.call{value: left}("");
            if (!success) revert Errors.SendETHFailed();
        }
        _addLiquidityProvider(
            ethLiquidityProvider,
            liquidityKeyAmount,
            block.timestamp,
            deadline
        );
        return liquidityKeyAmount;
    }

    /// @inheritdoc ITomoFragmentPool
    //get back fragment votepass and eth reward than sell the votepass if hold amount large than _fragmentParam, ant left sell to other liquidity provider
    function quitFromLiquidityProvider(
        address payable quitor
    ) external override {
        if (msg.sender != TOMO_HUB_ENTRYPOINT)
            revert Errors.NotTomoFragmentEntryPoint();
        if (!_bLiquidityProvider[quitor])
            revert Errors.JustLiquidityProviderCanQuit();

        (
            uint256 liquidityAvailableGet,
            uint256 liquidityFrozenGet,
            uint256 ethAvailableGet,

        ) = _quitFromLiquidity(quitor, _currentLiquidity);

        if (liquidityFrozenGet == 0) delete _bLiquidityProvider[quitor];
        _fragBalance[quitor] = liquidityAvailableGet;
        //liquidity provider quit, need sub account from _currentLiquidity
        //_totalShare -= liquidityAvailableGet;
        _currentLiquidity -= liquidityAvailableGet;
        _sellFragmentKey(liquidityAvailableGet, 0, quitor);
        if (ethAvailableGet > 0) {
            (bool success, ) = quitor.call{value: ethAvailableGet}("");
            if (!success) revert Errors.SendETHFailed();
        }
        _deleteQuitorLiquidityInfo(quitor);
    }

    receive() external payable virtual {
        revert Errors.NotReceiveETHDirectly();
    }

    /// ****************************
    /// *****VIEW FUNCTIONS*****
    /// ****************************

    /// @inheritdoc ITomoFragmentPool
    function getVotePassAndEthIfQuit(
        address quitor
    ) external view override returns (uint256, uint256, uint256, uint256) {
        (
            uint256 liquidityAvailableGet,
            uint256 userFrozenShareAmount,
            uint256 ethAvailableGet,
            uint256 ethFrozenGet
        ) = _quitFromLiquidity(quitor, _currentLiquidity);
        return (
            liquidityAvailableGet,
            userFrozenShareAmount,
            ethAvailableGet,
            ethFrozenGet
        );
    }

    function getSellPriceAfterFee(
        uint256 amount
    ) public view returns (uint256, uint256) {
        uint256 currentSupply = ITomo(TOMO_IMPL).getSubjectSupply(_subject);
        if (currentSupply == 0) revert Errors.SupplyCanNotBeZero();
        uint256 keyPrice = ITomo(TOMO_IMPL).getPrice(currentSupply - 1, 1);
        uint256 price = (keyPrice * amount) / _fragmentParam;
        uint256 fee = (price *
            (_liquidityProviderFeePercent + _protocolFeePercent)) / BPS_MAX;
        return (price, price - fee);
    }

    function getBuyPriceAfterFee(
        uint256 amount
    ) public view returns (uint256, uint256) {
        uint256 currentSupply = ITomo(TOMO_IMPL).getSubjectSupply(_subject);
        if (currentSupply == 0) revert Errors.SupplyCanNotBeZero();
        uint256 keyPrice = ITomo(TOMO_IMPL).getPrice(currentSupply - 1, 1);
        uint256 price = (keyPrice * amount) / _fragmentParam;
        uint256 fee = (price *
            (_liquidityProviderFeePercent + _protocolFeePercent)) / BPS_MAX;
        return (price, price + fee);
    }

    /// ****************************
    /// *****INTERNAL FUNCTIONS*****
    /// ****************************

    function _sellFragmentKey(
        uint256 amount,
        uint256 minAcceptPrice,
        address payable seller
    ) private returns (uint256) {
        bool bSellWholeKey = false;
        uint256 priceSellToTomo = 0;
        if (amount >= _fragmentParam) {
            (priceSellToTomo, amount) = _sellToTomo(amount, seller);
            bSellWholeKey = true;
        }
        if (bSellWholeKey && amount == 0) return priceSellToTomo;

        (uint256 price, uint256 priceAfterFee) = getSellPriceAfterFee(amount);
        if (priceAfterFee < minAcceptPrice && !bSellWholeKey) {
            revert Errors.LessThanMinAcceptPrice();
        }
        if (address(this).balance < priceAfterFee) {
            if (bSellWholeKey) {
                return priceSellToTomo;
            } else {
                revert Errors.ETHLiquidityNotEnough();
            }
        }

        _currentLiquidity += amount;
        _fragBalance[seller] -= amount;
        (bool success, ) = seller.call{value: priceAfterFee}("");
        (bool success1, ) = _protocolFeeAddress.call{
            value: (price * _protocolFeePercent) / BPS_MAX
        }("");
        if (!success1 && !success) revert Errors.SendETHFailed();
        return priceSellToTomo + priceAfterFee;
    }

    function _sellToTomo(
        uint256 amount,
        address payable seller
    ) private returns (uint256, uint256) {
        uint256 wholeKeyAmount = amount / _fragmentParam;
        uint256 sellPriceAfterFee = ITomo(TOMO_IMPL).getSellPriceAfterFee(
            _subject,
            wholeKeyAmount
        );

        uint256 sellAmount = wholeKeyAmount * _fragmentParam;
        _totalSupply -= sellAmount;
        //_currentLiquidity -= sellAmount;
        _fragBalance[seller] -= sellAmount;

        TomoHubEntryPoint(TOMO_HUB_ENTRYPOINT).sellVotePass(
            _subject,
            wholeKeyAmount,
            payable(seller)
        );
        return (sellPriceAfterFee, amount - sellAmount);
    }
}
