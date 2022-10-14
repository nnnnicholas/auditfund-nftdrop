// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/NFT.sol";

contract NFTTest is Test {
    NFT public nft;

    function setUp() public {
        nft = new NFT(
            "NFT Rewards Audit Fund",
            "AUDIT",
            payable(),
            "ipfs://QmXQoVyXbCt1ccjAExKjVLcamGgr2USLftNGEWx4ZzmGpi",
            1666051200
        );
    }

    function testMint() public {
        nft.mint{value: 0.1 ether}();
        assertEq(nft.balanceOf(address(this)), 1);
        assertEq(nft.ownerOf(1), address(this));
    }
}
