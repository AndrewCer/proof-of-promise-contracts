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
        address[] receivers; // Addresses that have yet to sign.
        address[] signers; // Addresses that have signed. May only be added to by contract
        BurnAuth _burnAuth;
        string _tokenUri;
    }

    struct PromiseCreation {
        bytes32 promiseHash;
        address[] receivers; // Addresses that have yet to sign.
        BurnAuth _burnAuth;
        string _tokenUri;
    }

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // TokenUri hash => Promise
    mapping(bytes32 => Promise) public promises;

    constructor() ERC721("Proof of Promise", "PoP") {}

    modifier promiseExists(bytes32 promiseHash) {
        require(
            promises[promiseHash].creator == address(0x0),
            "Promise exists"
        );
        _;
    }

    function createPromise(PromiseCreation calldata promiseCreation)
        public
        promiseExists(promiseCreation.promiseHash)
    {
        bytes32 promiseHash = promiseCreation.promiseHash;

        promises[promiseHash].creator = msg.sender;
        promises[promiseHash].receivers = promiseCreation.receivers;
        promises[promiseHash]._burnAuth = promiseCreation._burnAuth;
        promises[promiseHash]._tokenUri = promiseCreation._tokenUri;
    }

    // Overrides

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
