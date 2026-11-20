// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @notice Minimal ERC-721 stand-in for the Agent ID registry, used only in
///         tests. Supports mint + balanceOf (+ ownerOf for completeness).
contract MockAgentID {
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _owners;
    uint256 private _nextTokenId = 1;

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    function mint(address to) external returns (uint256 tokenId) {
        require(to != address(0), "MockAgentID: mint to zero address");
        tokenId = _nextTokenId++;
        _owners[tokenId] = to;
        _balances[to] += 1;
        emit Transfer(address(0), to, tokenId);
    }

    function balanceOf(address owner) external view returns (uint256) {
        require(owner != address(0), "MockAgentID: balance query for zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "MockAgentID: nonexistent token");
        return owner;
    }
}
