// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.4;

contract Contract {
    
    address[] public members;

    // Constructor adds the deployer as the first member.
    constructor(){
        members.push(msg.sender);
    } 

    // Checks if the given address is a member of the list.
    function isMember(address addr) public view returns(bool) {
        for(uint i = 0; i < members.length; i ++){
            if(members[i] == addr){
                return true;
            }
        }
        return false;  
    }

    // Adds a new address to the members list if the caller is already a member.
    function addMember(address newMember) external {
        require(isMember(msg.sender), "Must be a member in order to add a new member.");
        
        members.push(newMember);
    } 

    // Removes the last member from the list if the caller is a member.
    function removeLastMember() external {
        require(isMember(msg.sender), "Must be a member in order to remove a member.");

        members.pop();
    }
}