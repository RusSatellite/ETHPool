// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "hardhat/console.sol";

contract ETHPool is Ownable {

    using SafeMath for uint256;

    address[] internal stakeholders;
    mapping (address => uint256) internal stakes;
    mapping (address => uint256) internal rewards;
    mapping (address => uint256) internal lastUpdated;

    function isStakeHolder(address _address)
        internal
        view
        returns (bool, uint256)
    {
        for (uint256 i = 0; i < stakeholders.length; i += 1) {
            if (stakeholders[i] == _address) {
                return (true, i);
            }
        }
        return (false, 0);
    }

    function addStakeHolder(address _stakeHolder) 
        internal
    {
        (bool _isStakeHolder, ) = isStakeHolder(_stakeHolder);
        if (!_isStakeHolder) {
            stakeholders.push(_stakeHolder);
        }
    }

    function removeStakeHolder(address _stakeHolder)
        internal
    {
        (bool _isStakeHolder, uint256 _index) = isStakeHolder(_stakeHolder);
        if (_isStakeHolder) {
            stakeholders[_index] = stakeholders[stakeholders.length - 1];
            stakeholders.pop();
        }
    }

    function stakeOf()
        public
        view
        returns (uint256)
    {
        return stakes[msg.sender];
    }

    function totalStakes()
        public
        view
        returns (uint256)
    {
        uint256 _totalStakes = 0;
        for (uint256 i = 0; i < stakeholders.length; i += 1) {
            _totalStakes = _totalStakes.add(stakes[stakeholders[i]]);
        }
        return _totalStakes;
    }

    function createStake()
        public
        payable
    {
        
        if (stakes[msg.sender] == 0) {
            addStakeHolder(msg.sender);
            lastUpdated[msg.sender] = block.timestamp;
        }
        stakes[msg.sender] = stakes[msg.sender].add(msg.value);
    }

    function removeStake()
        public
    {
        payable(msg.sender).transfer(stakes[msg.sender] + rewards[msg.sender]);
        removeStakeHolder(msg.sender);
        stakes[msg.sender] = 0;
        rewards[msg.sender] = 0;
    }

    function rewardOf()
        public
        view
        returns (uint256)
    {
        return rewards[msg.sender];
    }

    function totalRewards()
        public
        view
        returns (uint256)
    {
        uint256 _totalRewards = 0;
        for (uint256 i = 0; i < stakeholders.length; i += 1) {
            _totalRewards = _totalRewards.add(rewards[stakeholders[i]]);
        }
        return _totalRewards;
    }

    function distributeRewards(uint256 _reward)
        internal
    {
        uint256 _totalMarks = 0;
        uint256 _curTime = block.timestamp;
        for (uint256 i = 0; i < stakeholders.length; i += 1) {
            address _stakeHolder = stakeholders[i];
            _totalMarks = _totalMarks.add((_curTime - lastUpdated[_stakeHolder]) * stakes[_stakeHolder] / 60 / 60 / 24);
        }
        if (_totalMarks > 0) {
            for (uint256 i = 0; i < stakeholders.length; i += 1) {
                address _stakeHolder = stakeholders[i];
                rewards[_stakeHolder] = rewards[_stakeHolder].add(((_curTime - lastUpdated[_stakeHolder]) * stakes[_stakeHolder] / 60 / 60 / 24) * _reward / _totalMarks);
                lastUpdated[_stakeHolder] = _curTime;
            }
        }
    }

    function getBalance()
        public
        view
        returns (uint256)
    {
        return address(this).balance;
    }

    function withdrawReward()
        public
    {
        payable(msg.sender).transfer(rewards[msg.sender]);
        rewards[msg.sender] = 0;
    }

    function depositeRewards()
        public
        payable
        onlyOwner
    {
        distributeRewards(msg.value);
    }
}