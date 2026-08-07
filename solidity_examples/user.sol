// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

// A simple user management and transfer contract allowing users to create accounts and transfer tokens.
contract Contract {

    // Defines a structure to store user details.
    struct User {
        uint balance;
        bool isActive;
    }

    mapping(address => User) public users;

    // Creates a new user account with a default balance of 100 tokens.
    function createUser() external {
		require(users[msg.sender].isActive != true, "Account has already been created.");
        
        users[msg.sender].balance = 100;
		users[msg.sender].isActive = true;
    }

    // Transfers tokens from the sender to another active user.
    function transfer(address _address, uint amount) external {
        require(users[msg.sender].isActive == true && users[_address].isActive == true, 'Both parties need to be active users.');
        require(users[msg.sender].balance >= amount, "Transfer amount exceeds balance.");

        users[msg.sender].balance -= amount;
        users[_address].balance += amount;
    }
}
