// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Upgoaled is Ownable { 

    // Hardcoded address of the token.
    address public constant TOKEN_ADDRESS = 0x2D54C76a3C48E6aFF35A40FFE85953c6Df6Ed3D4;

    // User struct to store user information.
    struct User {
        string name;
        address walletAddress; // Wallet address of the user.
        mapping(uint => Goal) goals; // List of goal IDs associated with the user.
        mapping(uint => GoalParticipation) goalParticipations;
    }
    // Goal struct to store goal information.
    struct Goal {
        uint goalPoolId;
        string activity;
        uint userData;
        uint stake;
        uint totalFailedStake;
        address[] participants;
        uint expiryTimestamp; 
        bool set; // used to check a mapping for our existence in it.
    }
    // GoalPool struct to store goal pool information.
    struct GoalPool {
        string name; // Name of the goal pool.
        uint[] goals; // List of goal IDs in the goal pool.
        uint activeGoals;
    }
    // GoalParticipation struct to store staked amounts, failed stakes, and claimed rewards.
    struct GoalParticipation {
        uint stakedAmount; // The totoal stake amount in the pool.
        uint userDistance; // Add this line to store the user's distance.
        UserProgress progress; // The states a user can be in.
    }
    enum UserProgress {
        JOINED, 
        FAILED, 
        COMPLETED,
        CLAIMED,
        ANY
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
    mapping(address => bool) uncompletedUsersId;
    
    // Events
    event UserCreated(string name, address indexed walletAddress);
    event GoalPoolCreated(uint indexed goalPoolId, string name);
    event GoalCreated(uint indexed goalId, string title, uint description, uint stake, uint goalPoolId, uint expiryTimestamp);
    event UserProgressUpdated(address indexed walletAddress, uint indexed goalId, UserProgress newStatus);
    event RewardsClaimed(address indexed walletAddress, uint indexed goalId);
    event UserJoinedGoal(address indexed walletAddress, uint indexed goalId, uint stake);
    
    // Modifier to check if the user has not been created yet.
    modifier userNotCreated(address _walletAddress) {
        require(!userAddressUsed[_walletAddress], "User can only create an account once");
        _;
    }
    // modifier to requre user has an account to join goal. 
    modifier userExists(address _walletAddress) {
        require(users[_walletAddress].walletAddress != address(0), "User must exist");
        _;
    }
    modifier goalExists (uint goalId) {
        require(goals[goalId].set, "goalExists: invalid goal id, goal does not exist");
        _;
    }

    // modifier to mark users who havent completed their goals as failed once the goal event expires. 
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
     
        goals[goalCount] = Goal(_goalPoolId, _activity, _distance, 0, 0, new address[](0), _expiryTimestamp, true);
        goalCount++;

        goalPools[_goalPoolId].goals.push(goalCount);
        goalPools[_goalPoolId].activeGoals++;

        emit GoalCreated(goalCount, _activity, _distance, 0, _goalPoolId, _expiryTimestamp);
    }
    // Function to create a new user with a name, wallet walletAddress, and USDC token address.
    function createUser(string memory _name) public userNotCreated(msg.sender) {
        // Check if the user's wallet has more than 5 tokens.
        IERC20 token = IERC20(TOKEN_ADDRESS);
        uint userTokenBalance = token.balanceOf(msg.sender);
        require(userTokenBalance >= 5, "User must have at least 5 USDC");

        users[msg.sender].name = _name;
        users[msg.sender].walletAddress = msg.sender;
   
        userCount++;

        userAddressUsed[msg.sender] = true;

        emit UserCreated(_name, msg.sender);
    }
    // Function to check if a user has joined a goal
    function userHasJoinedGoal(address walletAddress, uint goalId) public userExists(walletAddress) goalExists(goalId) view returns (bool) {        
        User storage user = users[walletAddress];
        return user.goals[goalId].set;
    }
    // Function to join a goal and pledge to the activity. 
    function joinGoalAndStake(uint _goalId, uint _stake) public userExists(msg.sender) goalExists(_goalId) {    
        require(goals[_goalId].expiryTimestamp > block.timestamp, "Cannot join an expired goal");
        User storage user = users[msg.sender];
    
        // Ensure the user has not already participated in the goal.
        require(!userHasJoinedGoal(msg.sender, _goalId), "User has already participated in the goal");

        // Ensure the user approves the contract to transfer tokens on their behalf.
        IERC20 token = IERC20(TOKEN_ADDRESS);
        require(token.allowance(msg.sender, address(this)) >= _stake, "Token allowance not sufficient");

        // Require that the user must stake tokens to join the goal.
        require(_stake > 0, "User must stake tokens to join the goal");

        // Transfer tokens from the user to the contract.
        token.transferFrom(msg.sender, address(this), _stake);

        uncompletedUsersId[msg.sender] = true;

        // Add the user's userId to the goal's participants array.
        goals[_goalId].participants.push(msg.sender);

        // Record user's participation in the goal.
        Goal storage goal = goals[_goalId];
        user.goals[_goalId] = goal;
        user.goalParticipations[_goalId].stakedAmount = _stake;
        user.goalParticipations[_goalId].userDistance = 0;
        user.goalParticipations[_goalId].progress = UserProgress.JOINED;               

        // Update the total stake for the goal in the goals mapping.
        goals[_goalId].stake += _stake;

        // Emit an event for joining the goal and staking.
        emit UserJoinedGoal(msg.sender, _goalId, _stake);
    }
    //Function to check goal expiry date and mark uncompleted users as failed. (Only Owner)
    function failGoal(uint _goalId) public onlyOwner goalExists(_goalId) {        
        require(block.timestamp >= goals[_goalId].expiryTimestamp, "Goal must be expired in order for users to have failed their goal");
        
        // to get the goalPoolId from the goal
        uint goalPoolId = goals[_goalId].goalPoolId;
        
        // Iterate through all the participants
        for (uint i = 0; i < goals[_goalId].participants.length; i++) {
            address id = goals[_goalId].participants[i];
            User storage u = users[id];

            // Check if the uncompletedUsersId is true
            if (uncompletedUsersId[u.walletAddress]) {
                // Check if the user's progress is not marked as Failed or Completed
                if (u.goalParticipations[_goalId].progress != UserProgress.FAILED && u.goalParticipations[_goalId].progress != UserProgress.COMPLETED) {                
                    u.goalParticipations[_goalId].progress = UserProgress.FAILED;
                    goals[_goalId].totalFailedStake += u.goalParticipations[_goalId].stakedAmount;
                    u.goalParticipations[_goalId].stakedAmount = 0;
                    // Optionally, emit an event to signal that the user's progress has been updated to Failed
                }
            }
        }
        goalPools[goalPoolId].activeGoals--;
    }   
    // Function to mark a user as having passed the goal. (Only Owner)
    function completeGoal(address _walletAddress, uint _goalId, uint _userData) public onlyOwner markFailedIfExpired(_goalId, _walletAddress) {
        User storage user = users[_walletAddress];

        require(user.walletAddress != address(0), "completeGoal: user must exist");

        require(_userData >= goals[_goalId].userData, "User distance must be greater than or equal to the goal distance");

        require(user.goalParticipations[_goalId].progress == UserProgress.JOINED, "User is required to have joined the goal");

        require(user.goalParticipations[_goalId].progress != UserProgress.FAILED, "User must not be marked as failed");

        // Mark the user as completed in its goalParticipations mapping.
        user.goalParticipations[_goalId].progress = UserProgress.COMPLETED;
        
        // Store the user's distance in the goalParticipations mapping.
        user.goalParticipations[_goalId].userDistance = _userData;       
    }
    // Function to calculate the user's share of the rewards
    function calculateUserRewards(address userAddress, uint goalId) internal view returns (uint) {
        uint userStakedAmount = users[userAddress].goalParticipations[goalId].stakedAmount;
        uint totalFailedStake = goals[goalId].totalFailedStake;
        uint numCompletedParticipants = countGoalParticipantsAtProgress(goalId, UserProgress.COMPLETED);
        uint claimFees = (userStakedAmount * FEE_PERCENTAGE) / 100;
        uint rewardsFromFailedStake = totalFailedStake / numCompletedParticipants;
        uint userRewards = (userStakedAmount + rewardsFromFailedStake) - claimFees;

        return userRewards;
    }
    // Function to allow a user to claim rewards after completing a goal
    function claimRewards(uint _goalId) public userExists(msg.sender) goalExists(_goalId) {        
        // Ensure the goal has expired. We all claim in equal parts only because nobody can join anymore after expiration.
        require(block.timestamp >= goals[_goalId].expiryTimestamp, "claimRewards: Goal must be expired");
    
        // Ensure the user has not already claimed their rewards.
        User storage user = users[msg.sender];

        // Ensure the user has completed the goal
        require(user.goalParticipations[_goalId].progress != UserProgress.CLAIMED, "User has already claimed rewards");
        require(user.goalParticipations[_goalId].progress == UserProgress.COMPLETED, "User must have completed the goal");

        // Ensure the user has staked tokens in the goal
        uint userStakedAmount = user.goalParticipations[_goalId].stakedAmount;
        require(userStakedAmount > 0, "User must have staked tokens in the goal");

        // Calculate the user's share of the rewards from the failed stakes.
        uint userRewards = calculateUserRewards(msg.sender, _goalId);

        // Transfer the rewards to the user.
        IERC20 token = IERC20(TOKEN_ADDRESS);
        token.transfer(msg.sender, userRewards);

        // Decrease the goal's stake by the user's stake.
        goals[_goalId].stake -= userRewards;
        user.goalParticipations[_goalId].progress = UserProgress.CLAIMED;

        emit RewardsClaimed(msg.sender, _goalId);
    }
    // Pays any users whom have not claimed their rewards and it pays the contract onwer the remaining stake and fees. (Only Owner)
    function payRemainingClaims(uint goalId) public onlyOwner goalExists(goalId) {
        // Ensure that the goal has expired before the function can be called. 
        require(block.timestamp >= goals[goalId].expiryTimestamp, "Goal must be expired in order to pay remaining claims");
        
        require(goals[goalId].stake > 0, "payRemainingClaims: There must be stake in the goal to claim");

        Goal storage goal = goals[goalId];

        for (uint i=0 ; i < goal.participants.length; i++) {
            address userAddress = goal.participants[i];
            if (users[userAddress].goalParticipations[goalId].progress == UserProgress.COMPLETED) {
                uint userRewards = calculateUserRewards(userAddress, goalId);
                IERC20 token = IERC20(TOKEN_ADDRESS);
                token.transfer(userAddress, userRewards);
                goal.stake -= userRewards;
                users[userAddress].goalParticipations[goalId].progress = UserProgress.CLAIMED;
            }
        }
        // Collect fees and any possible remainders.
        if (goal.stake > 0) {
            IERC20 token = IERC20(TOKEN_ADDRESS);
            token.transfer(msg.sender, goal.stake);
            goal.stake = 0;
        }
    }
    // Given the user progress enum the and the goal id it counts matching users on that state, if you pass ANY it counts all users.
    function countGoalParticipantsAtProgress(uint _goalId, UserProgress progress) public goalExists(_goalId) view returns (uint) {
        Goal storage goal = goals[_goalId];
        uint matches = 0;
        for (uint i=0 ; i < goal.participants.length; i++) {
            address userAddress = goal.participants[i];
            if (users[userAddress].goalParticipations[_goalId].progress == progress ||
                progress == UserProgress.ANY) {
                matches++; 
            }
        }
        return matches;
    }
}