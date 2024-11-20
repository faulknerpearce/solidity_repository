const { ethers } = require("ethers");
const dotenv = require("dotenv");
const abi = require("../contract_abi/StravaConsumer.json");

// Load environment variables from .env file
dotenv.config();

function getContractInstance() {
    // Connect to the Sepolia network
    const provider = new ethers.providers.JsonRpcProvider(process.env.SEPOLIA_URL);

    // Create a wallet instance
    const wallet = new ethers.Wallet(process.env.PRIVATE_KEY, provider);

    // Address of the deployed contract
    const contractAddress = process.env.GOALFI_CONTRACT_ADDRESS;

    // ABI of the deployed contract
    const contractABI = abi.abi;

    // Create a contract instance
    const contract = new ethers.Contract(contractAddress, contractABI, wallet);

    return contract;
}

module.exports = { getContractInstance };