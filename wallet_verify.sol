// SPDX-License-Identifier: MIT
// The wallet verification contract
pragma solidity ^0.8.0;

// The token contract
contract Token {
    string public name;

    // The total supply of tokens
    uint256 private totalSupply;

    // A mapping that stores the balance of each address
    mapping(address => uint256) private balances;

    // The constructor function, which sets the name of the token and the total supply
    constructor(string memory _name, uint256 _totalSupply) {
        name = _name;
        totalSupply = _totalSupply;
        balances[msg.sender] = _totalSupply;
    }

    // Transfer tokens to another address
    function transfer(address recipient, uint256 amount) public virtual returns (bool) {
        // Check that the sender has sufficient balance to make the transfer
        require(balances[msg.sender] >= amount, "Insufficient balance");

        // Transfer the tokens from the sender to the recipient
        balances[msg.sender] -= amount;
        balances[recipient] += amount;

        // Emit a transfer event
        emit Transfer(msg.sender, recipient, amount);

        return true;
    }

    // An event that is emitted when tokens are transferred
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract WalletVerification {
    // A mapping that stores the verification status of each address
    mapping(address => bool) private verified;

    // The token instance
    Token private token;

    // The constructor function, which creates a new instance of the token contract
    constructor() {
        token = new Token("Voter Token", 1000);
    }

    // Verify an address and transfer tokens to the verified address
    function verify(address recipient) public returns (bool) {
        // Check that the address has not already been verified
        require(!verified[recipient], "Address already verified");

        // Mark the address as verified
        verified[recipient] = true;

        // Transfer tokens to the verified address
        token.transfer(recipient, 1);

        return true;
    }
}
