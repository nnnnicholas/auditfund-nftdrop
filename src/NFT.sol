// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ERC721} from "solmate/tokens/ERC721.sol";
import {Ownable} from "openzeppelin-contracts/access/Ownable.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";
import {Strings} from "openzeppelin-contracts/utils/Strings.sol";

contract NFT is ERC721, ReentrancyGuard, Ownable {
    mapping(uint256 => uint256) public tierOf; // TODO rename tierOf
    string public baseUri;
    uint256 public totalSupply;
    uint256 private immutable deadline;
    address payable public immutable auditfund;

    constructor(
        string memory _name, // NFT Rewards Audit Fund
        string memory _symbol, // AUDIT
        address payable _auditfund,
        string memory _baseUri, // IPFS directory containing metadata for 3 tiers ipfs://QmXQoVyXbCt1ccjAExKjVLcamGgr2USLftNGEWx4ZzmGpi
        uint256 _deadline // Oct 18 00:00 UTC - 1666051200
    ) ERC721(_name, _symbol) {
        baseUri = _baseUri;
        deadline = _deadline;
        auditfund = _auditfund;
    }

    function _mintOne(address _to, uint256 _tier) internal {
        require(block.timestamp < deadline, "Deadline over");
        require(_tier > 0 && _tier < 4, "Tier out of range");
        uint256 tokenId = totalSupply + 1;
        tierOf[tokenId] = _tier;
        unchecked {
            ++totalSupply;
        }
        _mint(_to, tokenId);
    }

    // Public Mint
    function mint() external payable nonReentrant {
        uint256 tier;
        if (msg.value >= 10 ether) {
            tier = 3;
        } else if (msg.value >= 1 ether) {
            tier = 2;
        } else if (msg.value >= 0.1 ether) {
            tier = 1;
        } else {
            revert("Minimum price 0.1 ETH");
        }
        // MAKE SURE ITS A TX.ORIGIN PP
        (bool success, ) = auditfund.call{value: msg.value}("");
        require(success, "Payment to JB failed");
        _mintOne(msg.sender, tier);
    }

    function ownerMint(address _to, uint256 _tier)
        public
        onlyOwner
        nonReentrant
    {
        _mint(_to, _tier);
    }

    function ownerBatchMint(address[] memory _to, uint256[] memory _tiers)
        external
        onlyOwner
    {
        require(
            _to.length == _tiers.length,
            "Recipients and tiers must be same length"
        );
        for (uint256 i = 0; i < _to.length; i++) {
            ownerMint(_to[i], _tiers[i]);
        }
    }

    function setBaseUri(string memory _baseUri) external onlyOwner {
        baseUri = _baseUri;
    }

    function tokenURI(uint256 id) public view override returns (string memory) {
        return
            string(
                abi.encodePacked(baseUri, "/", Strings.toString(tierOf[id]))
            );
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721)
        returns (bool)
    {
        return ERC721.supportsInterface(interfaceId);
    }
}
