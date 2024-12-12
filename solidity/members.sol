// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Contract {
    
    mapping(address => bool) public members;

    function addMember(address _address) external {
        
        require(members[_address] == false, 'Must not already be a member');
        
        members[_address] = true;
    } 

    function isMember(address _address) external view returns(bool){
        return members[_address];
    }

    function removeMember(address _address) external {
        members[_address] = false;
    }
}
