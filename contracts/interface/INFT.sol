// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.1) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.20;

/**
 * @dev Required interface of an ERC-1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[ERC].
 */
interface INFT {
    function mint(address account, uint256 id, uint256 amount, bytes memory data) external;

    function balanceOf(address account, uint256 id) external view returns (uint256);

    function setURI(string memory newuri) external;

    function setApprovalForAll(address operator, bool approved) external;

    function safeTransferFrom(address from, address to, uint256 id, uint256 value, bytes calldata data) external;
}