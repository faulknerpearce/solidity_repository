const { getContractInstance } = require("./getContractInstance");
const dotenv = require("dotenv");
dotenv.config();

// Function to request activity data using chainlink functions with the smart contract.
async function requestActivityData(accessTokens, activityType, startTimestamp, expiryTimestamp) {
  
  // Get an instance of the smart contract.
  const contract = getContractInstance();

  console.log(`Requesting activity data for sport type: ${activityType}` );

  // Send the activity data request to the smart contract.
  const tx = await contract.executeRequest(accessTokens, activityType, startTimestamp, expiryTimestamp);

  console.log(`Activity data request sent for ${activityType}, transaction hash: ${tx.hash}`);
}

// Hardcoded data for testing. Takes a user id and the access token.
const userAccessTokens = `{"1": "${process.env.ACCESS_TOKEN_ONE}", "2": "${process.env.ACCESS_TOKEN_TWO}"}`;
const activity = 'Run';
const start_Timestamp = '1729004722';
const expiry_Timestamp = '1729004722';

requestActivityData(userAccessTokens, activity, start_Timestamp, expiry_Timestamp).catch(console.error);
