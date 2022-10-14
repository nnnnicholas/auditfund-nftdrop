// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/NFT.sol";
import "juice-contracts-v2/interfaces/IJBSingleTokenPaymentTerminalStore.sol";
import "juice-contracts-v2/interfaces/IJBTokenStore.sol";

contract NFTTest is Test {
    NFT public nft;
    IJBTokenStore tokenStore =
        IJBTokenStore(0xCBB8e16d998161AdB20465830107ca298995f371);
    IJBSingleTokenPaymentTerminalStore singleTokenPaymentTerminalStore =
        IJBSingleTokenPaymentTerminalStore(
            0x96a594ABE6B910E05E486b63B32fFe29DA5d33f7
        );
    IJBSingleTokenPaymentTerminal primaryEthPaymentTerminal =
        IJBSingleTokenPaymentTerminal(
            0x7Ae63FBa045Fec7CaE1a75cF7Aa14183483b8397
        );
    uint256[8] values = [
        uint256(0.1 ether),
        uint256(0.11 ether),
        uint256(0.99999 ether),
        uint256(1 ether),
        uint256(1.01 ether),
        uint256(9.9999 ether),
        uint256(10 ether),
        uint256(100 ether)
    ];
    uint256[8] tiers = [
        uint256(1),
        uint256(1),
        uint256(1),
        uint256(2),
        uint256(2),
        uint256(2),
        uint256(3),
        uint256(3)
    ];
    string baseUri = "ipfs://QmXQoVyXbCt1ccjAExKjVLcamGgr2USLftNGEWx4ZzmGpi";

    function setUp() public {
        nft = new NFT(
            "NFT Rewards Audit Fund",
            "AUDIT",
            256,
            address(0),
            baseUri,
            1666051200
        );
    }

    function testMint() public {
        for (uint256 i = 0; i < values.length; i++) {
            nft.mint{value: uint256(values[i])}();
            uint256 tokenId = nft.totalSupply();
            assertEq(nft.balanceOf(address(this)), i + 1);
            assertEq(nft.ownerOf(tokenId), address(this));
            assertEq(nft.tierOf(tokenId), tiers[i]);
        }
    }

    function testFailMint() public {
        nft.mint{value: uint256(0.09 ether)}();
    }

    function testTokenUri() public {
        for (uint256 i = 0; i < values.length; i++) {
            nft.mint{value: values[i]}();
            uint256 tokenId = nft.totalSupply();
            assertEq(
                nft.tokenURI(tokenId),
                string(
                    abi.encodePacked(baseUri, "/", Strings.toString(tiers[i]))
                )
            );
        }
    }

    function testOwnerIsDeployer() public {
        assertEq(nft.owner(), address(this));
    }

    // Check JB received funds
    function testJBReceivedFunds() public {
        uint256 balance = singleTokenPaymentTerminalStore.balanceOf(
            primaryEthPaymentTerminal,
            256
        ); // balance before
        nft.mint{value: uint256(0.1 ether)}();
        uint256 balanceAfter = singleTokenPaymentTerminalStore.balanceOf(
            primaryEthPaymentTerminal,
            256
        ); // balance after
        assertEq(balanceAfter, balance + uint256(0.1 ether));
    }

    // Check minter received project tokens
    function testTokensIssuedToMinter() public {
        uint256 balance = tokenStore.balanceOf(address(this), 256); // balance before
        nft.mint{value: uint256(0.1 ether)}();
        uint256 balanceAfter = tokenStore.balanceOf(address(this), 256); // balance after
        assertEq(balanceAfter, balance + 1_000_000 * 0.1 ether);
    }

    function testOwnerMint(address _to, uint256 _tier) public {
        vm.assume(_tier == 1 || _tier == 2 || _tier == 3);
        vm.assume(_to != address(0));
        nft.ownerMint(_to, _tier);
        assertEq(nft.balanceOf(_to), 1);
        assertEq(nft.ownerOf(nft.totalSupply()), _to);
        assertEq(nft.tierOf(nft.totalSupply()), _tier);
    }

    // batch owner mint
    // Check pay memo is correct
    
}
