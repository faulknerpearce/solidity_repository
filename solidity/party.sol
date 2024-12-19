// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.4;

// This contract handles RSVP and deposit collection for a party, enabling the organizer to pay a bill and distribute remaining funds to members.
contract Party {
    uint256 public deposit;
    address[] public members;
    address public organizer;

    mapping(address => bool) hasJoinedParty;

    event joinedParty(address indexed addr);
    event paidBill(address indexed addr);
    
    // Initializes the contract with a deposit amount and sets the organizer.
    constructor(uint256 _deposit) {
        deposit = _deposit;
        organizer = msg.sender;
    }
    
    // Allows a user to RSVP by paying the exact deposit amount.
    function rsvp() external payable {
        require(msg.value == deposit, "Incorrect RSVP amount");

        require(!hasJoinedParty[msg.sender], 'Can only RSVP once.');

        hasJoinedParty[msg.sender] = true;
        members.push(msg.sender);

        emit joinedParty(msg.sender);
    }
    // Distributes remaining funds equally among all RSVPed members. Called internally after the organizer pays the bill.
    function distributeRemainingFunds() internal {
        uint256 totalBalance = address(this).balance;
        uint256 share = totalBalance / members.length;

        for(uint i = 0; i < members.length; i ++){
            (bool success, ) = members[i].call{value: share}("");
            require(success);
        }
    }

    // Allows the organizer to pay the venue and distribute leftover funds to members.
    function payBill(address venue, uint cost) external {
        require(msg.sender == organizer, "Only the organizer can pay the bill.");
        require(cost <= address(this).balance, "Insufficient funds to pay the bill.");

        (bool success, ) = venue.call{value: cost}("");
        require(success);

        distributeRemainingFunds();

        emit paidBill(venue);
    }
}