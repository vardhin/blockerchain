require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

module.exports = {
  solidity: "0.8.28",
  networks: {
    // Local network
    hardhat: {
      chainId: 31337
    },
  }
};