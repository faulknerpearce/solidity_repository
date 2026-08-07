// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// A contract that requires a minimum deposit upon deployment and allows the owner to withdraw all funds.
contract Contract {

    address public owner;
    
    // Constructor function, payable to accept Ether upon deployment.
    constructor() payable {
        owner = msg.sender;
        
        require(msg.value >= 1 ether, 'Must send at least 1 ETH .'); 
    }

    // Function to send all Ether in the contract to the owner.
    function withdraw() public payable {
        require(msg.sender == owner, 'Must be the contract owner to withdraw.');
        
        (bool success, ) = owner.call{ value: address(this).balance }("");
        require(success);
    }
}
