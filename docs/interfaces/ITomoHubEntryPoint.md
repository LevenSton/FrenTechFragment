# ITomoHubEntryPoint

*Tomo Protocol*

> ITomoHubEntryPoint

This is the interface for the TomoSplit contract, the main entry point for Buy/Sell Fragment. You&#39;ll find all the events and external functions, as well as the reasoning behind them here.



## Methods

### addETHLiquidity

```solidity
function addETHLiquidity(bytes32 subject) external payable
```

add eth liquidity for key pool. only can be called from FragmentPool address to help sell whole key to tomo



#### Parameters

| Name | Type | Description |
|---|---|---|
| subject | bytes32 | Identity of one tomo. |

### buyFragmentVotePass

```solidity
function buyFragmentVotePass(bytes32 subject, uint256 amount, uint256 maxAcceptPrice) external payable
```

Sell the Fragment Key/Vote.



#### Parameters

| Name | Type | Description |
|---|---|---|
| subject | bytes32 | Identity of one tomo. |
| amount | uint256 | The sell amount. |
| maxAcceptPrice | uint256 | The min price seller can accept. |

### buyVotePassAndFragment

```solidity
function buyVotePassAndFragment(bytes32 subject, uint256 amount, uint256 fragmentAmount, uint256 maxAcceptPrice, uint8[] v, bytes32[] r, bytes32[] s) external payable
```

Buy And Fragment Key/Vote.



#### Parameters

| Name | Type | Description |
|---|---|---|
| subject | bytes32 | Identity of one tomo. |
| amount | uint256 | The buy amount. |
| fragmentAmount | uint256 | The amount of each key can fragment |
| maxAcceptPrice | uint256 | The max price that call can pay for amount key. |
| v | uint8[] | The V of signature |
| r | bytes32[] | The r of signature |
| s | bytes32[] | The s of signature |

### buyVotePassWithLockTimeStamp

```solidity
function buyVotePassWithLockTimeStamp(bytes32 subject, uint256 amount, uint256 maxAcceptPrice, uint256 lockUntil, uint8[] v, bytes32[] r, bytes32[] s) external payable
```

buy VotePass and set a lock time, can sell if timestame less than you set



#### Parameters

| Name | Type | Description |
|---|---|---|
| subject | bytes32 | Identity of one tomo. |
| amount | uint256 | The buy amount. |
| maxAcceptPrice | uint256 | The max price that call can pay for amount key. |
| lockUntil | uint256 | undefined |
| v | uint8[] | The V of signature |
| r | bytes32[] | The r of signature |
| s | bytes32[] | The s of signature |

### getAllLockIndexByAddress

```solidity
function getAllLockIndexByAddress(address locker) external view returns (uint256[])
```

get all lock index by address



#### Parameters

| Name | Type | Description |
|---|---|---|
| locker | address | locker address |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256[] | undefined |

### getLockInfoByIndex

```solidity
function getLockInfoByIndex(uint256 index) external view returns (struct DataTypes.VotePassLockInfo)
```

get Lock Info by index



#### Parameters

| Name | Type | Description |
|---|---|---|
| index | uint256 | LockIndex |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | DataTypes.VotePassLockInfo | undefined |

### initialize

```solidity
function initialize(address governanceContractAddress, address protocolFeeAddress) external nonpayable
```

initialize smart contract.



#### Parameters

| Name | Type | Description |
|---|---|---|
| governanceContractAddress | address | The governance address to set. |
| protocolFeeAddress | address | The protocol fee address to set. |

### quitFromLiquidityProvider

```solidity
function quitFromLiquidityProvider(bytes32 subject) external nonpayable
```

quit from liquidity provider, get back all votepass and eth reward. send whole votepass to tomo contract, if have left fragment votepass, become a normal user who hold fragment vote pass, than can sell to other liquidity provider only can be called from FragmentPool address to help sell whole key to tomo



#### Parameters

| Name | Type | Description |
|---|---|---|
| subject | bytes32 | Identity of one tomo. |

### sellFragmentVotePass

```solidity
function sellFragmentVotePass(bytes32 subject, uint256 amount, uint256 minAcceptPrice) external nonpayable
```

Sell the Fragment Key/Vote.



#### Parameters

| Name | Type | Description |
|---|---|---|
| subject | bytes32 | Identity of one tomo. |
| amount | uint256 | The sell amount. |
| minAcceptPrice | uint256 | The min price seller can accept. |

### sellLockVotePass

```solidity
function sellLockVotePass(uint256 lockIndex, uint256 amount, uint256 minAcceptPrice, address payable receiveFund) external nonpayable
```

sell Vote Pass after be unlocked



#### Parameters

| Name | Type | Description |
|---|---|---|
| lockIndex | uint256 | locke index |
| amount | uint256 | sell amount |
| minAcceptPrice | uint256 | minAcceptPrice The min price seller can accept. |
| receiveFund | address payable | undefined |

### sellVotePass

```solidity
function sellVotePass(bytes32 subject, uint256 amount, address payable seller) external nonpayable
```

Sell the Key/Vote. only can be called from FragmentPool address to help sell whole key to tomo



#### Parameters

| Name | Type | Description |
|---|---|---|
| subject | bytes32 | Identity of one tomo. |
| amount | uint256 | The sell amount. |
| seller | address payable | The address of seller |

### setGovernance

```solidity
function setGovernance(address newGovernance) external nonpayable
```

set new governance address



#### Parameters

| Name | Type | Description |
|---|---|---|
| newGovernance | address | new address |

### setMinPriceKeyCanFragment

```solidity
function setMinPriceKeyCanFragment(uint256 minPrice) external nonpayable
```

set min price of one key/vote can fragment



#### Parameters

| Name | Type | Description |
|---|---|---|
| minPrice | uint256 | new min price |

### setProtocolFeeAddress

```solidity
function setProtocolFeeAddress(address newProtocolFeeAddress) external nonpayable
```

set new protocol fee address



#### Parameters

| Name | Type | Description |
|---|---|---|
| newProtocolFeeAddress | address | new fee address |

### setState

```solidity
function setState(enum DataTypes.TomoHubEntryPointState newState) external nonpayable
```

set new state of TomoHubEntryPoint



#### Parameters

| Name | Type | Description |
|---|---|---|
| newState | enum DataTypes.TomoHubEntryPointState | new state |

### transferLockVotePass

```solidity
function transferLockVotePass(uint256 lockIndex, address to) external nonpayable
```

transfer lock Vote Pass to other



#### Parameters

| Name | Type | Description |
|---|---|---|
| lockIndex | uint256 | locke index |
| to | address | the address receipt lock vote pass |




