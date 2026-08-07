// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.4;

// A simple escrow smart contract where an arbiter approves fund transfers to a beneficiary.
contract Contract {

    address public depositor; 
    address public arbiter;
    address public beneficiary;

    bool public isApproved = false;
    
    // Constructor to initialize the arbiter and beneficiary and set the depositor.
    constructor(address _arbiter, address _beneficiary) payable {
        
        depositor = msg.sender;
        arbiter = _arbiter;
        beneficiary = _beneficiary;  
    }

    event Approved(uint _balance);

    // Function to approve the fund transfer, callable only by the arbiter.
    function approve() external {
        require(msg.sender == arbiter, "Must be the contract arbiter to in order to approve.");

        uint balance = address(this).balance;

        (bool success, ) = beneficiary.call{value: balance}("");
        require(success, "Failed to send Ether");

        isApproved = true;

        emit Approved(balance);
    }
}