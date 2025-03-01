require("@nomicfoundation/hardhat-toolbox");
require('dotenv').config();

module.exports = {
  solidity: {
    compilers: [
      {
        version: "0.8.20",
      },
    ],
  },
  networks: {
    fuji: {
      url: process.env.FUJI_RPC,
      accounts: [process.env.PRIVATE_KEY],
    },
  },
};