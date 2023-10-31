# ITomo

*Tomo Protocol*

> ITomo





## Methods

### buyVotePass

```solidity
function buyVotePass(bytes32 subject, uint256 amount, uint8[] v, bytes32[] r, bytes32[] s) external payable
```

Buy Key/Vote.



#### Parameters

| Name | Type | Description |
|---|---|---|
| subject | bytes32 | Identity of one tomo. |
| amount | uint256 | The buy amount. |
| v | uint8[] | v of signature. |
| r | bytes32[] | r of signature. |
| s | bytes32[] | s of signature. |

### getBuyPrice

```solidity
function getBuyPrice(bytes32 subject, uint256 amount) external view returns (uint256)
```

get total price with buy amout key of subject.



#### Parameters

| Name | Type | Description |
|---|---|---|
| subject | bytes32 | Identity of one tomo. |
| amount | uint256 | The buy amount |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### getBuyPriceAfterFee

```solidity
function getBuyPriceAfterFee(bytes32 subject, uint256 amount) external view returns (uint256)
```

get total price after fee with buy amout key of subject.



#### Parameters

| Name | Type | Description |
|---|---|---|
| subject | bytes32 | Identity of one tomo. |
| amount | uint256 | The buy amount |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### getPrice

```solidity
function getPrice(uint256 supply, uint256 amount) external pure returns (uint256)
```





#### Parameters

| Name | Type | Description |
|---|---|---|
| supply | uint256 | undefined |
| amount | uint256 | undefined |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### getSellPrice

```solidity
function getSellPrice(bytes32 subject, uint256 amount) external view returns (uint256)
```

get total price with sell amout key of subject.



#### Parameters

| Name | Type | Description |
|---|---|---|
| subject | bytes32 | Identity of one tomo. |
| amount | uint256 | The sell amount |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### getSellPriceAfterFee

```solidity
function getSellPriceAfterFee(bytes32 subject, uint256 amount) external view returns (uint256)
```

get total price after fee with sell amout key of subject.



#### Parameters

| Name | Type | Description |
|---|---|---|
| subject | bytes32 | Identity of one tomo. |
| amount | uint256 | The sell amount |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### getSubjectBalanceOf

```solidity
function getSubjectBalanceOf(bytes32 subject, address account) external view returns (uint256)
```

get balance of one subject a account  hold.



#### Parameters

| Name | Type | Description |
|---|---|---|
| subject | bytes32 | Identity of one tomo. |
| account | address | Address of account. |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### getSubjectETHBalance

```solidity
function getSubjectETHBalance(bytes32 subject) external view returns (uint256)
```

get eth balance of one subject.



#### Parameters

| Name | Type | Description |
|---|---|---|
| subject | bytes32 | Identity of one tomo. |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### getSubjectOwner

```solidity
function getSubjectOwner(bytes32 subject) external view returns (address)
```

get SubjectOwner of one subject.



#### Parameters

| Name | Type | Description |
|---|---|---|
| subject | bytes32 | Identity of one tomo. |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | address | undefined |

### getSubjectSupply

```solidity
function getSubjectSupply(bytes32 subject) external view returns (uint256)
```

get supply of one subject.



#### Parameters

| Name | Type | Description |
|---|---|---|
| subject | bytes32 | Identity of one tomo. |

#### Returns

| Name | Type | Description |
|---|---|---|
| _0 | uint256 | undefined |

### sellVotePass

```solidity
function sellVotePass(bytes32 subject, uint256 amount) external nonpayable
```

Sell Key/Vote.



#### Parameters

| Name | Type | Description |
|---|---|---|
| subject | bytes32 | Identity of one tomo. |
| amount | uint256 | The sell amount |




