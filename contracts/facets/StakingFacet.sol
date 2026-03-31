// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import {LibStaking} from "../libraries/LibStaking.sol";

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
}

contract StakingFacet {
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardsClaimed(address indexed user, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 amount);
    event RewardRateUpdated(uint256 newRate);
    
    function initializeStaking(address _stakingToken) external {
        LibDiamond.enforceIsContractOwner();
        LibStaking.StakingStorage storage s = LibStaking.stakingStorage();
        require(s.stakingToken == address(0), "Already initialized");
        s.stakingToken = _stakingToken;
        s.rewardRate = 100;
        s.lockPeriod = 7 days;
        s.earlyWithdrawPenalty = 10;
    }
    
    function stake(uint256 amount) external {
        require(amount > 0, "Cannot stake 0");
        LibStaking.StakingStorage storage s = LibStaking.stakingStorage();
        
        LibStaking._updateRewards(msg.sender);
        
        IERC20(s.stakingToken).transferFrom(msg.sender, address(this), amount);
        s.stakes[msg.sender].amount += amount;
        if (s.stakes[msg.sender].stakeTime == 0) {
            s.stakes[msg.sender].stakeTime = block.timestamp;
        }
        s.totalStaked += amount;
        
        emit Staked(msg.sender, amount);
    }
    
    function withdraw(uint256 amount) external {
        require(amount > 0, "Cannot withdraw 0");
        LibStaking.StakingStorage storage s = LibStaking.stakingStorage();
        require(s.stakes[msg.sender].amount >= amount, "Insufficient stake");
        
        LibStaking._updateRewards(msg.sender);
        
        uint256 withdrawAmount = amount;
        if (block.timestamp < s.stakes[msg.sender].stakeTime + s.lockPeriod) {
            uint256 penalty = (amount * s.earlyWithdrawPenalty) / 100;
            withdrawAmount = amount - penalty;
        }
        
        s.stakes[msg.sender].amount -= amount;
        s.totalStaked -= amount;
        IERC20(s.stakingToken).transfer(msg.sender, withdrawAmount);
        
        emit Withdrawn(msg.sender, amount);
    }
    
    function claimRewards() external {
        LibStaking.StakingStorage storage s = LibStaking.stakingStorage();
        LibStaking._updateRewards(msg.sender);
        
        uint256 reward = s.stakes[msg.sender].rewardDebt;
        require(reward > 0, "No rewards");
        
        s.stakes[msg.sender].rewardDebt = 0;
        IERC20(s.stakingToken).transfer(msg.sender, reward);
        
        emit RewardsClaimed(msg.sender, reward);
    }
    
    function emergencyWithdraw() external {
        LibStaking.StakingStorage storage s = LibStaking.stakingStorage();
        uint256 amount = s.stakes[msg.sender].amount;
        require(amount > 0, "You didn't stake");
        
        s.stakes[msg.sender].amount = 0;
        s.stakes[msg.sender].rewardDebt = 0;
        s.stakes[msg.sender].lastUpdateTime = 0;
        s.stakes[msg.sender].stakeTime = 0;
        s.totalStaked -= amount;
        
        IERC20(s.stakingToken).transfer(msg.sender, amount);
        
        emit EmergencyWithdraw(msg.sender, amount);
    }
    
    function updateRewardRate(uint256 newRate) external {
        LibDiamond.enforceIsContractOwner();
        LibStaking.StakingStorage storage s = LibStaking.stakingStorage();
        s.rewardRate = newRate;
        emit RewardRateUpdated(newRate);
    }
    
    function earned(address account) external view returns (uint256) {
        return LibStaking.earned(account);
    }
    
    function getStake(address account) external view returns (uint256 amount, uint256 rewardDebt, uint256 lastUpdateTime, uint256 stakeTime) {
        LibStaking.StakingStorage storage s = LibStaking.stakingStorage();
        LibStaking.Stake memory userStake = s.stakes[account];
        return (userStake.amount, userStake.rewardDebt, userStake.lastUpdateTime, userStake.stakeTime);
    }
    
    function getTotalStaked() external view returns (uint256) {
        return LibStaking.stakingStorage().totalStaked;
    }
    
    function getStakingToken() external view returns (address) {
        return LibStaking.stakingStorage().stakingToken;
    }
}
