// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library LibStaking {
    bytes32 constant STAKING_STORAGE_POSITION = keccak256("diamond.standard.staking.storage");
    
    struct Stake {
        uint256 amount;
        uint256 rewardDebt;
        uint256 lastUpdateTime;
        uint256 stakeTime;
    }
    
    struct StakingStorage {
        address stakingToken;
        uint256 rewardRate;
        uint256 lockPeriod;
        uint256 earlyWithdrawPenalty;
        mapping(address => Stake) stakes;
        uint256 totalStaked;
    }
    
    function stakingStorage() internal pure returns (StakingStorage storage ss) {
        bytes32 position = STAKING_STORAGE_POSITION;
        assembly {
            ss.slot := position
        }
    }
    
    function earned(address account) internal view returns (uint256) {
        StakingStorage storage s = stakingStorage();
        Stake memory userStake = s.stakes[account];
        if (userStake.amount == 0) return userStake.rewardDebt;
        
        uint256 timeElapsed = block.timestamp - userStake.lastUpdateTime;
        uint256 newRewards = (userStake.amount * s.rewardRate * timeElapsed) / 1e18;
        return userStake.rewardDebt + newRewards;
    }
    
    function _updateRewards(address account) internal {
        StakingStorage storage s = stakingStorage();
        s.stakes[account].rewardDebt = earned(account);
        s.stakes[account].lastUpdateTime = block.timestamp;
    }
}
