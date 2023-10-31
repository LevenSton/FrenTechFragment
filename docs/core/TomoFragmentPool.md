# TomoFragmentPool









## Methods

### BPS_MAX

```solidity
function BPS_MAX() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### TOMO_Hub_ENTRYPOINT

```solidity
function TOMO_Hub_ENTRYPOINT() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### TOMO_IMPL

```solidity
function TOMO_IMPL() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### _bLiquidityProvider

```solidity
function _bLiquidityProvider(address) external view returns (bool)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bool | undefined |

### _currentLiquidity

```solidity
function _currentLiquidity() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### _fragBalance

```solidity
function _fragBalance(address) external view returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### _fragmentParam

```solidity
function _fragmentParam() external view returns (uint256)
```

get fragment param.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### _liquidityProviderFeePercent

```solidity
function _liquidityProviderFeePercent() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### _protocolFeePercent

```solidity
function _protocolFeePercent() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### _subject

```solidity
function _subject() external view returns (bytes32)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | bytes32 | undefined |

### _subjectOwner

```solidity
function _subjectOwner() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### _totalSupply

```solidity
function _totalSupply() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### addETHLiquidity

```solidity
function addETHLiquidity(address payable ethLiquidityProvider) external payable returns (uint256)
```

Add ETH liquidity.



#### Parameters

| Name | Type | Description |
|---|---|---|
| ethLiquidityProvider | address payable | The eth provider address. |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### addKeyLiquidity

```solidity
function addKeyLiquidity(address keyLiquidityProvider, uint256 keyAmount) external nonpayable
```

Add Key/Vote liquidity.



#### Parameters

| Name | Type | Description |
|---|---|---|
| keyLiquidityProvider | address | undefined |
| keyAmount | uint256 | The key amount |

### buyFragmentVotePass

```solidity
function buyFragmentVotePass(uint256 amount, uint256 maxAcceptPrice, address payable buyer) external payable returns (uint256)
```

Sell the Fragment Key/Vote.



#### Parameters

| Name | Type | Description |
|---|---|---|
| amount | uint256 | The sell amount. |
| maxAcceptPrice | uint256 | The min price seller can accept. |
| buyer | address payable | The address of buyer |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### getBuyPriceAfterFee

```solidity
function getBuyPriceAfterFee(uint256 amount) external view returns (uint256, uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| amount | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |
| _1 | uint256 | undefined |

### getSellPriceAfterFee

```solidity
function getSellPriceAfterFee(uint256 amount) external view returns (uint256, uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| amount | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |
| _1 | uint256 | undefined |

### getVotePassAndEthIfQuit

```solidity
function getVotePassAndEthIfQuit(address quitor) external view returns (uint256, uint256)
```

query how mant fragment votepass and eth can get if quit the liquidity



#### Parameters

| Name | Type | Description |
|---|---|---|
| quitor | address | Address who want to quit liquidity provider. |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |
| _1 | uint256 | undefined |

### initialize

```solidity
function initialize(bytes32 subject, address keyLiquidityProvider, uint256 fragmentParam, uint256 keyAmount) external nonpayable
```

Buy And Fragment Key/Vote.



#### Parameters

| Name | Type | Description |
|---|---|---|
| subject | bytes32 | Identity of one tomo. |
| keyLiquidityProvider | address | undefined |
| fragmentParam | uint256 | The param which one key can split to |
| keyAmount | uint256 | The amount key need to fragment |

### quitFromLiquidityProvider

```solidity
function quitFromLiquidityProvider(address payable quitor) external nonpayable
```

quit from liquidity provider, get back all votepass and eth reward. if hold amount large than _fragmentParam, sell whole votepass to tomo contract, if any left fragment votepass, sell to other liquidity provider



#### Parameters

| Name | Type | Description |
|---|---|---|
| quitor | address payable | Address who want to quit liquidity provider. |

### sellFragmentVotePass

```solidity
function sellFragmentVotePass(uint256 amount, uint256 minAcceptPrice, address payable seller) external nonpayable returns (uint256)
```

Sell the Fragment Key/Vote.



#### Parameters

| Name | Type | Description |
|---|---|---|
| amount | uint256 | The sell amount. |
| minAcceptPrice | uint256 | The min price seller can accept. |
| seller | address payable | The seller address. |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |




## Errors

### CanNotBuyExceedFragmentParam

```solidity
error CanNotBuyExceedFragmentParam()
```






### ETHValueTooLow

```solidity
error ETHValueTooLow()
```






### FundsNotEnough

```solidity
error FundsNotEnough()
```






### InitParamsInvalid

```solidity
error InitParamsInvalid()
```






### Initialized

```solidity
error Initialized()
```






### JustLiquidityProviderCanQuit

```solidity
error JustLiquidityProviderCanQuit()
```






### LargeThanMaxAcceptPrice

```solidity
error LargeThanMaxAcceptPrice()
```






### LessThanMinAcceptPrice

```solidity
error LessThanMinAcceptPrice()
```






### LiquidityNotEnough

```solidity
error LiquidityNotEnough()
```






### LiquidityProviderCanNotBuy

```solidity
error LiquidityProviderCanNotBuy()
```






### LiquidityProviderCanNotSell

```solidity
error LiquidityProviderCanNotSell()
```






### NotEnoughFragment

```solidity
error NotEnoughFragment()
```






### NotReceiveETHDirectly

```solidity
error NotReceiveETHDirectly()
```






### NotTomoFragmentEntryPoint

```solidity
error NotTomoFragmentEntryPoint()
```






### SendETHFailed

```solidity
error SendETHFailed()
```






### SupplyCanNotBeZero

```solidity
error SupplyCanNotBeZero()
```







