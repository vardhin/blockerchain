const hre = require("hardhat");

async function main() {
  console.log("Starting deployment to Ganache...");
  
  // Check if Ganache is running
  try {
    const network = await hre.ethers.provider.getNetwork();
    console.log(`Connected to network: ${network.name} (chainId: ${network.chainId})`);
    
    if (network.chainId !== 1337n) {
      console.error("Not connected to Ganache! Expected chainId 1337, got", network.chainId);
      console.error("Please make sure Ganache is running and you're connected to the correct network");
      process.exit(1);
    }
  } catch (error) {
    console.error("Failed to connect to Ganache:", error.message);
    console.error("Please make sure Ganache is running at http://127.0.0.1:7545");
    process.exit(1);
  }
  
  // Get the deployer account
  const [deployer] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);
  
  // Get and log the account balance
  const balance = await hre.ethers.provider.getBalance(deployer.address);
  console.log("Account balance:", hre.ethers.formatEther(balance), "ETH");
  
  if (balance === 0n) {
    console.error("Deployer account has no ETH. Please fund the account in Ganache before deploying.");
    process.exit(1);
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
    console.error("Contract deployment failed - no code at the deployed address");
    process.exit(1);
  }
  console.log("Contract code verified at address");
  
  // Log deployment summary
  console.log("\nDeployment Summary:");
  console.log("-------------------");
  console.log(`Network: Ganache (chainId: 1337)`);
  console.log(`Deployer: ${deployer.address}`);
  console.log(`Contract: ${contractAddress}`);
  console.log("\nIMPORTANT: Update the CONTRACT_ADDRESS in your frontend code with this address");
  
  // Create a file with the contract address for easy reference
  const fs = require("fs");
  const path = require("path");
  
  const contractInfo = {
    address: contractAddress,
    network: "Ganache",
    chainId: 1337,
    deployer: deployer.address,
    timestamp: new Date().toISOString()
  };
  
  fs.writeFileSync(
    path.join(__dirname, "../deployed-contract.json"),
    JSON.stringify(contractInfo, null, 2)
  );
  
  console.log("\nContract information saved to deployed-contract.json");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("Deployment failed:", error);
    process.exit(1);
  }); 