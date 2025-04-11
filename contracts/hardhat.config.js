/** @type import('hardhat/config').HardhatUserConfig */
require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

const SEPOLIA_RPC_URL = process.env.SEPOLIA_RPC_URL || "";
const GANACHE_RPC_URL = process.env.GANACHE_RPC_URL || "http://127.0.0.1:7545";
const PRIVATE_KEY = process.env.PRIVATE_KEY || "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"; // Default to first Ganache account
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
      url: GANACHE_RPC_URL,
      accounts: [PRIVATE_KEY],
      chainId: 1337 // Default Ganache chainId
    },
    sepolia: {
      url: SEPOLIA_RPC_URL,
      accounts: [PRIVATE_KEY],
      chainId: 11155111
    }
  },
  etherscan: {
    apiKey: ETHERSCAN_API_KEY
  }
};