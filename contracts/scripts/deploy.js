const hre = require("hardhat");

async function main() {
  console.log("Starting deployment process...");
  
  // Get the network information
  const network = await hre.ethers.provider.getNetwork();
  console.log(`Deploying to network: ${network.name} (chainId: ${network.chainId})`);
  
  // Get the deployer account
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);
  
  // Get and log the account balance
  const balance = await hre.ethers.provider.getBalance(deployer.address);
  console.log("Account balance:", hre.ethers.formatEther(balance), "ETH");
  
  if (balance === 0n) {
    throw new Error("Deployer account has no ETH. Please fund the account before deploying.");
  }
  
  // Deploy the contract
  console.log("Deploying BlockerChain contract...");
  const BlockerChain = await hre.ethers.getContractFactory("BlockerChain");
  const blockerChain = await BlockerChain.deploy();
  
  // Wait for deployment to complete
  console.log("Waiting for deployment to complete...");
  await blockerChain.waitForDeployment();
  
  // Get the deployed contract address
  const contractAddress = await blockerChain.getAddress();
  console.log("BlockerChain deployed to:", contractAddress);
  
  // Verify the contract exists at the address
  const code = await hre.ethers.provider.getCode(contractAddress);
  if (code === "0x") {
    throw new Error("Contract deployment failed - no code at the deployed address");
  }
  console.log("Contract code verified at address");
  
  // Log deployment summary
  console.log("\nDeployment Summary:");
  console.log("-------------------");
  console.log(`Network: ${network.name} (chainId: ${network.chainId})`);
  console.log(`Deployer: ${deployer.address}`);
  console.log(`Contract: ${contractAddress}`);
  console.log("\nIMPORTANT: Update the CONTRACT_ADDRESS in your frontend code with this address");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Deployment failed:", error);
    process.exit(1);
  });