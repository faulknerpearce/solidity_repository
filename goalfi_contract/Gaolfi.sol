// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {FunctionsClient} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/contracts/src/v0.8/functions/v1_0_0/libraries/FunctionsRequest.sol";

contract Goalfi is Ownable(msg.sender), ReentrancyGuard, FunctionsClient {
    using FunctionsRequest for FunctionsRequest.Request;

    // Struct representing an activity's type and data.
    struct ActivityStruct {
        uint goalId;
        string activityType;
        string activityData;
    }

    // Struct representing a user in the system.
    struct User {
        address walletAddress;
        uint id;
        mapping(uint => GoalParticipation) goalParticipations;
        uint totalRewards;
    }

    // Struct representing a goal within the system.
    struct Goal {
        uint goalId;
        string activity;
        string description;
        uint distance;
        uint stake;
        uint failedStake;
        mapping(address => GoalParticipation) participants;
        address[] participantAddresses;
        uint startTimestamp;
        uint expiryTimestamp;
        bool set;
    }

    // Struct representing a participant's details in a goal.
    struct GoalParticipation {
        uint stakedAmount;
        uint userDistance;
        UserProgress progress;
    }

    // Enum representing the possible states of a user's progress in a goal.
    enum UserProgress {
        ANY,
        JOINED,
        FAILED,
        COMPLETED,
        CLAIMED
    }

     // Struct representing the status of a data request.
    struct RequestStatus {
        bool fulfilled;
        bool exists;
        bytes response;
        bytes err;
    }

    // Hardcoded for Fuji
    address router = 0xA9d587a00A31A52Ed70D6026794a8FC5E2F5dCb0; // Fuji network 
    bytes32 donID = 0x66756e2d6176616c616e6368652d66756a692d31000000000000000000000000; // Fuji network
    uint32 gasLimit = 300000;

    bytes32 public lastRequestId;
    uint64 public subscriptionId;
    string public source;

    bytes32[] public requestIds;
    bytes public lastResponse;
    bytes public lastError;

    uint public userCount;
    uint public goalCount;
    uint public activeGoalCount;

    uint public constant FEE_PERCENTAGE = 2;

    mapping(uint => Goal) public goals;
    mapping(address => User) public users;
    mapping(uint => address) public userIds;
    mapping(address => bool) public userAddressUsed;
    mapping(uint => bytes32) public goalToRequestId;

    mapping(bytes32 => RequestStatus) public requests;
    mapping(bytes32 => ActivityStruct) public activities;

    event Response(bytes32 indexed requestId,string activityData,bytes response,bytes err);
    event APIRequestSent(bytes32 indexed requestId,string activityType);
    event UserCreated(address indexed walletAddress);
    event GoalCreated(uint indexed goalId, string activity, string description, uint distance, uint startTimestamp, uint expiryTimestamp);
    event UserJoinedGoal(address indexed walletAddress, uint indexed goalId, uint stake);
    event UserProgressUpdated(address indexed walletAddress, uint indexed goalId, UserProgress newStatus);
    event RewardsClaimed(address indexed walletAddress, uint indexed goalId);
    event GoalEvaluated(uint indexed goalId);

    // Modifier to ensure a user has not already been created.
    modifier userNotCreated(address _walletAddress) {
        require(!userAddressUsed[_walletAddress], "Can only create an account once");
        _;
    }

    // Modifier to ensure a user exists.
    modifier userExists(address _walletAddress) {
        require(users[_walletAddress].walletAddress != address(0), "User must exist");
        _;
    }

    // Modifier to ensure a goal exists
    modifier goalExists(uint goalId) {
        require(goals[goalId].set, "Invalid goal id, goal does not exist");
        _;
    }

    // Modifier to mark a goal as failed if it has expire
    modifier markFailedIfExpired(uint _goalId, address _walletAddress) {
        require(goals[_goalId].set, "Invalid goal id, goal does not exist");
        if (goals[_goalId].expiryTimestamp < block.timestamp) {
            closeGoal(_goalId);
        }
        _;
    }
    
    // Initializes the contract with the given subscription ID and source code.
    constructor(uint64 functionsSubscriptionId, string memory _source) FunctionsClient(router) {
        subscriptionId = functionsSubscriptionId;
        source = _source;
    }

    // Sets the JavaScript source for Chainlink Functions requests.
    function setSource(string memory _source) external onlyOwner {
        source = _source;
    }

    // Creates a new goal with specified parameters.
    function createGoal(string memory _activity, string memory _description, uint _distance, uint _startTimestamp, uint _expiryTimestamp) public onlyOwner {
        Goal storage newGoal = goals[goalCount];
        newGoal.goalId = goalCount;
        newGoal.activity = _activity;
        newGoal.description = _description;
        newGoal.distance = _distance;
        newGoal.startTimestamp = _startTimestamp;
        newGoal.expiryTimestamp = _expiryTimestamp;
        newGoal.set = true;
        activeGoalCount++;
        goalCount++;

        emit GoalCreated(goalCount, _activity, _description, _distance, _startTimestamp, _expiryTimestamp);
    }

    // Creates a new user account if not already created.
    function createUser() public userNotCreated(msg.sender) {
        require(msg.sender.balance >= 1000000000000000, "Must have at least 0.001 Avax");

        users[msg.sender].walletAddress = msg.sender;
        users[msg.sender].id = userCount;
        userIds[userCount] = msg.sender;
        userAddressUsed[msg.sender] = true;
        userCount++;

        emit UserCreated(msg.sender);
    }
    
    // Allows a user to join a goal with a specified stake.
    function joinGoal(uint _goalId) public payable userExists(msg.sender) goalExists(_goalId) {
        require(block.timestamp < goals[_goalId].startTimestamp, "Goal has started.");
        require(goals[_goalId].expiryTimestamp > block.timestamp, "Goal has expired.");
        require(msg.value > 0, "Must stake to join goal.");
        require(goals[_goalId].participants[msg.sender].progress == UserProgress.ANY, "Already participated in goal.");

        goals[_goalId].participants[msg.sender] = GoalParticipation(msg.value, 0, UserProgress.JOINED);
        goals[_goalId].participantAddresses.push(msg.sender);
        goals[_goalId].stake += msg.value;

        emit UserJoinedGoal(msg.sender, _goalId, msg.value);
    }

    // Checks if a user has completed a goal and updates their status.
    function evaluateUserProgress(address walletAddress, uint goalId) internal {
        Goal storage goal = goals[goalId];
        GoalParticipation storage participation = goal.participants[walletAddress];

        if (participation.progress == UserProgress.JOINED) {
            if (participation.userDistance >= goal.distance) {
                participation.progress = UserProgress.COMPLETED;
            } else {
                participation.progress = UserProgress.FAILED;
                goal.failedStake += participation.stakedAmount;
                participation.stakedAmount = 0;
            }
            
            emit UserProgressUpdated(walletAddress, goalId, participation.progress);
        }
    }

    // Evaluates and closes a goal, marking user progress as necessary.
    function closeGoal(uint _goalId) public onlyOwner goalExists(_goalId) {
        require(block.timestamp >= goals[_goalId].expiryTimestamp, "Goal must be expired");

        Goal storage goal = goals[_goalId];

        for (uint i = 0; i < goal.participantAddresses.length; i++) {
            address userAddress = goal.participantAddresses[i];
            evaluateUserProgress(userAddress, _goalId);
        }
        activeGoalCount--;
        emit GoalEvaluated(_goalId);
    }

    // Counts the number of participants in a goal with a specific progress status.
    function countGoalParticipantsAtProgress(uint _goalId, UserProgress progress) public view goalExists(_goalId) returns (uint) {
        Goal storage goal = goals[_goalId];
        uint matches = 0;
        for (uint i = 0; i < goal.participantAddresses.length; i++) {
            address userAddress = goal.participantAddresses[i];
            if (goal.participants[userAddress].progress == progress || progress == UserProgress.ANY) {
                matches++;
            }
        }
        return matches;
    }

    // Calculates the rewards for a user based on their participation in a goal.
    function calculateUserRewards(address userAddress, uint goalId) internal view returns (uint) {
        Goal storage goal = goals[goalId];
        uint userStakedAmount = goal.participants[userAddress].stakedAmount;
        uint failedStake = goal.failedStake;
        uint numCompletedParticipants = countGoalParticipantsAtProgress(goalId, UserProgress.COMPLETED);
        uint claimFees = (userStakedAmount * FEE_PERCENTAGE) / 100;
        uint rewardsFromFailedStake = failedStake / numCompletedParticipants;
        uint userRewards = (userStakedAmount + rewardsFromFailedStake) - claimFees;

        return userRewards;
    }

    // Allows a user to claim rewards for completing a goal.
    function claimRewards(uint _goalId) public userExists(msg.sender) goalExists(_goalId) {
        require(block.timestamp >= goals[_goalId].expiryTimestamp, "Goal must be expired");

        Goal storage goal = goals[_goalId];

        require(goal.participants[msg.sender].progress != UserProgress.CLAIMED, "Rewards already claimed.");
        require(goal.participants[msg.sender].progress == UserProgress.COMPLETED, "Goal incomplete.");

        uint userStakedAmount = goal.participants[msg.sender].stakedAmount;
        require(userStakedAmount > 0, "Did not stake.");

        uint userRewards = calculateUserRewards(msg.sender, _goalId);
        require(userRewards > 0, "No rewards to claim.");
        require(userRewards <= address(this).balance, "Insufficient contract balance.");

        goal.stake -= userRewards;
        goal.participants[msg.sender].progress = UserProgress.CLAIMED;
        users[msg.sender].totalRewards += userRewards;

        emit RewardsClaimed(msg.sender, _goalId);

        (bool success, ) = payable(msg.sender).call{value: userRewards}("");
        require(success, "Transfer failed.");
    }

    // Initiates a Chainlink request to fetch activity data for a specific goal.
    function executeRequest(string memory accessTokens, string memory activityType, uint goalId, string memory startTimestamp, string memory expiryTimestamp) external returns (bytes32 requestId) {
        require(goals[goalId].set, "Goal must exist");
        
        string[] memory args = new string[](4);
        args[0] = accessTokens;
        args[1] = activityType;
        args[2] = startTimestamp;
        args[3] = expiryTimestamp;

        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(source);
        if (args.length > 0) req.setArgs(args);

        lastRequestId = _sendRequest(
            req.encodeCBOR(),
            subscriptionId,
            gasLimit,
            donID
        );

        activities[lastRequestId] = ActivityStruct({
            goalId: goalId,
            activityType: activityType,
            activityData: ""
        });
        
        requests[lastRequestId] = RequestStatus({
            exists: true,
            fulfilled: false,
            response: "",
            err: ""
        });

        requestIds.push(lastRequestId);
        goalToRequestId[goalId] = lastRequestId;

        emit APIRequestSent(lastRequestId, activityType);

        return lastRequestId;
    }

    // Handles the fulfillment of a Chainlink request, saving the response to an activity struct.
    function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal override {
        require(requests[requestId].exists, "Request not found");

        lastError = err;
        lastResponse = response;

        if (response.length > 0) {
            ActivityStruct storage activity = activities[requestId];
            activity.activityData = string(response);
        }

        requests[requestId].fulfilled = true;
        requests[requestId].response = response;
        requests[requestId].err = err;

        emit Response(requestId, string(response), response, err);
    }

    // Assigns distances to participants of a specific goal based on provided data.
    function assignDistance(uint256[] memory _data, uint _goalId) public onlyOwner goalExists(_goalId) {
        for(uint i = 0; i < _data.length; i += 2) {
            address walletAddress = getUserAddress(_data[i]);
            goals[_goalId].participants[walletAddress].userDistance = _data[i + 1];
        }
    }

    // Retrieves the activity associated with a specific request Id.
    function getActivityWithRequestId(bytes32 requestId) public view returns (ActivityStruct memory){
        return activities[requestId];
    }

    // Retrieves the distance recorded for a user in a specific goal.
    function getUserDistance(address walletAddress, uint goalId) public view goalExists(goalId) userExists(walletAddress) returns (uint) {
        return goals[goalId].participants[walletAddress].userDistance;
    }

    // Retrieves the list of participant addresses in a specific goal.
    function getParticipantAddresses(uint _goalId) public view goalExists(_goalId) returns (address[] memory) {
        return goals[_goalId].participantAddresses;
    }

    // Retrieves the progress status of a user in a specific goal.
    function getParticipantProgress(uint _goalId, address _userAddress) public view goalExists(_goalId) returns (UserProgress) {
        return goals[_goalId].participants[_userAddress].progress;
    }

    // Retrieves the total rewards accumulated by a user.
    function getUserTotalRewards(address walletAddress) public view userExists(walletAddress) returns (uint) {
        return users[walletAddress].totalRewards;
    }

    // Retrieves the id that is associated with the user address.
    function getUserId(address walletAddress) public view userExists(walletAddress) returns (uint) {
        return users[walletAddress].id;
    }

   // Retrieves the address that is associated with the user ID.
    function getUserAddress(uint _id) public view returns (address) {
        return userIds[_id];
    }
}
