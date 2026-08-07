// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

// Base contract to manage ownership of the contract.
contract Ownable {

    // State variable to store the address of the current owner.
    address public owner;

    // Constructor sets the deployer of the contract as the initial owner.
    constructor() {
        owner = msg.sender;
    }

    // Modifier to restrict function access to the owner only.
    modifier onlyOwner {
        require(msg.sender == owner, "Must be the contract owner.");
        _; 
    }
}

// Contract inheriting from Ownable to add transfer ownership functionality.
contract Transferable is Ownable {

    // Allows the current owner to transfer ownership to a new address.
    function transfer(address newOwner) external onlyOwner{
        owner = newOwner;
    } 
}