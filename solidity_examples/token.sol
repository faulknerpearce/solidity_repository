// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

// A simple ERC20-like token contract
contract Token {
    
    uint public totalSupply;
    string public name = "USDC";
    string public symbol = "USD";
    uint8 public decimals = 18;

    mapping(address => uint256) balances;

    event Transfer(address indexed sender, address indexed receiver, uint256 amount);

    // Constructor function to initialize the total supply and assign it to the deployer.
    constructor() {
        totalSupply = 1000 * (10 ** uint256(decimals));
        balances[msg.sender] = totalSupply;
    }

    // Checks the balance of a specific address.
    function balanceOf(address addr) external view returns(uint256) {
        return balances[addr];
    }

    // Transfers tokens from the caller to a specified address.
    function transfer(address receiver, uint amount) external returns(bool){
        require(balances[msg.sender] >= amount, 'insufficient amount.');
        balances[msg.sender] -= amount;
        balances[receiver] += amount;

        emit Transfer(msg.sender, receiver, amount);

        return true;
    }
}