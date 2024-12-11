// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

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

	// Function to donate all contract balance to charity.
	function donate() public {
		(bool success, ) = charity.call{ value: address(this).balance }("");
		require(success);
	}

	// Function to send a tip to the contract owner.
	function tip() public payable {
		(bool success, ) = owner.call{ value: msg.value }("");
		require(success);
	}
}
