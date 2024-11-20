// SPDX-License-Identifier: MIT

// This contract exclusively handles sending and receiving ethereum.

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Goalify is Ownable(msg.sender) {

    // User struct to store user information.
    struct User {
        address walletAddress; // Wallet address of the user.
        mapping(uint => GoalParticipation) goalParticipations;
    }

    // Goal struct to store goal information.
    struct Goal {
        uint goalPoolId;
        string activity;
        uint distance;
        uint stake;
        uint totalFailedStake;
        mapping(address => GoalParticipation) participants;
        address[] participantAddresses;
        uint expiryTimestamp; 
        bool set;
    }

    // GoalPool struct to store goal pool information.
    struct GoalPool {
        string name; // Name of the goal pool.
        uint[] goals; // List of goal IDs in the goal pool.
        uint activeGoals;
    }

    // GoalParticipation struct to store staked amounts, failed stakes, and claimed rewards.
    struct GoalParticipation {
        uint stakedAmount; // The total stake amount in the pool.
        uint userDistance; // Add this line to store the user's distance.
        UserProgress progress; // The states a user can be in.
    }

    enum UserProgress {
        ANY,
        JOINED, 
        FAILED, 
        COMPLETED,
        CLAIMED   
    }

    // Counter for the total number of users, goals, and goal pool.
    uint public userCount; 
    uint public goalCount; 
    uint public goalPoolCount;

    // Contract Pool Fee.
    uint public constant FEE_PERCENTAGE = 2;

    // Maximum number of goal pools allowed.
    uint public constant MAX_GOAL_POOLS = 3;
    uint public constant MAX_GOALS_PER_POOL = 3;

    // Mappings to store user, goal, and goal pool data.
    mapping(address => User) public users;
    mapping(uint => Goal) public goals;
    mapping(uint => GoalPool) public goalPools;
    mapping(address => bool) public userAddressUsed;
    mapping(address => bool) public uncompletedUsersId;

    // Events
    event UserCreated(address indexed walletAddress);
    event GoalPoolCreated(uint indexed goalPoolId, string name);
    event GoalCreated(uint indexed goalId, string activity, uint distance, uint stake, uint goalPoolId, uint expiryTimestamp);
    event UserProgressUpdated(address indexed walletAddress, uint indexed goalId, UserProgress newStatus);
    event RewardsClaimed(address indexed walletAddress, uint indexed goalId);
    event UserJoinedGoal(address indexed walletAddress, uint indexed goalId, uint stake);

    // Modifier to check if the user has not been created yet.
    modifier userNotCreated(address _walletAddress) {
        require(!userAddressUsed[_walletAddress], "User can only create an account once");
        _;
    }

    // Modifier to require user has an account to join goal. 
    modifier userExists(address _walletAddress) {
        require(users[_walletAddress].walletAddress != address(0), "User must exist");
        _;
    }

    modifier goalExists (uint goalId) {
        require(goals[goalId].set, "goalExists: invalid goal id, goal does not exist");
        _;
    }

    // Modifier to mark users who haven't completed their goals as failed once the goal event expires. 
    modifier markFailedIfExpired(uint _goalId, address _walletAddress) {
        require(goals[_goalId].set, "markFailedIfExpired: invalid goal id, goal does not exist");
        if (goals[_goalId].expiryTimestamp < block.timestamp) {
            failGoal(_goalId);
        }
        _;
    }

    // Function to create a new goal pool with a name. (Only Owner) 
    function createGoalPool(string memory _name) public onlyOwner {
        require(goalPoolCount < MAX_GOAL_POOLS, "Maximum number of goal pools reached");

        goalPools[goalPoolCount] = GoalPool(_name, new uint[](0), 0);
        goalPoolCount++;

        emit GoalPoolCreated(goalPoolCount, _name);
    }

    // Function to create a new goal with a title, and goal pool ID. (Only Owner)
    function createGoal(string memory _activity, uint _distance, uint _goalPoolId, uint _expiryTimestamp) public onlyOwner {
        require(goalPools[_goalPoolId].activeGoals < MAX_GOALS_PER_POOL, "Maximum number of active goals per pool reached");

        Goal storage newGoal = goals[goalCount];
        newGoal.goalPoolId = _goalPoolId;
        newGoal.activity = _activity;
        newGoal.distance = _distance;
        newGoal.stake = 0;
        newGoal.totalFailedStake = 0;
        newGoal.participantAddresses =  new address[](0);
        newGoal.expiryTimestamp = _expiryTimestamp;
        newGoal.set = true;

        goalPools[_goalPoolId].goals.push(goalCount);
        goalPools[_goalPoolId].activeGoals++;

        emit GoalCreated(goalCount, _activity, _distance, 0, _goalPoolId, _expiryTimestamp);

        goalCount++;
    }

    // Function to create a new user with a wallet address.
    function createUser() public userNotCreated(msg.sender) {
        require(msg.sender.balance >= 1000000000000000, "User must have at least 0.001 ETH in their wallet");

        users[msg.sender].walletAddress = msg.sender;

        userCount++;

        userAddressUsed[msg.sender] = true;

        emit UserCreated(msg.sender);
    }

    // Function to join a goal and pledge to the activity.
    function joinGoal(uint _goalId) public payable userExists(msg.sender) goalExists(_goalId) {
        require(goals[_goalId].expiryTimestamp > block.timestamp, "Cannot join an expired goal");

        require(msg.value > 0, "You must stake to join the pool.");

        // Ensure the user has not already participated in the goal.
        require(goals[_goalId].participants[msg.sender].progress == UserProgress.ANY, "User has already participated in the goal");

        uncompletedUsersId[msg.sender] = true;

        // Record user's participation in the goal.
        goals[_goalId].participants[msg.sender] = GoalParticipation(msg.value, 0, UserProgress.JOINED);

        // Add the user's address to the goal's participants array.
        goals[_goalId].participantAddresses.push(msg.sender);

        // Update the total stake for the goal.
        goals[_goalId].stake += msg.value;

        // Emit an event for joining the goal and staking.
        emit UserJoinedGoal(msg.sender, _goalId, msg.value);
    }

    // Function to mark a user as having passed the goal. (Only Owner)
    function completeGoal(address _walletAddress, uint _goalId, uint _userData) public onlyOwner markFailedIfExpired(_goalId, _walletAddress) {
        User storage user = users[_walletAddress];
        Goal storage goal = goals[_goalId];

        require(user.walletAddress != address(0), "completeGoal: user must exist");
        require(_userData >= goal.distance, "User distance must be greater than or equal to the goal distance");
        require(goal.participants[_walletAddress].progress == UserProgress.JOINED, "User is required to have joined the goal");
        require(goal.participants[_walletAddress].progress != UserProgress.FAILED, "User must not be marked as failed");

        // Mark the user as completed in its goalParticipations mapping.
        goal.participants[_walletAddress].progress = UserProgress.COMPLETED;
        
        // Store the user's distance in the goalParticipations mapping.
        goal.participants[_walletAddress].userDistance = _userData;
    }

    // Function to check goal expiry date and mark uncompleted users as failed. (Only Owner)
    function failGoal(uint _goalId) public onlyOwner goalExists(_goalId) {        
        require(block.timestamp >= goals[_goalId].expiryTimestamp, "Goal must be expired in order for users to have failed their goal");

        Goal storage goal = goals[_goalId];

        // Iterate through all the participants
        for (uint i = 0; i < goal.participantAddresses.length; i++) {
            address userAddress = goal.participantAddresses[i];

            // Check if the uncompletedUsersId is true
            if (uncompletedUsersId[userAddress]) {
                // Check if the user's progress is not marked as Failed or Completed
                if (goal.participants[userAddress].progress != UserProgress.FAILED && goal.participants[userAddress].progress != UserProgress.COMPLETED) {                
                    goal.participants[userAddress].progress = UserProgress.FAILED;
                    goal.totalFailedStake += goal.participants[userAddress].stakedAmount;
                    goal.participants[userAddress].stakedAmount = 0;
                    // Optionally, emit an event to signal that the user's progress has been updated to Failed
                }
            }
        }
        goalPools[goal.goalPoolId].activeGoals--;
    }

    // Given the user progress enum and the goal id, it counts matching users on that state, if you pass ANY it counts all users.
    function countGoalParticipantsAtProgress(uint _goalId, UserProgress progress) public view goalExists(_goalId) returns (uint) {
        Goal storage goal = goals[_goalId];
        uint matches = 0;
        for (uint i = 0; i < goal.participantAddresses.length; i++) {
            address userAddress = goal.participantAddresses[i];
            if (goal.participants[userAddress].progress == progress ||
                progress == UserProgress.ANY) {
                matches++; 
            }
        }
        return matches;
    }

    // Function to calculate the user's share of the rewards
    function calculateUserRewards(address userAddress, uint goalId) internal view returns (uint) {
        Goal storage goal = goals[goalId];
        uint userStakedAmount = goal.participants[userAddress].stakedAmount;
        uint totalFailedStake = goal.totalFailedStake;
        uint numCompletedParticipants = countGoalParticipantsAtProgress(goalId, UserProgress.COMPLETED);
        uint claimFees = (userStakedAmount * FEE_PERCENTAGE) / 100;
        uint rewardsFromFailedStake = totalFailedStake / numCompletedParticipants;
        uint userRewards = (userStakedAmount + rewardsFromFailedStake) - claimFees;

        return userRewards;
    }

    // Function to allow a user to claim rewards after completing a goal
    function claimRewards(uint _goalId) public payable userExists(msg.sender) goalExists(_goalId) {
        
        // Ensure the goal has expired. We all claim in equal parts only because nobody can join anymore after expiration.
        require(block.timestamp >= goals[_goalId].expiryTimestamp, "claimRewards: Goal must be expired");

        // Ensure the user has not already claimed their rewards.
        Goal storage goal = goals[_goalId];

        // Ensure the user has completed the goal
        require(goal.participants[msg.sender].progress != UserProgress.CLAIMED, "User has already claimed rewards");
        require(goal.participants[msg.sender].progress == UserProgress.COMPLETED, "User must have completed the goal");

        // Ensure the user has staked Ether in the goal
        uint userStakedAmount = goal.participants[msg.sender].stakedAmount;
        require(userStakedAmount > 0, "User must have staked Ether in the goal");

        // Calculate the user's share of the rewards from the failed stakes.
        uint userRewards = calculateUserRewards(msg.sender, _goalId);

        // Transfer the rewards to the user.
        payable(msg.sender).transfer(userRewards);

        // Decrease the goal's stake by the user's rewards.
        goal.stake -= userRewards;
        goal.participants[msg.sender].progress = UserProgress.CLAIMED;

        emit RewardsClaimed(msg.sender, _goalId);
    }
}
