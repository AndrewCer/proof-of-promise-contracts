// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.19;

// @dev: see https://eips.ethereum.org/EIPS/eip-5484
contract ERC5484 {
    // tokenId => BurnAuth
    mapping(uint256 => BurnAuth) private _burnAuth;

    /// A guideline to standardlize burn-authorization's number coding
    enum BurnAuth {
        IssuerOnly,
        OwnerOnly,
        Both,
        Neither
    }

    /// @notice Emitted when a soulbound token is issued.
    /// @dev This emit is an add-on to nft's transfer emit in order to distinguish sbt
    /// from vanilla nft while providing backward compatibility.
    /// @param from The issuer
    /// @param to The receiver
    /// @param tokenId The id of the issued token
    event Issued(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId,
        BurnAuth burnAuth
    );

    /// @notice provides burn authorization of the token id.
    /// @dev unassigned tokenIds are invalid, and queries do throw
    /// @param tokenId The identifier for a token.
    function burnAuth(uint256 tokenId) public view returns (BurnAuth) {
        return _burnAuth[tokenId];
    }

    function setBurnAuth(uint256 tokenId, BurnAuth auth) public {
        _burnAuth[tokenId] = auth;
    }
}
