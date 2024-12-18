// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Contract {
    
    // Tracks membership status of addresses.
    mapping(address => bool) public members;

    // Adds an address as a member if it is not already a member.
    function addMember(address _address) external {
        
        require(members[_address] == false, 'Must not already be a member');
        
        members[_address] = true;
    } 

    // Checks if a given address is a member.
    function isMember(address _address) external view returns(bool){
        return members[_address];
    }

    // Removes an address from membership by setting its status to false.
    function removeMember(address _address) external {
        members[_address] = false;
    }
}
