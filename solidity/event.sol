// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.4;

// A smart contract for ownership transfer, pricing, and purchasing functionality with event logging.
contract Contract {
    
    address public owner;
    uint public price;

    event Deployed(address indexed _owner);
    
    // Sets the contract deployer as the initial owner.
    constructor(){
        owner = msg.sender;

        emit Deployed(msg.sender);
    }

    event Transfer(address indexed _owner, address indexed _recipient);
    
    // Transfer ownership of the contract to a new recipient.
    function transfer(address _recipient) external {
        require(msg.sender == owner, "Must be the owner in oder to transfer.");
        
        owner = _recipient;

        emit Transfer(msg.sender, _recipient);
    }

    event ForSale(uint _price, uint _timeStamp);

    // Set the price of the contract. only executable by the contract owner.
    function markPrice(uint _price) external {
        require(msg.sender == owner, "Must be the owner in oder to set the price");
        
        price = _price;
        
        emit ForSale(price, block.timestamp);
    }

    event Purchase(uint _amount, address indexed _address);

    // Function to purchase the contract. Only if a price for the contract has been set.
    function purchase() external payable {
        require(msg.value == price, 'Insufficient amount.');
        require(price > 0, "Price has not been set by the owner.");

        (bool success, ) = owner.call{value: msg.value}("");
        require(success);

        owner = msg.sender;
        price = 0;

        emit Purchase(msg.value, msg.sender);

    }
}