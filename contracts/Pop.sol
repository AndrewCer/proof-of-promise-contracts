// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./ERC5484.sol";
import "./ERC5192.sol";

import "hardhat/console.sol";

/**
 * @dev Proof of Promise (PoP) the non-transferable ERC721 token agreement protocol.
 */
contract Pop is ERC721URIStorage, ERC721Enumerable, ERC5484, ERC5192 {
    using ECDSA for bytes32;

    struct Promise {
        address creator;
        bool restricted;
        BurnAuth burnAuth;
        string tokenUri;
    }

    struct PromiseCreation {
        bytes32 promiseHash;
        address[] receivers;
        BurnAuth burnAuth;
        string tokenUri;
    }

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // Promise hash => Promise
    mapping(bytes32 => Promise) public promises;
    // Restricted Promises require receivers to be added before they may sign
    // Promise hash => address => Bool
    mapping(bytes32 => mapping(address => bool)) public receivers;
    // Fetch if an address has signed a particular Promise.
    // Promise hash => address => Bool
    mapping(bytes32 => mapping(address => bool)) public signers;

    constructor() ERC721("Proof of Promise", "PoP") {}

    modifier promiseExists(bytes32 promiseHash) {
        require(
            promises[promiseHash].creator == address(0x0),
            "Promise exists"
        );
        _;
    }

    modifier promiseDoesntExist(bytes32 promiseHash) {
        require(
            promises[promiseHash].creator != address(0x0),
            "Promise does not exists"
        );
        _;
    }

    function createPromise(PromiseCreation calldata promiseCreation)
        public
        promiseExists(promiseCreation.promiseHash)
    {
        bytes32 promiseHash = promiseCreation.promiseHash;

        promises[promiseHash].creator = msg.sender;
        promises[promiseHash].burnAuth = promiseCreation.burnAuth;
        promises[promiseHash].tokenUri = promiseCreation.tokenUri;

        if (promiseCreation.receivers.length > 0) {
            promises[promiseHash].restricted = true;
            for (uint256 i = 0; i < promiseCreation.receivers.length; ++i) {
                receivers[promiseHash][promiseCreation.receivers[i]] = true;
            }
        }
    }

    function signPromise(bytes32 promiseHash)
        public
        promiseDoesntExist(promiseHash)
    {
        if (promises[promiseHash].restricted) {
            require(
                receivers[promiseHash][msg.sender] == true,
                "Not on receivers list"
            );
        }

        signers[promiseHash][msg.sender] = true;

        _tokenIds.increment();
        uint256 tokenId = _tokenIds.current();
        _mint(msg.sender, tokenId);
        _setTokenURI(tokenId, promises[promiseHash].tokenUri);
        _lock(tokenId);

        emit Locked(tokenId);
        emit Issued(
            address(0x0),
            msg.sender,
            tokenId,
            promises[promiseHash].burnAuth
        );
    }

    // Overrides
    function locked(uint256 tokenId) public override(ERC5192) returns (bool) {
        require(ownerOf(tokenId) != address(0x0), "ERC5192: invalid address");

        return super.locked(tokenId);
    }

    // Soulbound functionality
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) {
        require(
            locked(tokenId),
            "This token is soulbound and cannot be transfered"
        );

        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override(ERC721, IERC721) {
        require(
            locked(tokenId),
            "This token is soulbound and cannot be transfered"
        );

        super.safeTransferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public override(ERC721, IERC721) {
        require(
            locked(tokenId),
            "This token is soulbound and cannot be transfered"
        );

        super.safeTransferFrom(from, to, tokenId, _data);
    }

    // Required overrides from import contracts
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
