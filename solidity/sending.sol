// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// A contract that supports receiving Ether, donating its balance to charity, and tipping the owner.
contract Contract {
	address public owner;
	address public charity;

	// Constructor to initialize the contract with charity address.
	constructor(address _charity) {
		owner = msg.sender;
		charity = _charity;
	}

	// Fallback function to receive Ether.
	receive() external payable { }

	// Donates all contract balance to charity.
	function donate() public {
		(bool success, ) = charity.call{ value: address(this).balance }("");
		require(success);
	}

	// Sends a tip to the contract owner.
	function tip() public payable {
		(bool success, ) = owner.call{ value: msg.value }("");
		require(success);
	}
}
