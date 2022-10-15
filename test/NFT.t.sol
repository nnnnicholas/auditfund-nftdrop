// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/NFT.sol";
import "juice-contracts-v2/interfaces/IJBSingleTokenPaymentTerminalStore.sol";
import "juice-contracts-v2/interfaces/IJBTokenStore.sol";
import "juice-contracts-v2/interfaces/IJBPayoutRedemptionPaymentTerminal.sol";

contract NFTTest is Test {
    NFT public nft;
    IJBTokenStore tokenStore =
        IJBTokenStore(0xCBB8e16d998161AdB20465830107ca298995f371);
    IJBSingleTokenPaymentTerminalStore singleTokenPaymentTerminalStore =
        IJBSingleTokenPaymentTerminalStore(
            0x96a594ABE6B910E05E486b63B32fFe29DA5d33f7
        );
    IJBSingleTokenPaymentTerminal ethPaymentTerminal =
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
            ethPaymentTerminal,
            256
        ); // balance before
        nft.mint{value: uint256(0.1 ether)}();
        uint256 balanceAfter = singleTokenPaymentTerminalStore.balanceOf(
            ethPaymentTerminal,
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

    function testBatchOwnerMint() public {
        address[] memory _to = new address[](10);
        _to[0] = address(0x1);
        _to[1] = address(0x2);
        _to[2] = address(0x3);
        _to[3] = address(0x4);
        _to[4] = address(0x5);
        _to[5] = address(0x6);
        _to[6] = address(0x7);
        _to[7] = address(0x8);
        _to[8] = address(0x9);
        _to[9] = address(0x10);
        uint256[] memory _tier = new uint256[](10);
        _tier[0] = uint256(1);
        _tier[1] = uint256(1);
        _tier[2] = uint256(1);
        _tier[3] = uint256(2);
        _tier[4] = uint256(2);
        _tier[5] = uint256(2);
        _tier[6] = uint256(3);
        _tier[7] = uint256(3);
        _tier[8] = uint256(3);
        _tier[9] = uint256(3);
        nft.ownerBatchMint(_to, _tier);
        for (uint256 i = 0; i < _to.length; i++) {
            assertEq(nft.ownerOf(i+1), _to[i]);
            assertEq(nft.tierOf(i+1), _tier[i]);
        }
    }

    // Check that redemptions work
    function testRedemption() public {
        address payable pranksy = payable(address(0xd8dA6BF26964aF9D7eEd9e03E53415D37aA96045));
        vm.startPrank(pranksy);
        uint256 balanceBefore = pranksy.balance; // balance before
        nft.mint{value: uint256(10 ether)}();
        assertEq(nft.ownerOf(1), pranksy);
        assertEq(
            tokenStore.balanceOf(pranksy, 256),
            1_000_000 * 10 ether
        );
        IJBPayoutRedemptionPaymentTerminal(address(ethPaymentTerminal))
            .redeemTokensOf(
                pranksy,
                256,
                tokenStore.balanceOf(pranksy, 256),
                JBTokens.ETH,
                0,
                payable(pranksy),
                "",
                bytes("")
            );
        uint256 balanceAfter = pranksy.balance; // balance after
        assertEq(balanceAfter, balanceBefore);
    }
}
