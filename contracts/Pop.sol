// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./ERC5484.sol";

import "hardhat/console.sol";

/**
 * @dev Proof of Promise (PoP) the non-transferable ERC721 token agreement protocol.
 */
abstract contract Pop is ERC721URIStorage, ERC721Enumerable, ERC5484 {
    using ECDSA for bytes32;

    struct Promise {
        BurnAuth _burnAuth;
        string _tokenURI;
        address creator;
        address[] signers;
    }

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // Promise hash => Promise
    mapping(bytes32 => Promise) public promises;

    constructor() ERC721("Proof of Promise", "PoP") {}

    modifier promiseExists(bytes32 promiseHash) {
        // require(promises[promiseHash] == Promise, "Promise exists");
        _;
    }

    function createPromise(Promise calldata pop) public promiseExists(hash(pop)) {
        bytes32 promiseHash = hash(pop);
        promises[promiseHash]._burnAuth = pop._burnAuth;
        promises[promiseHash]._tokenURI = pop._tokenURI;
        promises[promiseHash].creator = pop.creator;
        promises[promiseHash].signers = pop.signers;
    }

    function hash(Promise calldata pop) public pure returns (bytes32) {
        return
            keccak256(
                abi.encode(pop._burnAuth, pop._tokenURI, pop.creator, pop.signers)
            );
    }
}
