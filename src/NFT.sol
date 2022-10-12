// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC721} from "solmate/tokens/ERC721.sol";

contract NFT is ERC721 {

mapping (uint256 => string) public tokenURIs;

    constructor() ERC721("NFT Rewards Audit Fund", "AUDIT") {}

    function tokenURI(uint256 id) public view override returns (string memory) {
        return "https://example.com";
    }
}
