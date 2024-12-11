# Hardhat Sandbox

This Hardhat Sandbox is a development environment intended for deploying smart contracts, running unit tests, and experimenting with various Ethereum-related functionalities. 
It provides an easy-to-use setup for blockchain development and testing.

## Features
- **Smart Contract Deployment:** deploy contracts to local or test networks.
- **Unit Testing:** Write and run comprehensive tests for smart contracts using `chai` and `ethers.js`.
- **Script Execution:** Run custom scripts for deployment, interaction, or testing purposes.
- **Hardhat Network Support:** Utilize a local blockchain for fast and safe testing.

setup: 
1. touch .env and add: SEPOLIA_RPC, FUJI_RPC, PRIVATE_KEY.
1. run npm install
2. run npx hardhat test

contracts: 
- The Balance contract is a simple example for storing and viewing a balance.
- The Faucet contract allows users to withdraw small amounts of Ether and includes administrative functions for the contract owner.

usage: 
- run npx hardhat scrips/deploy_balance --network fuji to deploy the contract on the avalanche fuji network.
- run npx hardhat test to run unit tests for the faucet contracts.
