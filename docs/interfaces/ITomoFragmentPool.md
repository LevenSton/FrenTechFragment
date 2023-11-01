# ITomoFragmentPool

*Tomo Protocol*

> ITomoFragmentPool

This is the interface for the TomoFragmentPool contract, the pool of key Fragment. You&#39;ll find all the events and external functions, as well as the reasoning behind them here.



## Methods

### _fragmentParam

```solidity
function _fragmentParam() external view returns (uint256)
```

get fragment param.




#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### addETHLiquidity

```solidity
function addETHLiquidity(address payable ethLiquidityProvider, uint256 deadline) external payable returns (uint256)
```

Add ETH liquidity.



#### Parameters

| Name | Type | Description |
|---|---|---|
| ethLiquidityProvider | address payable | The eth provider address. |
| deadline | uint256 | The deadline this liquidity can quit |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### addKeyLiquidity

```solidity
function addKeyLiquidity(address liquidityProvider, uint256 keyAmount, uint256 deadline) external nonpayable
```

Add Key/Vote liquidity. all liquidity provider share all _currentLiquidity and eth in contract, so not record the fragment balance of liquidity provider



#### Parameters

| Name | Type | Description |
|---|---|---|
| liquidityProvider | address | The liquidity provider address. |
| keyAmount | uint256 | The key amount |
| deadline | uint256 | The deadline this liquidity can quit |

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
function initialize(bytes32 subject, uint256 fragmentParam, address protocolFeeAddress) external nonpayable
```

Buy And Fragment Key/Vote.



#### Parameters

| Name | Type | Description |
|---|---|---|
| subject | bytes32 | Identity of one tomo. |
| fragmentParam | uint256 | The param which one key can split to |
| protocolFeeAddress | address | The protocol fee Address. |

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




