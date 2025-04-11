# BlockerChain Contract Deployment

This directory contains the smart contract for the BlockerChain application.

## Prerequisites

- Node.js and npm installed
- Ganache running locally (http://127.0.0.1:7545)
- MetaMask installed in your browser

## Setup

1. Install dependencies:
```bash
npm install
```

2. Create a `.env` file in the root directory with the following content:
```
# Network RPC URLs
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/your-infura-key
GANACHE_RPC_URL=http://127.0.0.1:7545

# Private key for deployment (replace with your actual private key)
# WARNING: Never commit your actual private key to version control
PRIVATE_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# API Keys
ETHERSCAN_API_KEY=your-etherscan-api-key
```

## Deployment

### Deploy to Ganache

1. Make sure Ganache is running at http://127.0.0.1:7545
2. Run the deployment script:
```bash
npx hardhat run scripts/deploy-ganache.js --network ganache
```

3. The script will:
   - Check if Ganache is running
   - Deploy the contract
   - Verify the deployment
   - Save the contract address to `deployed-contract.json`

### Deploy to Local Hardhat Network

1. Start a local Hardhat node:
```bash
npx hardhat node
```

2. In a new terminal, deploy the contract:
```bash
npx hardhat run scripts/deploy.js --network localhost
```

## Updating the Frontend

After deploying the contract, you need to update the frontend with the new contract address:

1. Copy the contract address from the deployment output or from `deployed-contract.json`
2. Update the `CONTRACT_ADDRESS` constant in `src/routes/+page.svelte`

## Troubleshooting

### Contract Deployment Issues

- **Error: "Deployer account has no ETH"**: Make sure your Ganache account has ETH. You can transfer ETH from another account in Ganache.
- **Error: "Not connected to Ganache"**: Make sure Ganache is running and you're using the correct network configuration.
- **Error: "Contract deployment failed"**: Check the error message for more details. It could be due to insufficient gas, network issues, or contract compilation errors.

### Frontend Connection Issues

- **Error: "Contract does not exist at the specified address"**: Make sure you've updated the `CONTRACT_ADDRESS` in the frontend code with the correct address.
- **Error: "Failed to initialize contract"**: Check if MetaMask is connected to the correct network (Ganache with chainId 1337).
- **Error: "Internal JSON-RPC error"**: This could be due to network issues, contract ABI mismatch, or insufficient gas. Try increasing the gas limit in the transaction. 