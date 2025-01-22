// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

// A MultiSig wallet that requires multiple owners to approve transactions before execution.
contract MultiSig {
    
    address[] public owners;
    uint public transactionCount;
    uint public required;
    
    // Struct representing a transaction, including the recipient address, value, execution status, and optional data payload.
    struct Transaction {
        address destination;
        uint256 value;
        bool executed;
        bytes data;
    }

    mapping(uint => Transaction) public transactions;
    mapping(uint => mapping(address => bool)) public confirmations;
    
    constructor(address[] memory _owners, uint _required) {
        require(_owners.length > 0, "Must have at least one owner in order to deploy the contract.");
        require(_required <= _owners.length, "The required amount of signatures exceeded the total amount of owners.");
        require(_required > 0, "The required amount of signatures must be greater than zero.");
        

        required = _required;   
    }
    
    // Checks if a given address is an owner.
    function isOwner(address addr) internal view returns(bool) {
        for(uint i = 0; i < owners.length; i++){
            if(owners[i] == addr){
                return true;
            }
        }
        return false;
    }

    // Counts the number of confirmations for a transaction.
    function getConfirmationsCount(uint transactionId) internal view returns(uint256) {
        uint256 count = 0;

        for(uint i = 0; i < owners.length; i++){
            if(confirmations[transactionId][owners[i]] == true){
                count += 1;
            }
        } 

        return count;
    }

    // Checks if a transaction has enough confirmations to be executed.
    function isConfirmed(uint transactionID) public view returns(bool) {
       return getConfirmationsCount(transactionID) >= required;
    }

    // Creates and stores a new transaction.
    function addTransaction(address destination, uint value, bytes memory data) internal returns(uint) {
        uint transactionId = transactionCount;

        transactions[transactionId] = Transaction(destination, value, false, data);
        transactionCount ++;
        
        return transactionId;
    }

    // Confirms a transaction by the sender and executes it if the required approvals are met.
    function confirmTransaction(uint transactionId) public {
        require(isOwner(msg.sender), "Must be contract owner in order to confirm the transaction.");
        confirmations[transactionId][msg.sender] = true;

        if(isConfirmed(transactionId)){
            executeTransaction(transactionId);
        }
         
    }

    // Submits a new transaction and confirms it by the sender.
    function submitTransaction(address destination, uint value, bytes memory data) external {
        require(isOwner(msg.sender), 'Must be the contract owner in order to submit a transaction.');

        uint transactionId = addTransaction(destination, value, data);
        
        confirmTransaction(transactionId);
    }

    // Executes a confirmed transaction if it hasn't been executed already.
    function executeTransaction(uint transactionId) public {
        require(isConfirmed(transactionId), 'The transaction must have been confirmed by the required number of owners.');
        require(transactions[transactionId].executed != true, 'This transaction has already been executed.');

        Transaction storage transaction = transactions[transactionId];

        transaction.executed = true;

        (bool success, ) = transaction.destination.call{ value: transaction.value }(transaction.data);
        require(success); 
    }

    
    receive() external payable{ }

}