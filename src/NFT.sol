// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {ERC721} from "solmate/tokens/ERC721.sol";
import "juice-contracts-v2/JBETHERC20ProjectPayer.sol";
import {ReentrancyGuard} from "solmate/utils/ReentrancyGuard.sol";
import {Strings} from "openzeppelin-contracts/utils/Strings.sol";

contract NFT is ERC721, ReentrancyGuard, JBETHERC20ProjectPayer {
    mapping(uint256 => uint256) public tierOf; // TODO rename tierOf
    uint256 private immutable projectId;
    string public baseUri;
    uint256 public totalSupply;
    uint256 private immutable deadline;

    constructor(
        string memory _name, // NFT Rewards Audit Fund
        string memory _symbol, // AUDIT
        uint256 _projectId, // 256
        address _beneficiary, // 0xb0a1b2f7f7a2093da2247ed16f0c06cf02ce164f (safe.auditfund.eth)
        string memory _baseUri, // IPFS directory containing metadata for 3 tiers for ex. QmREvFUJiX8TNhJrqkE7T9v5zo7avbKUtggLccoonf4RQ3
        uint256 _deadline // 1657972800 last time it'll be July 15 anywhere in the world
    )
        ERC721(_name, _symbol)
        JBETHERC20ProjectPayer(
            _projectId,
            payable(_beneficiary),
            false,
            "ipfs://TODOFIXME",
            "",
            false,
            IJBDirectory(0xCc8f7a89d89c2AB3559f484E0C656423E979ac9C),
            address(this)
        )
    {
        // TODO fix ipfs ^^
        projectId = _projectId;
        baseUri = _baseUri;
        deadline = _deadline;
    }

    function _mintOne(address _to, uint256 _tier) internal nonReentrant {
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
        require(msg.value >= 0.1 ether, "Minimum price 0.1 ETH");
        //pay jb
        uint256 tier;
        if (msg.value >= 10) {
            tier = 3;
        } else if (msg.value >= 1) {
            tier = 2;
        } else if (msg.value >= 0.1) {
            tier = 1;
        } else if (msg.value < 0.1) {
            revert("Minimum price 0.1 ETH");
        }
        _pay(
            projectId, //uint256 _projectId,`
            JBTokens.ETH, // address _token
            msg.value, //uint256 _amount,
            18, //uint256 _decimals,
            msg.sender, //address _beneficiary,
            0, //uint256 _minReturnedTokens,
            false, //bool _preferClaimedTokens,
            "ipfs://TODOFIXME", //string memory _metadata,
            "" //bytes calldata _metadata
        );

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
        return string(abi.encodePacked(baseUri, Strings.toString(tiers[id])));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, JBETHERC20ProjectPayer)
        returns (bool)
    {
        return
            JBETHERC20ProjectPayer.supportsInterface(interfaceId) ||
            ERC721.supportsInterface(interfaceId);
    }
}
