// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Contract {

    struct User {
        uint balance;
        bool isActive;
    }

    mapping(address => User) public users;

    function createUser() external {
		require(users[msg.sender].isActive != true, "Account has already been created.");
        
        users[msg.sender].balance = 100;
		users[msg.sender].isActive = true;
    }

    function transfer(address _address, uint amount) external {
        require(users[msg.sender].isActive == true && users[_address].isActive == true, 'Both parties need to be active users.');
        require(users[msg.sender].balance >= amount, "Transfer amount exceeds balance.");

        users[msg.sender].balance -= amount;
        users[_address].balance += amount;
    }
}

