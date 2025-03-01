//SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// Token contract, inheriting from ERC20.
contract Token is ERC20 {

    uint public total_supply;
    
    // Constructor, minting the total supply to the deployer
    constructor(uint amount) ERC20("Circle", "USDC") {

        total_supply = amount * (10**18);

        _mint(msg.sender, total_supply);
    }
}