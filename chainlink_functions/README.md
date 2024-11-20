how to add a chainlink consumer.

# Packages to install.

1. npm install @chainlink/functions-toolkit
2. npm install --save-dev hardhat, then start hardhat: run npx hardhat init
3. npm install dotenv
4. npm install @chainlink/env-enc

# Instructions

1. Create a subscription at https://functions.chain.link/
2. Get the DON ID and the Router Address from the subscription page and paste them into the smart contract.
3. check the source file that is located at scripts/source.js, this is the file the chainlink nodes will use to make the api query.
4. Deploy the smart contract (use: npx hardhat run scripts/deploy.js --network sepolia), make sure to deploy the contract with the chainlink subscription id (set the sub ID in the env file). 
5. Add the consumer to your subscription by copying the smart contract address and pasting it into the add consumer section at https://functions.chain.link

6. Next we encrypt our environment variables. Set the encryption password by running: npx env-enc set-pw 
7. Set the encrypted values to your secrets one by one using the following command: npx env-enc set

8. Make sure to have ethers v6 installed.