// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Contract {
    uint32 timesTicked;
    address payable public owner; 

    // Initialize the tick counter to zero and set the contract deployer as the owner at contract creation.
    constructor() {
        timesTicked = 0; 
        owner = payable(msg.sender); 
    }

    // Function to increment the tick counter and self-destruct the contract once it has ticked 10 times.
    function tick() external {
        if(timesTicked == 10){
            selfdestruct(owner);
        }
        timesTicked ++;
    }    
}
