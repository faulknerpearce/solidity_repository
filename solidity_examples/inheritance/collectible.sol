import "./baseContracts.sol";

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

// Contract representing a collectible item with pricing, ownership, and transfer features.
contract Collectible is Ownable, Transferable {
	uint public price;

    // Function to set the price of the collectible, restricted to the owner.
	function markPrice(uint _price) external onlyOwner {
		price = _price;
	}
}