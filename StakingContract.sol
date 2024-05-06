// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract YointsStaking is Ownable, ReentrancyGuard {
    IERC20 public stakingToken;
    IERC20 public rewardToken;

    struct Staker {
        uint256 stakedAmount;
        uint256 rewardDebt;
        uint256 stakeTime;
    }

    mapping(address => Staker) public stakers;

    uint256 public rewardRatePerToken;
    uint256 public totalStaked;
    uint256 public lastRewardTime;
    uint256 public accRewardPerToken;
    uint256 public lockupDuration = 30 days;

    constructor(address _stakingToken, address _rewardToken, uint256 _rewardRatePerToken) {
        stakingToken = IERC20(_stakingToken);
        rewardToken = IERC20(_rewardToken);
        rewardRatePerToken = _rewardRatePerToken;
    }

    function updatePool() internal {
        if (block.timestamp <= lastRewardTime) {
            return;
        }
        if (totalStaked == 0) {
            lastRewardTime = block.timestamp;
            return;
        }
        uint256 timeElapsed = block.timestamp - lastRewardTime;
        uint256 rewardAmount = timeElapsed * rewardRatePerToken * totalStaked;
        accRewardPerToken += rewardAmount / totalStaked;
        lastRewardTime = block.timestamp;
    }

    function stake(uint256 amount) external nonReentrant {
        Staker storage staker = stakers[msg.sender];
        updatePool();
        if (staker.stakedAmount > 0) {
            uint256 pending = (staker.stakedAmount * accRewardPerToken - staker.rewardDebt) / 1e12;
            rewardToken.transfer(msg.sender, pending);
        }
        stakingToken.transferFrom(msg.sender, address(this), amount);
        totalStaked += amount;
        staker.stakedAmount += amount;
        staker.rewardDebt = staker.stakedAmount * accRewardPerToken / 1e12;
        staker.stakeTime = block.timestamp;
    }

    function unstake(uint256 amount) external nonReentrant {
        Staker storage staker = stakers[msg.sender];
        require(block.timestamp >= staker.stakeTime + lockupDuration, "Tokens are locked");
        require(staker.stakedAmount >= amount, "Not enough tokens staked");
        updatePool();
        uint256 pending = (staker.stakedAmount * accRewardPerToken - staker.rewardDebt) / 1e12;
        rewardToken.transfer(msg.sender, pending);
        staker.stakedAmount -= amount;
        totalStaked -= amount;
        staker.rewardDebt = staker.stakedAmount * accRewardPerToken / 1e12;
        stakingToken.transfer(msg.sender, amount);
    }

    function claimRewards() external nonReentrant {
        Staker storage staker = stakers[msg.sender];
        updatePool();
        uint256 pending = (staker.stakedAmount * accRewardPerToken - staker.rewardDebt) / 1e12;
        staker.rewardDebt = staker.stakedAmount * accRewardPerToken / 1e12;
        rewardToken.transfer(msg.sender, pending);
    }
}

