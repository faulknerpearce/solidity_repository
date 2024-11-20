const { getContractInstance } = require("./getContractInstance");

// Function to get the last recorded activity data from the smart contract
async function getLastActivityData() {

  // Get an instance of the smart contract.
  const contract = getContractInstance();

  console.log("Requesting last activity data.");

  // Fetch the last activity data from the contract.
  const activity = await contract.getLastActivity();

  // Extract the activity data from the response.
  const activityData = activity.activityData;

  console.log(`Last activity data: ${activityData}`);

}

getLastActivityData().catch(console.error);
