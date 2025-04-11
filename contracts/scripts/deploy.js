async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);
    console.log("Account balance:", (await ethers.provider.getBalance(deployer.address)).toString());
  
    const BlockerChain = await ethers.getContractFactory("BlockerChain");
    const blockerChain = await BlockerChain.deploy();
    
    await blockerChain.waitForDeployment();
    console.log("BlockerChain deployed to:", await blockerChain.getAddress());
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });