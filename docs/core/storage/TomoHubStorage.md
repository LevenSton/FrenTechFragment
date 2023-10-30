# TomoHubStorage

*Tomo Protocol*

> TomoHubStorage

This is an abstract contract that *only* contains storage for the TomoFragment contract. This *must* be inherited last (bar interfaces) in order to preserve the TomoFragment storage layout. Adding storage variables should be done solely at the bottom of this contract.



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




