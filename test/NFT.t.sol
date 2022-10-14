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
            256,
            0xb0a1b2f7f7a2093da2247ed16f0c06cf02ce164f,
            "IPFS directory containing metadata for 3 tiers Qmd681A6CHQRvqfRQpWUhvsD43H5NyJmhsLmZz9r5fR34R",
            1657972800
        );
    }

    function testMint() public {
        nft.mint{value: 0.1 ether}();
        assertEq(nft.balanceOf(address(this)), 1);
        assertEq(nft.ownerOf(1), address(this));
    }
}
