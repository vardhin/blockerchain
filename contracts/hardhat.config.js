/** @type import('hardhat/config').HardhatUserConfig */
require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

const SEPOLIA_RPC_URL = process.env.SEPOLIA_RPC_URL || "";
const PRIVATE_KEY = process.env.PRIVATE_KEY || "";
const ETHERSCAN_API_KEY = process.env.ETHERSCAN_API_KEY || "";

module.exports = {
  solidity: "0.8.28",
  networks: {
    hardhat: {
      // Local network with no external connections
    },
    localhost: {
      url: "http://localhost:8545"
    },
    ganache: {
      url: "http://127.0.0.1:7545", // Default Ganache UI port
      accounts: [PRIVATE_KEY],
      chainId: 1337 // Default Ganache chainId
    }
  }
};