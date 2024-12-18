// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

contract Contract {
	enum Choices { Yes, No }
	
	struct Vote {
		Choices choice;
		address voter;
	}

	Vote none = Vote(Choices(0), address(0));

	Vote[] public votes; 

    // Creates a new vote if the sender hasn't already voted.
	function createVote(Choices choice) external {
        require(!hasVoted(msg.sender));
		votes.push(Vote(choice, msg.sender));
	}

    // Changes an existing vote for the sender.
    function changeVote(Choices choice) external {
		Vote storage vote = findVote(msg.sender);
		require(vote.voter != none.voter);
		vote.choice = choice;
	}

    // Internal function to find a vote by the voter's address.
	function findVote(address voter) internal view returns(Vote storage) {
		for(uint i = 0; i < votes.length; i++) {
			if(votes[i].voter == voter) {
				return votes[i];
			}
		}
		return none;
	}

    // Public function to check if an address has already voted.
	function hasVoted(address voter) public view returns(bool) {
		return findVote(voter).voter == voter;
	}

    // External function to get the voting choice of a specific address.
	function findChoice(address voter) external view returns(Choices) {
		return findVote(voter).choice;
	}
}

