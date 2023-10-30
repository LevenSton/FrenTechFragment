# TomoHubEntryPoint









## Methods

### _globalLockIndex

```solidity
function _globalLockIndex() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### _governance

```solidity
function _governance() external view returns (address)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### _minPriceKeyCanFragment

```solidity
function _minPriceKeyCanFragment() external view returns (uint256)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### _state

```solidity
function _state() external view returns (enum DataTypes.TomoHubEntryPointState)
```






#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | enum DataTypes.TomoHubEntryPointState | undefined |

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
function initialize(address newGovernanceContractAddress) external nonpayable
```

initialize smart contract.



#### Parameters

| Name | Type | Description |
|---|---|---|
| newGovernanceContractAddress | address | The governance address to set. |

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
function sellVotePass(bytes32 subject, address seller, uint256 amount) external nonpayable
```

Sell the Key/Vote. only can be called from FragmentPool address to help sell whole key to tomo



#### Parameters

| Name | Type | Description |
|---|---|---|
| subject | bytes32 | Identity of one tomo. |
| seller | address | The address of seller |
| amount | uint256 | The sell amount. |

### setGovernance

```solidity
function setGovernance(address newGovernance) external nonpayable
```

*********************** *****GOV FUNCTIONS***** ***********************



#### Parameters

| Name | Type | Description |
|---|---|---|
| newGovernance | address | undefined |

### setMinPriceKeyCanFragment

```solidity
function setMinPriceKeyCanFragment(uint256 minPrice) external nonpayable
```

set min price of one key/vote can fragment



#### Parameters

| Name | Type | Description |
|---|---|---|
| minPrice | uint256 | new min price |

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



## Events

### AddFragmentKeyLiquidity

```solidity
event AddFragmentKeyLiquidity(address fragmentPoolAddress, address liquidityProvider, uint256 fragmentKeyLiquidity, uint256 timeStamp)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| fragmentPoolAddress  | address | undefined |
| liquidityProvider  | address | undefined |
| fragmentKeyLiquidity  | uint256 | undefined |
| timeStamp  | uint256 | undefined |

### GovernanceSet

```solidity
event GovernanceSet(address indexed caller, address indexed prevGovernance, address indexed newGovernance, uint256 timestamp)
```



*Emitted when the governance address is changed. We emit the caller even though it should be the previous governance address, as we cannot guarantee this will always be the case due to upgradeability.*

#### Parameters

| Name | Type | Description |
|---|---|---|
| caller `indexed` | address | The caller who set the governance address. |
| prevGovernance `indexed` | address | The previous governance address. |
| newGovernance `indexed` | address | The new governance address set. |
| timestamp  | uint256 | The current block timestamp. |

### MinPriceKeyCanFragment

```solidity
event MinPriceKeyCanFragment(address indexed caller, uint256 indexed preMinPriceKeyCanFragment, uint256 indexed newMinPriceKeyCanFragment, uint256 timestamp)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| caller `indexed` | address | undefined |
| preMinPriceKeyCanFragment `indexed` | uint256 | undefined |
| newMinPriceKeyCanFragment `indexed` | uint256 | undefined |
| timestamp  | uint256 | undefined |

### NewFragmentPoolCreate

```solidity
event NewFragmentPoolCreate(bytes32 subject, address creator, address poolAddress, uint256 fragmentAmount)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| subject  | bytes32 | undefined |
| creator  | address | undefined |
| poolAddress  | address | undefined |
| fragmentAmount  | uint256 | undefined |

### SellLockVotePass

```solidity
event SellLockVotePass(bytes32 subject, uint256 lockIndex, uint256 amount, uint256 sellPrice, address seller)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| subject  | bytes32 | undefined |
| lockIndex  | uint256 | undefined |
| amount  | uint256 | undefined |
| sellPrice  | uint256 | undefined |
| seller  | address | undefined |

### StateSet

```solidity
event StateSet(address indexed caller, enum DataTypes.TomoHubEntryPointState indexed prevState, enum DataTypes.TomoHubEntryPointState indexed newState, uint256 timestamp)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| caller `indexed` | address | undefined |
| prevState `indexed` | enum DataTypes.TomoHubEntryPointState | undefined |
| newState `indexed` | enum DataTypes.TomoHubEntryPointState | undefined |
| timestamp  | uint256 | undefined |

### TradeFragmentSuccess

```solidity
event TradeFragmentSuccess(bytes32 subject, address buyer, uint256 amount, uint256 price, bool bBuy)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| subject  | bytes32 | undefined |
| buyer  | address | undefined |
| amount  | uint256 | undefined |
| price  | uint256 | undefined |
| bBuy  | bool | undefined |

### TransferLockVotePass

```solidity
event TransferLockVotePass(uint256 lockIndex, address from, address to)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| lockIndex  | uint256 | undefined |
| from  | address | undefined |
| to  | address | undefined |



## Errors

### AlreadyContrainThisLockIndex

```solidity
error AlreadyContrainThisLockIndex()
```






### CallerNeedBeFragmentPool

```solidity
error CallerNeedBeFragmentPool()
```






### CanNotSellBeforeDeadline

```solidity
error CanNotSellBeforeDeadline()
```






### CannotInitImplementation

```solidity
error CannotInitImplementation()
```






### FragmentPoolNotExist

```solidity
error FragmentPoolNotExist()
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






### KeyPriceTooLowCanNotBeFragment

```solidity
error KeyPriceTooLowCanNotBeFragment()
```






### LargeThanMaxAcceptPrice

```solidity
error LargeThanMaxAcceptPrice()
```






### LessThanMinAcceptPrice

```solidity
error LessThanMinAcceptPrice()
```






### NotAvaiableAmount

```solidity
error NotAvaiableAmount()
```






### NotContrainThisLockIndex

```solidity
error NotContrainThisLockIndex()
```






### NotGovernance

```solidity
error NotGovernance()
```






### NotLockOwner

```solidity
error NotLockOwner()
```






### SendETHFailed

```solidity
error SendETHFailed()
```






### VotePassNotEnough

```solidity
error VotePassNotEnough()
```







