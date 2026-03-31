# Staking Facet Integration

## What Was Done

Converted the standalone `StakingRewards.sol` contract into a Diamond facet, making it upgradable and part of the modular diamond architecture.

## Files Created

### 1. `contracts/facets/StakingFacet.sol`
- Main staking facet with all user-facing functions
- Functions: `initializeStaking`, `stake`, `withdraw`, `claimRewards`, `emergencyWithdraw`, `updateRewardRate`, `earned`, `getStake`, `getTotalStaked`, `getStakingToken`
- Uses diamond storage pattern via `LibStaking`

### 2. `contracts/libraries/LibStaking.sol`
- Storage library for staking data
- Uses diamond storage pattern with unique storage slot
- Contains helper functions: `earned()` and `_updateRewards()`
- Stores: stakingToken, rewardRate, lockPeriod, earlyWithdrawPenalty, stakes mapping, totalStaked

## Files Modified

### 1. `contracts/StakingToken.sol`
- Added `mint()` function for testing purposes

### 2. `test/deployDiamond.t.sol`
- Added `StakingFacet` and `StakingToken` imports
- Added `testStakingFacet()` test that:
  - Deploys staking token
  - Adds StakingFacet to diamond
  - Initializes staking with token address
  - Tests staking functionality

## How It Works

1. **Diamond Storage Pattern**: Uses a unique storage slot (`keccak256("diamond.standard.staking.storage")`) to avoid storage collisions with other facets

2. **Initialization**: Owner must call `initializeStaking(tokenAddress)` once after adding the facet

3. **Staking Features**:
   - Stake ERC20 tokens
   - Earn rewards over time (100 tokens per second per staked token)
   - 7-day lock period with 10% early withdrawal penalty
   - Emergency withdraw option
   - Owner can update reward rate

## Testing

Run tests with:
```bash
forge test -vv
```

Both tests pass:
- `testInDiamondLoupeFacetcreaseCount()` - Original counter test
- `testStakingFacet()` - New staking integration test

## Usage Example

```solidity
// After deploying diamond and adding StakingFacet
StakingFacet(diamondAddress).initializeStaking(tokenAddress);

// Users can stake
token.approve(diamondAddress, amount);
StakingFacet(diamondAddress).stake(amount);

// Check earned rewards
uint256 rewards = StakingFacet(diamondAddress).earned(userAddress);

// Claim rewards
StakingFacet(diamondAddress).claimRewards();

// Withdraw stake
StakingFacet(diamondAddress).withdraw(amount);
```

## Benefits

- **Upgradable**: Can replace staking logic without redeploying
- **Modular**: Staking is isolated in its own facet
- **Shared Storage**: All facets access the same diamond storage
- **Single Address**: Users interact with one diamond address
- **No Size Limit**: Can add unlimited features via more facets
