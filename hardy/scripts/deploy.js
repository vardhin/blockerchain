async function main() {
    // Get the contract factory
    const SimpleStorage = await ethers.getContractFactory("SimpleStorage");
  
    // Deploy the contract
    const simpleStorage = await SimpleStorage.deploy();
    await simpleStorage.waitForDeployment();
  
    // Get the contract address
    const address = await simpleStorage.getAddress();
    
    console.log("SimpleStorage deployed to:", address);
  }
  
  // Handle errors
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });