// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

// A time-locked inheritance contract that allows a recipient to withdraw funds after a specified period of inactivity.
contract Contract {
    address public owner;
    address public recipient;
    uint public lastTimestamp;

    event withdrawn(address _recipient);
    
    // Constructor initializes the contract with a recipient and stores the deployment timestamp.
    constructor(address _recipient) payable{
        owner = msg.sender;
        recipient = _recipient;
        lastTimestamp = block.timestamp;
    }

    // Allows the owner to update the last interaction timestamp, resetting inactivity timer.
    function ping() external {
        require(msg.sender == owner, "Must be the contract owner in order to ping.");
        lastTimestamp = block.timestamp;
    }

    // Allows the recipient to withdraw funds after 52 weeks of inactivity.
    function withdraw() external {
        require(msg.sender == recipient, "Must be the contracts beneficiary.");
        require((block.timestamp - lastTimestamp) >= 52 weeks, "Required period of inactivity has not been reached." );

        (bool success, ) = recipient.call{value: address(this).balance}("");
        require(success, "Transaction failed.");

        emit withdrawn(msg.sender);
    }
}