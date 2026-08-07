// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// TO DO 
// 1. add random number generator for the power and defence of the monster.
// 2. store NFT as svg images.

// Simple NFT contract.
contract Pokemon {

    struct Monster {
        uint power;
        uint defence;
        bool isEveil;
    }

    uint ids = 0;
    
    mapping(uint => address) public owners;
    mapping(uint => Monster) public monsters;

    // Minting functionality, creating a new NFT.
    function mint(uint _power, uint _defence, bool _isEvil) external payable  {
        require(msg.value >= 0.1 ether, "Insufficient funds to mint NFT");

        monsters[ids] = Monster(_power, _defence, _isEvil);
        owners[ids] = msg.sender;
        ids ++;
    }
    
    // Transfering functionality.
    function transer(address reciever, uint id) external {
        require(owners[id] == msg.sender, "You are not the owner of this NFT");
        require(reciever != address(0), "Invalid reciever address");
        owners[id] = reciever;
    }

    // Getting the monster details.
    function getMonster(uint id) external view returns(Monster memory){
        return monsters[id];
    }
    
    // Breeding functionality, creating a new NFT by combining two NFTs.
    function breed(uint id1, uint id2) external {
        require(owners[id1] == msg.sender && owners[id2] == msg.sender, "You need to own both NFTs to breed them");
        
        owners[ids] = msg.sender;

        uint power = (monsters[id1].power + monsters[id2].power);
        uint defence = (monsters[id1].defence + monsters[id2].defence);
        bool isEvil = monsters[id1].isEveil || monsters[id2].isEveil;

        monsters[ids] = Monster(power, defence, isEvil);
        ids ++;
    }
}