// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

library Errors {
    error NotGovernance();
    error CannotInitImplementation();
    error Initialized();
    error InitParamsInvalid();
    error NotTomoFragmentEntryPoint();
    error LiquidityNotEnough();
    error SubjectNotExist();
    error LiquidityProviderCanNotBuy();
    error LiquidityProviderCanNotSell();
    error CanNotBuyExceedFragmentParam();
    error FundsNotEnough();
    error LargeThanMaxAcceptPrice();
    error LessThanMinAcceptPrice();
    error NotReceiveETH();
    error SendETHFailed();
    error NotEnoughFragment();
    error ETHLiquidityNotEnough();
    error NotReceiveETHDirectly();
    error KeyPriceTooLowCanNotBeFragment();
    error FragmentPoolNotExist();
    error CallerNeedBeFragmentPool();
    error CanNotBeZeroAddress();
    error ETHValueTooLow();
    error VotePassNotEnough();
    error NotLockOwner();
    error CanNotSellBeforeDeadline();
    error NotAvaiableAmount();
    error NotContrainThisLockIndex();
    error AlreadyContrainThisLockIndex();
    error JustLiquidityProviderCanQuit();
    error DeadLineNeedMoreThanOneWeek();
    error SupplyCanNotBeZero();
}
