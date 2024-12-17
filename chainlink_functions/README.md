# Instructions

### how to add a Chainlink consumer.

1. Create a subscription at https://functions.chain.link/
2. Get the DON ID and the Router Address from the subscription page and paste them into the smart contract.
3. check the source file that is located at scripts/source.js, this is the file the Chainlink nodes will use to make the api query.
4. Deploy the smart contract (use: npx hardhat run scripts/deploy.js --network sepolia), make sure to deploy the contract with the Chainlink subscription id ( configure the subscription ID in the env file ). 
5. Add the consumer to your subscription by copying the smart contract address and pasting it into the add consumer section at https://functions.chain.link

# Strava

1. Create an API application on Strava. 
2. set the redirect URl to the localhost port that the vite application is using. ( if you are using a front end interface )