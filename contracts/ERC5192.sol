// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.19;

// @dev: see https://eips.ethereum.org/EIPS/eip-5192
contract ERC5192 {
    // tokenId => boolean
    mapping(uint256 => bool) private _locked;

    /// @notice Emitted when the locking status is changed to locked.
    /// @dev If a token is minted and the status is locked, this event should be emitted.
    /// @param tokenId The identifier for a token.
    event Locked(uint256 tokenId);

    /// @notice Emitted when the locking status is changed to unlocked.
    /// @dev If a token is minted and the status is unlocked, this event should be emitted.
    /// @param tokenId The identifier for a token.
    event Unlocked(uint256 tokenId);

    /// @notice Returns the locking status of an Soulbound Token
    /// @dev SBTs assigned to zero address are considered invalid, and queries
    /// about them do throw.
    /// @param tokenId The identifier for an SBT.
    function locked(uint256 tokenId) public virtual returns (bool) {
        return _locked[tokenId];
    }


    function _lock(uint256 tokenId) internal virtual {
        _locked[tokenId] = true;
    }
}
