require("@chainlink/env-enc").config();
const path = require('path');
const fs = require('fs');

async function main() {

  // Read the JavaScript source code from a file named 'source.js'.
  const source = fs.readFileSync(path.resolve(__dirname, 'source.js'), 'utf8');

  // Get the subscription ID for deploying on the Avalanche Fuji testnet from environment variables.
  const subscriptionId = process.env.FUJI_SUBSCRIPTION_ID; // For deploying on the avalanche fuji network.

  // Create a contract factory for the "StravaConsumer" contract.
  const StravaConsumerFactory = await ethers.getContractFactory("StravaConsumer");
  
  // Deploy the "Strava Consumer" contract with the subscription ID and source code.
  const StravaConsumerContract = await StravaConsumerFactory.deploy(subscriptionId, source);
  
  console.log('Deploying Contract.');

  // Wait for the contract deployment to complete.
  await StravaConsumerContract.waitForDeployment();

  console.log('Contract deployed successfully.');
  console.log("Contract address:", await StravaConsumerContract.getAddress());
}
  
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
  