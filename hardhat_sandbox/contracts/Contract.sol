// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Test {
    
    uint public balance; 
    
    // Constructor to initialize the balance
    constructor(uint amount) {
        balance = amount;  
    }

    // Function to view the current balance
    function viewBalance() external view returns (uint) {
        return balance;  
    }
}

