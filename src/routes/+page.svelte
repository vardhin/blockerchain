<script>
  import { ethers } from 'ethers';
  import { onMount } from 'svelte';
  
  let accounts = [];
  let selectedAccount = '';
  let value = 0;
  let contract;
  let error = '';
  let loading = false;
  let friendAddress = '';
  let amountToSend = 0;
  let username = '';
  let usernames = {};
  let contractState = {
    value: 0,
    lastUpdated: null,
    isInitialized: false
  };
  let debugInfo = {
    network: '',
    chainId: '',
    contractAddress: '',
    lastError: null,
    lastTransaction: null
  };

  // Carbon credit related state
  let carbonCredits = {
    available: 0,
    price: 0,
    transactions: []
  };
  let amountToBuy = 0;
  let amountToSell = 0;
  let newPrice = 0;
  let marketStats = {
    totalVolume: 0,
    averagePrice: 0,
    totalCredits: 0
  };

  // Profile related state
  let profile = {
    name: '',
    description: '',
    creditsAvailable: 0,
    creditsSold: 0,
    isProvider: false,
    reputation: 0,
    exists: false
  };
  let profileName = '';
  let profileDescription = '';
  let isProvider = false;
  let amountToAdd = 0;
  let providers = [];
  let selectedProvider = null;

  // Update with your deployed contract address
  const CONTRACT_ADDRESS = '0x45a2B04e891A05abE9295EDA632B43c02c68f06D';
  const CONTRACT_ABI = [
    {
      "inputs": [],
      "name": "retrieve",
      "outputs": [{"type": "uint256"}],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [{"type": "uint256"}],
      "name": "store",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [{"type": "string"}],
      "name": "setUsername",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [{"type": "address"}],
      "name": "getUsername",
      "outputs": [{"type": "string"}],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "stateMutability": "payable",
      "type": "receive"
    },
    {
      "inputs": [],
      "name": "getCarbonCredits",
      "outputs": [{"type": "uint256"}],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [{"type": "uint256"}],
      "name": "buyCarbonCredits",
      "outputs": [],
      "stateMutability": "payable",
      "type": "function"
    },
    {
      "inputs": [{"type": "uint256"}],
      "name": "sellCarbonCredits",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [{"type": "uint256"}],
      "name": "setCarbonCreditPrice",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "getCarbonCreditPrice",
      "outputs": [{"type": "uint256"}],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "getTotalCarbonCredits",
      "outputs": [{"type": "uint256"}],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "getTotalVolume",
      "outputs": [{"type": "uint256"}],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [
        {"type": "string"},
        {"type": "string"},
        {"type": "bool"}
      ],
      "name": "createProfile",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    },
    {
      "inputs": [{"type": "address"}],
      "name": "getProfile",
      "outputs": [
        {"type": "string"},
        {"type": "string"},
        {"type": "uint256"},
        {"type": "uint256"},
        {"type": "bool"},
        {"type": "uint256"}
      ],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [],
      "name": "getProviders",
      "outputs": [{"type": "address[]"}],
      "stateMutability": "view",
      "type": "function"
    },
    {
      "inputs": [{"type": "uint256"}],
      "name": "addCredits",
      "outputs": [],
      "stateMutability": "nonpayable",
      "type": "function"
    }
  ];

  async function connectWallet() {
    if (typeof window.ethereum !== 'undefined') {
      try {
        loading = true;
        error = '';
        console.log('Attempting to connect wallet...');
        
        // Request accounts
        accounts = await window.ethereum.request({
          method: 'eth_requestAccounts'
        });
        
        console.log('Connected accounts:', accounts);
        
        if (!selectedAccount && accounts.length > 0) {
          selectedAccount = accounts[0];
        }

        // Get network information
        const provider = new ethers.BrowserProvider(window.ethereum);
        const network = await provider.getNetwork();
        debugInfo.network = network.name;
        debugInfo.chainId = network.chainId.toString();
        console.log('Connected to network:', network);
        
        // Check if we're on the correct network (Ganache)
        if (network.chainId !== 1337n) {
          try {
            // Request network switch to Ganache
            await window.ethereum.request({
              method: 'wallet_switchEthereumChain',
              params: [{ chainId: '0x539' }], // 1337 in hex
            });
          } catch (switchError) {
            // If Ganache network doesn't exist, add it
            if (switchError.code === 4902) {
              try {
                await window.ethereum.request({
                  method: 'wallet_addEthereumChain',
                  params: [{
                    chainId: '0x539',
                    chainName: 'Ganache',
                    nativeCurrency: {
                      name: 'ETH',
                      symbol: 'ETH',
                      decimals: 18
                    },
                    rpcUrls: ['http://127.0.0.1:7545'],
                    blockExplorerUrls: null
                  }]
                });
              } catch (addError) {
                error = 'Failed to add Ganache network: ' + addError.message;
                console.error('Failed to add Ganache network:', addError);
                return;
              }
            } else {
              error = 'Failed to switch to Ganache network: ' + switchError.message;
              console.error('Failed to switch network:', switchError);
              return;
            }
          }
        }
        
        // Initialize contract
        await initializeContract();
        
        // Load initial values
        await loadInitialData();
        
      } catch (err) {
        error = 'Error connecting wallet: ' + err.message;
        debugInfo.lastError = {
          message: err.message,
          timestamp: new Date().toISOString()
        };
        console.error('Error connecting wallet:', err);
      } finally {
        loading = false;
      }
    } else {
      error = 'Please install MetaMask!';
      console.error('MetaMask not detected');
    }
  }

  async function initializeContract() {
    try {
      if (!window.ethereum) {
        throw new Error('Please install MetaMask');
      }

      // Get the current network
      const provider = new ethers.BrowserProvider(window.ethereum);
      const network = await provider.getNetwork();
      console.log('Current network:', network);

      // Check if we're on Ganache (chainId 1337)
      if (network.chainId !== 1337n) {
        console.log('Not on Ganache network, attempting to switch...');
        try {
          await window.ethereum.request({
            method: 'wallet_switchEthereumChain',
            params: [{ chainId: '0x539' }], // 1337 in hex
          });
        } catch (switchError) {
          // This error code indicates that the chain has not been added to MetaMask
          if (switchError.code === 4902) {
            try {
              await window.ethereum.request({
                method: 'wallet_addEthereumChain',
                params: [{
                  chainId: '0x539',
                  chainName: 'Ganache',
                  nativeCurrency: {
                    name: 'ETH',
                    symbol: 'ETH',
                    decimals: 18
                  },
                  rpcUrls: ['http://127.0.0.1:7545'],
                  blockExplorerUrls: null
                }]
              });
            } catch (addError) {
              throw new Error('Failed to add Ganache network to MetaMask');
            }
          } else {
            throw switchError;
          }
        }
      }

      // Verify contract exists
      const code = await provider.getCode(CONTRACT_ADDRESS);
      if (code === '0x') {
        throw new Error('Contract does not exist at the specified address. Please ensure the contract is deployed.');
      }

      // Initialize contract
      contract = new ethers.Contract(
        CONTRACT_ADDRESS,
        CONTRACT_ABI,
        provider
      );

      // Get signer
      const signer = await provider.getSigner();
      contract = contract.connect(signer);

      console.log('Contract initialized successfully');
      return true;
    } catch (error) {
      console.error('Error initializing contract:', error);
      error = 'Failed to initialize contract: ' + error.message;
      return false;
    }
  }
  
  async function loadInitialData() {
    if (contract && selectedAccount) {
      try {
        // First check if profile exists
        let profileExists = false;
        try {
          const [, , , , , , exists] = await contract.getProfile(selectedAccount);
          profileExists = exists;
        } catch (err) {
          console.log('Profile does not exist yet');
          profileExists = false;
        }

        if (!profileExists) {
          // Reset all values if no profile exists
          carbonCredits.available = 0;
          carbonCredits.price = 0;
          marketStats.totalCredits = 0;
          marketStats.totalVolume = 0;
          marketStats.averagePrice = 0;
          profile.exists = false;
          providers = [];
          return;
        }

        // Load carbon credit data only if profile exists
        try {
          const credits = await contract.getCarbonCredits();
          carbonCredits.available = Number(credits);
        } catch (err) {
          console.error('Error loading carbon credits:', err);
          carbonCredits.available = 0;
        }
        
        try {
          const price = await contract.getCarbonCreditPrice();
          carbonCredits.price = Number(ethers.formatEther(price));
        } catch (err) {
          console.error('Error loading carbon credit price:', err);
          carbonCredits.price = 0;
        }
        
        try {
          const totalCredits = await contract.getTotalCarbonCredits();
          marketStats.totalCredits = Number(totalCredits);
        } catch (err) {
          console.error('Error loading total carbon credits:', err);
          marketStats.totalCredits = 0;
        }
        
        try {
          const totalVolume = await contract.getTotalVolume();
          marketStats.totalVolume = Number(totalVolume);
        } catch (err) {
          console.error('Error loading total volume:', err);
          marketStats.totalVolume = 0;
        }
        
        // Set average price to current price for now
        marketStats.averagePrice = carbonCredits.price;
        
        // Load profile data
        await loadProfile(selectedAccount);
        
        // Load providers
        await loadProviders();
        
        console.log('Carbon credit data loaded:', {
          available: carbonCredits.available,
          price: carbonCredits.price,
          totalCredits: marketStats.totalCredits,
          totalVolume: marketStats.totalVolume
        });
      } catch (err) {
        console.error('Error loading carbon credit data:', err);
      }
    }
  }
  
  async function loadProfile(address) {
    try {
      const [
        name,
        description,
        creditsAvailable,
        creditsSold,
        isProvider,
        reputation,
        exists
      ] = await contract.getProfile(address);
      
      profile = {
        name,
        description,
        creditsAvailable: Number(creditsAvailable),
        creditsSold: Number(creditsSold),
        isProvider,
        reputation: Number(reputation),
        exists: exists
      };
      
      console.log('Profile loaded:', profile);
    } catch (err) {
      console.error('Error loading profile:', err);
      // Reset profile to default state
      profile = {
        name: '',
        description: '',
        creditsAvailable: 0,
        creditsSold: 0,
        isProvider: false,
        reputation: 0,
        exists: false
      };
    }
  }
  
  async function loadProviders() {
    try {
      const providerAddresses = await contract.getProviders();
      providers = [];
      
      if (!providerAddresses || providerAddresses.length === 0) {
        console.log('No providers found');
        return;
      }
      
      for (const address of providerAddresses) {
        try {
          const [
            name,
            description,
            creditsAvailable,
            creditsSold,
            isProvider,
            reputation,
            exists
          ] = await contract.getProfile(address);
          
          if (exists) {
            providers.push({
              address,
              name,
              description,
              creditsAvailable: Number(creditsAvailable),
              creditsSold: Number(creditsSold),
              reputation: Number(reputation)
            });
          }
        } catch (err) {
          console.error(`Error loading provider profile for ${address}:`, err);
        }
      }
      
      console.log('Providers loaded:', providers);
    } catch (err) {
      console.error('Error loading providers:', err);
      providers = [];
    }
  }
  
  async function loadUsernames() {
    for (const account of accounts) {
      await loadUsername(account);
    }
  }

  let txStatus = '';
  
  async function setValue() {
    try {
      loading = true;
      error = '';
      txStatus = 'Sending transaction...';
      console.log('Setting value:', value);
      
      const tx = await contract.store(value);
      debugInfo.lastTransaction = {
        type: 'store',
        hash: tx.hash,
        value: value,
        timestamp: new Date().toISOString()
      };
      console.log('Transaction sent:', tx.hash);
      
      txStatus = `Transaction sent! Hash: ${tx.hash.slice(0,10)}...`;
      
      // Wait for confirmation
      txStatus = 'Waiting for confirmation...';
      const receipt = await tx.wait();
      console.log('Transaction confirmed:', receipt);
      
      txStatus = 'Value successfully stored!';
      await getValue();
      setTimeout(() => txStatus = '', 5000);
    } catch (err) {
      error = 'Error setting value: ' + err.message;
      debugInfo.lastError = {
        message: err.message,
        timestamp: new Date().toISOString()
      };
      console.error('Error setting value:', err);
      txStatus = '';
    } finally {
      loading = false;
    }
  }

  async function setUsername() {
    if (!username.trim()) {
      error = 'Username cannot be empty';
      return;
    }
    
    try {
      loading = true;
      error = '';
      txStatus = 'Setting username...';
      
      const tx = await contract.setUsername(username);
      txStatus = `Transaction sent! Hash: ${tx.hash.slice(0,10)}...`;
      
      // Wait for confirmation
      txStatus = 'Waiting for confirmation...';
      await tx.wait();
      
      // Update local usernames object
      usernames[selectedAccount] = username;
      txStatus = 'Username successfully set!';
      setTimeout(() => txStatus = '', 5000);
    } catch (err) {
      error = 'Error setting username: ' + err.message;
      console.error('Error setting username:', err);
      txStatus = '';
    } finally {
      loading = false;
    }
  }
  
  onMount(() => {
    if (window.ethereum) {
      window.ethereum.on('accountsChanged', function (newAccounts) {
        accounts = newAccounts;
        selectedAccount = newAccounts[0];
        initializeContract();
      });
    }
  });

  async function switchAccount(account) {
    selectedAccount = account;
    await initializeContract();
    await loadInitialData();
  }

  async function getBalance(address) {
    try {
      const provider = new ethers.BrowserProvider(window.ethereum);
      const balance = await provider.getBalance(address);
      return ethers.formatEther(balance);
    } catch (err) {
      console.error('Error getting balance:', err);
      return '0';
    }
  }

  async function getValue() {
    try {
      if (!contract) {
        console.warn('Contract not initialized');
        return;
      }
      console.log('Retrieving value...');
      const result = await contract.retrieve();
      value = Number(result);
      contractState.value = value;
      contractState.lastUpdated = new Date().toISOString();
      console.log('Retrieved value:', value);
    } catch (err) {
      error = 'Error getting value: ' + err.message;
      debugInfo.lastError = {
        message: err.message,
        timestamp: new Date().toISOString()
      };
      console.error('Error getting value:', err);
    }
  }

  async function loadUsername(address) {
    try {
      if (!contract) return '';
      const name = await contract.getUsername(address);
      usernames[address] = name;
      return name;
    } catch (err) {
      console.error('Error loading username:', err);
      return '';
    }
  }

  async function sendEth() {
    if (!friendAddress || !amountToSend) {
      error = 'Please enter both address and amount';
      return;
    }

    try {
      loading = true;
      error = '';
      txStatus = 'Sending ETH...';

      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner(selectedAccount);
      
      const tx = await signer.sendTransaction({
        to: friendAddress,
        value: ethers.parseEther(amountToSend.toString())
      });

      txStatus = `Transaction sent! Hash: ${tx.hash.slice(0,10)}...`;
      
      // Wait for confirmation
      txStatus = 'Waiting for confirmation...';
      await tx.wait();
      txStatus = 'ETH successfully sent!';
      
      // Reset form
      friendAddress = '';
      amountToSend = 0;
      
      setTimeout(() => txStatus = '', 5000);
    } catch (err) {
      error = 'Error sending ETH: ' + err.message;
      console.error('Error sending ETH:', err);
      txStatus = '';
    } finally {
      loading = false;
    }
  }

  async function createProfile() {
    if (!profileName.trim()) {
      error = 'Profile name cannot be empty';
      return;
    }
    
    try {
      loading = true;
      error = '';
      txStatus = 'Creating profile...';
      
      // Check if profile already exists
      try {
        const [name, , , , , , exists] = await contract.getProfile(selectedAccount);
        if (exists) {
          error = 'Profile already exists';
          txStatus = '';
          loading = false;
          return;
        }
      } catch (err) {
        // This is expected if profile doesn't exist yet
        console.log('Profile does not exist yet, proceeding with creation');
      }
      
      // Log the transaction parameters for debugging
      console.log('Creating profile with params:', {
        name: profileName,
        description: profileDescription,
        isProvider: isProvider
      });
      
      // Get the current network for debugging
      const provider = new ethers.BrowserProvider(window.ethereum);
      const network = await provider.getNetwork();
      console.log('Current network:', network);
      
      // Get the contract code for debugging
      const code = await provider.getCode(CONTRACT_ADDRESS);
      console.log('Contract code exists:', code !== '0x');
      
      // Create the profile with higher gas limit for provider profiles
      const gasLimit = isProvider ? 1000000 : 500000;
      console.log(`Using gas limit: ${gasLimit}`);
      
      // Create the profile with explicit gas limit
      const tx = await contract.createProfile(
        profileName, 
        profileDescription, 
        isProvider,
        { gasLimit: gasLimit } // Higher gas limit for provider profiles
      );
      
      txStatus = `Transaction sent! Hash: ${tx.hash.slice(0,10)}...`;
      
      // Wait for confirmation
      txStatus = 'Waiting for confirmation...';
      await tx.wait();
      
      // Update local profile
      await loadProfile(selectedAccount);
      
      txStatus = 'Profile successfully created!';
      setTimeout(() => txStatus = '', 5000);
    } catch (err) {
      error = 'Error creating profile: ' + err.message;
      console.error('Error creating profile:', err);
      
      // Add more detailed error information
      if (err.code === 'CALL_EXCEPTION') {
        console.error('Transaction failed. This could be due to:');
        console.error('1. Contract not deployed at the specified address');
        console.error('2. Wrong network connection');
        console.error('3. Contract ABI mismatch');
        console.error('4. Insufficient gas');
        
        // Check if this is a provider profile and suggest increasing gas
        if (isProvider) {
          error += ' (Provider profiles may require more gas. Try again with a higher gas limit.)';
        }
      }
      
      txStatus = '';
    } finally {
      loading = false;
    }
  }
  
  async function addCredits() {
    if (!amountToAdd || amountToAdd <= 0) {
      error = 'Please enter a valid amount to add';
      return;
    }
    
    try {
      loading = true;
      error = '';
      txStatus = 'Adding credits...';
      
      // Use a higher gas limit for adding credits
      const tx = await contract.addCredits(amountToAdd, { gasLimit: 500000 });
      txStatus = `Transaction sent! Hash: ${tx.hash.slice(0,10)}...`;
      
      // Wait for confirmation
      txStatus = 'Waiting for confirmation...';
      await tx.wait();
      
      // Update local profile and market stats
      await loadProfile(selectedAccount);
      await loadInitialData();
      
      txStatus = 'Credits successfully added!';
      amountToAdd = 0;
      setTimeout(() => txStatus = '', 5000);
    } catch (err) {
      error = 'Error adding credits: ' + err.message;
      console.error('Error adding credits:', err);
      
      // Add more detailed error information
      if (err.code === 'CALL_EXCEPTION') {
        console.error('Transaction failed. This could be due to:');
        console.error('1. Insufficient gas');
        console.error('2. Contract state error');
        console.error('3. Network issues');
      }
      
      txStatus = '';
    } finally {
      loading = false;
    }
  }

  async function buyCarbonCredits() {
    if (!amountToBuy || amountToBuy <= 0) {
      error = 'Please enter a valid amount to buy';
      return;
    }
    
    if (!profile.exists) {
      error = 'You need to create a profile before buying carbon credits';
      return;
    }

    try {
      loading = true;
      error = '';
      txStatus = 'Processing purchase...';

      const totalCost = amountToBuy * carbonCredits.price;
      
      // Check if there are providers with available credits
      const providerAddresses = await contract.getProviders();
      let hasAvailableProvider = false;
      
      for (const address of providerAddresses) {
        try {
          const [, , creditsAvailable, , , , exists] = await contract.getProfile(address);
          if (exists && Number(creditsAvailable) >= amountToBuy) {
            hasAvailableProvider = true;
            break;
          }
        } catch (err) {
          console.error(`Error checking provider ${address}:`, err);
        }
      }
      
      if (!hasAvailableProvider) {
        error = 'No providers with sufficient credits available';
        txStatus = '';
        loading = false;
        return;
      }

      const tx = await contract.buyCarbonCredits(amountToBuy, {
        value: ethers.parseEther(totalCost.toString())
      });

      txStatus = `Transaction sent! Hash: ${tx.hash.slice(0,10)}...`;
      await tx.wait();
      
      // Update local state
      carbonCredits.available += amountToBuy;
      carbonCredits.transactions.push({
        type: 'buy',
        amount: amountToBuy,
        price: carbonCredits.price,
        timestamp: new Date().toISOString()
      });
      
      // Refresh market stats and providers
      await loadInitialData();
      
      txStatus = 'Purchase successful!';
      amountToBuy = 0;
      setTimeout(() => txStatus = '', 5000);
    } catch (err) {
      error = 'Error buying carbon credits: ' + err.message;
      console.error('Error buying carbon credits:', err);
      txStatus = '';
    } finally {
      loading = false;
    }
  }

  async function sellCarbonCredits() {
    if (!amountToSell || amountToSell <= 0) {
      error = 'Please enter a valid amount to sell';
      return;
    }

    if (amountToSell > carbonCredits.available) {
      error = 'Insufficient carbon credits to sell';
      return;
    }
    
    if (!profile.exists) {
      error = 'You need to create a profile before selling carbon credits';
      return;
    }

    try {
      loading = true;
      error = '';
      txStatus = 'Processing sale...';

      // Double-check available credits before selling
      try {
        const availableCredits = await contract.getCarbonCredits();
        if (Number(availableCredits) < amountToSell) {
          error = 'Insufficient carbon credits to sell';
          txStatus = '';
          loading = false;
          return;
        }
      } catch (err) {
        console.error('Error checking available credits:', err);
      }

      const tx = await contract.sellCarbonCredits(amountToSell);
      txStatus = `Transaction sent! Hash: ${tx.hash.slice(0,10)}...`;
      await tx.wait();
      
      // Update local state
      carbonCredits.available -= amountToSell;
      carbonCredits.transactions.push({
        type: 'sell',
        amount: amountToSell,
        price: carbonCredits.price,
        timestamp: new Date().toISOString()
      });
      
      // Refresh market stats
      await loadInitialData();
      
      txStatus = 'Sale successful!';
      amountToSell = 0;
      setTimeout(() => txStatus = '', 5000);
    } catch (err) {
      error = 'Error selling carbon credits: ' + err.message;
      console.error('Error selling carbon credits:', err);
      txStatus = '';
    } finally {
      loading = false;
    }
  }

  async function updateCarbonCreditPrice() {
    if (!newPrice || newPrice <= 0) {
      error = 'Please enter a valid price';
      return;
    }

    try {
      loading = true;
      error = '';
      txStatus = 'Updating price...';

      const tx = await contract.setCarbonCreditPrice(ethers.parseEther(newPrice.toString()));
      txStatus = `Transaction sent! Hash: ${tx.hash.slice(0,10)}...`;
      await tx.wait();
      
      // Update local state
      carbonCredits.price = newPrice;
      marketStats.averagePrice = newPrice;
      txStatus = 'Price updated successfully!';
      newPrice = 0;
      setTimeout(() => txStatus = '', 5000);
    } catch (err) {
      error = 'Error updating price: ' + err.message;
      console.error('Error updating price:', err);
      txStatus = '';
    } finally {
      loading = false;
    }
  }

  // Add this function to calculate the total cost
  $: totalBuyCost = amountToBuy ? (amountToBuy * carbonCredits.price).toFixed(4) : '0.0000';
  $: totalSellValue = amountToSell ? (amountToSell * carbonCredits.price).toFixed(4) : '0.0000';
</script>

<svelte:head>
  <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
</svelte:head>

<main class="container">
  <header class="header">
    <h1 class="title">Carbon Credit Exchange</h1>
    <div class="market-stats">
      <div class="stat-item">
        <span class="stat-label">Total Volume</span>
        <span class="stat-value">{marketStats.totalVolume} CC</span>
      </div>
      <div class="stat-item">
        <span class="stat-label">Average Price</span>
        <span class="stat-value">{marketStats.averagePrice} ETH</span>
      </div>
      <div class="stat-item">
        <span class="stat-label">Total Credits</span>
        <span class="stat-value">{marketStats.totalCredits} CC</span>
      </div>
    </div>
  </header>

  {#if error}
    <div class="error-banner">{error}</div>
  {/if}

  {#if txStatus}
    <div class="tx-status">{txStatus}</div>
  {/if}

  {#if accounts.length === 0}
    <div class="connect-section">
      <h2>Welcome to Carbon Credit Exchange</h2>
      <p>Connect your wallet to start trading carbon credits</p>
      <button class="connect-btn" on:click={connectWallet} disabled={loading}>
        {loading ? 'Connecting...' : 'Connect Wallet'}
      </button>
    </div>
  {:else}
    <div class="dashboard">
      <div class="wallet-info card">
        <h3>Wallet Information</h3>
        <div class="account-selector">
          {#each accounts as account}
            <button 
              class:selected={account === selectedAccount}
              on:click={() => switchAccount(account)}
            >
              {account.slice(0, 6)}...{account.slice(-4)}
            </button>
          {/each}
        </div>
        {#await getBalance(selectedAccount) then balance}
          <div class="balance-info">
            <span>Balance:</span>
            <span class="balance">{balance} ETH</span>
          </div>
        {/await}
      </div>

      {#if !profile.exists}
        <div class="profile-creation card">
          <h3>Create Your Profile</h3>
          <p>You need to create a profile before trading carbon credits</p>
          <div class="input-group">
            <input 
              type="text" 
              bind:value={profileName} 
              placeholder="Profile Name"
            >
            <textarea 
              bind:value={profileDescription} 
              placeholder="Profile Description"
              rows="3"
            ></textarea>
            <div class="checkbox-group">
              <input 
                type="checkbox" 
                id="isProvider" 
                bind:checked={isProvider}
              >
              <label for="isProvider">I want to provide carbon credits</label>
            </div>
            <button 
              on:click={createProfile} 
              disabled={loading}
              class="action-btn create"
            >
              {loading ? 'Creating...' : 'Create Profile'}
            </button>
          </div>
        </div>
      {:else}
        <div class="profile-info card">
          <h3>Your Profile</h3>
          <div class="profile-details">
            <div class="profile-field">
              <span class="field-label">Name:</span>
              <span class="field-value">{profile.name}</span>
            </div>
            <div class="profile-field">
              <span class="field-label">Description:</span>
              <span class="field-value">{profile.description}</span>
            </div>
            <div class="profile-field">
              <span class="field-label">Type:</span>
              <span class="field-value">{profile.isProvider ? 'Provider' : 'Trader'}</span>
            </div>
            <div class="profile-field">
              <span class="field-label">Reputation:</span>
              <span class="field-value">{profile.reputation}</span>
            </div>
            {#if profile.isProvider}
              <div class="profile-field">
                <span class="field-label">Credits Available:</span>
                <span class="field-value">{profile.creditsAvailable} CC</span>
              </div>
              <div class="profile-field">
                <span class="field-label">Credits Sold:</span>
                <span class="field-value">{profile.creditsSold} CC</span>
              </div>
              <div class="input-group">
                <input 
                  type="number" 
                  bind:value={amountToAdd} 
                  placeholder="Amount to add"
                  min="0"
                  step="1"
                >
                <button 
                  on:click={addCredits} 
                  disabled={loading}
                  class="action-btn add"
                >
                  {loading ? 'Adding...' : 'Add Credits'}
                </button>
              </div>
            {/if}
          </div>
        </div>
      {/if}

      <div class="trading-section">
        <div class="market-info card">
          <h3>Market Information</h3>
          <div class="price-info">
            <span>Current Price:</span>
            <span class="price">{carbonCredits.price} ETH/CC</span>
          </div>
          <div class="credits-info">
            <span>Your Credits:</span>
            <span class="credits">{carbonCredits.available} CC</span>
          </div>
        </div>

        {#if profile.exists}
          <div class="trading-actions">
            <div class="buy-section card">
              <h3>Buy Carbon Credits</h3>
              <div class="input-group">
                <input 
                  type="number" 
                  bind:value={amountToBuy} 
                  placeholder="Amount to buy"
                  min="0"
                  step="1"
                >
                <div class="cost-info">
                  <span>Total Cost:</span>
                  <span class="cost-value">{totalBuyCost} ETH</span>
                </div>
                <button 
                  on:click={buyCarbonCredits} 
                  disabled={loading}
                  class="action-btn buy"
                >
                  {loading ? 'Processing...' : 'Buy Credits'}
                </button>
              </div>
            </div>

            <div class="sell-section card">
              <h3>Sell Carbon Credits</h3>
              <div class="input-group">
                <input 
                  type="number" 
                  bind:value={amountToSell} 
                  placeholder="Amount to sell"
                  min="0"
                  step="1"
                >
                <div class="cost-info">
                  <span>Total Value:</span>
                  <span class="cost-value">{totalSellValue} ETH</span>
                </div>
                <button 
                  on:click={sellCarbonCredits} 
                  disabled={loading}
                  class="action-btn sell"
                >
                  {loading ? 'Processing...' : 'Sell Credits'}
                </button>
              </div>
            </div>
          </div>

          <div class="price-update card">
            <h3>Update Market Price</h3>
            <div class="input-group">
              <input 
                type="number" 
                bind:value={newPrice} 
                placeholder="New price in ETH"
                min="0"
                step="0.0001"
              >
              <button 
                on:click={updateCarbonCreditPrice} 
                disabled={loading}
                class="action-btn update"
              >
                {loading ? 'Updating...' : 'Update Price'}
              </button>
            </div>
          </div>

          <div class="providers card">
            <h3>Carbon Credit Providers</h3>
            <div class="provider-list">
              {#each providers as provider}
                <div class="provider-item">
                  <div class="provider-header">
                    <span class="provider-name">{provider.name}</span>
                    <span class="provider-reputation">Rep: {provider.reputation}</span>
                  </div>
                  <div class="provider-description">{provider.description}</div>
                  <div class="provider-stats">
                    <span>Available: {provider.creditsAvailable} CC</span>
                    <span>Sold: {provider.creditsSold} CC</span>
                  </div>
                </div>
              {/each}
            </div>
          </div>

          <div class="transactions card">
            <h3>Recent Transactions</h3>
            <div class="transaction-list">
              {#each carbonCredits.transactions.slice(-5).reverse() as tx}
                <div class="transaction-item">
                  <span class="tx-type {tx.type}">{tx.type}</span>
                  <span class="tx-amount">{tx.amount} CC</span>
                  <span class="tx-price">{tx.price} ETH</span>
                  <span class="tx-time">{new Date(tx.timestamp).toLocaleString()}</span>
                </div>
              {/each}
            </div>
          </div>
        {/if}
      </div>
    </div>
  {/if}
</main>

<style>
  :global(body) {
    background-color: #f8fafc;
    color: #1e293b;
    margin: 0;
    font-family: 'Inter', system-ui, -apple-system, sans-serif;
  }

  .container {
    max-width: 1200px;
    margin: 0 auto;
    padding: 2rem;
  }

  .header {
    text-align: center;
    margin-bottom: 3rem;
  }

  .title {
    font-size: 2.5rem;
    font-weight: 700;
    color: #0f172a;
    margin-bottom: 1.5rem;
  }

  .market-stats {
    display: flex;
    justify-content: center;
    gap: 2rem;
    margin-top: 1rem;
  }

  .stat-item {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 0.5rem;
  }

  .stat-label {
    font-size: 0.875rem;
    color: #64748b;
  }

  .stat-value {
    font-size: 1.25rem;
    font-weight: 600;
    color: #0f172a;
  }

  .error-banner {
    background-color: #fee2e2;
    color: #dc2626;
    padding: 1rem;
    border-radius: 8px;
    margin-bottom: 1rem;
    text-align: center;
  }

  .tx-status {
    background-color: #dbeafe;
    color: #2563eb;
    padding: 1rem;
    border-radius: 8px;
    margin-bottom: 1rem;
    text-align: center;
  }

  .connect-section {
    text-align: center;
    padding: 4rem 2rem;
    background-color: white;
    border-radius: 12px;
    box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
  }

  .connect-section h2 {
    font-size: 2rem;
    color: #0f172a;
    margin-bottom: 1rem;
  }

  .connect-section p {
    color: #64748b;
    margin-bottom: 2rem;
  }

  .dashboard {
    display: grid;
    gap: 2rem;
  }

  .card {
    background-color: white;
    border-radius: 12px;
    padding: 1.5rem;
    box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1);
  }

  .card h3 {
    font-size: 1.25rem;
    color: #0f172a;
    margin-bottom: 1.5rem;
  }

  .wallet-info {
    margin-bottom: 2rem;
  }

  .account-selector {
    display: flex;
    gap: 1rem;
    margin-bottom: 1rem;
  }

  .account-selector button {
    padding: 0.5rem 1rem;
    border: 1px solid #e2e8f0;
    border-radius: 8px;
    background: white;
    color: #64748b;
    cursor: pointer;
    transition: all 0.2s ease;
  }

  .account-selector button.selected {
    background: #2563eb;
    color: white;
    border-color: #2563eb;
  }

  .balance-info {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 1rem;
    background: #f8fafc;
    border-radius: 8px;
  }

  .balance {
    font-weight: 600;
    color: #0f172a;
  }

  .trading-section {
    display: grid;
    gap: 2rem;
  }

  .market-info {
    display: flex;
    justify-content: space-between;
    align-items: center;
  }

  .price-info, .credits-info {
    display: flex;
    flex-direction: column;
    gap: 0.5rem;
  }

  .price, .credits {
    font-size: 1.5rem;
    font-weight: 600;
    color: #0f172a;
  }

  .trading-actions {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 2rem;
  }

  .input-group {
    display: flex;
    flex-direction: column;
    gap: 1rem;
  }

  .input-group input, .input-group textarea {
    padding: 0.75rem;
    border: 1px solid #e2e8f0;
    border-radius: 8px;
    font-size: 1rem;
  }

  .checkbox-group {
    display: flex;
    align-items: center;
    gap: 0.5rem;
  }

  .action-btn {
    padding: 0.75rem 1.5rem;
    border: none;
    border-radius: 8px;
    font-weight: 500;
    cursor: pointer;
    transition: all 0.2s ease;
  }

  .action-btn.buy {
    background: #22c55e;
    color: white;
  }

  .action-btn.sell {
    background: #ef4444;
    color: white;
  }

  .action-btn.update {
    background: #2563eb;
    color: white;
  }

  .action-btn.create {
    background: #8b5cf6;
    color: white;
  }

  .action-btn.add {
    background: #f59e0b;
    color: white;
  }

  .action-btn:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  .transaction-list {
    display: flex;
    flex-direction: column;
    gap: 1rem;
  }

  .transaction-item {
    display: grid;
    grid-template-columns: auto 1fr 1fr 1fr;
    gap: 1rem;
    padding: 1rem;
    background: #f8fafc;
    border-radius: 8px;
    align-items: center;
  }

  .tx-type {
    padding: 0.25rem 0.75rem;
    border-radius: 4px;
    font-size: 0.875rem;
    font-weight: 500;
  }

  .tx-type.buy {
    background: #dcfce7;
    color: #166534;
  }

  .tx-type.sell {
    background: #fee2e2;
    color: #991b1b;
  }

  .cost-info {
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 0.5rem 0;
    font-size: 0.9rem;
    color: #64748b;
  }

  .cost-value {
    font-weight: 600;
    color: #0f172a;
  }

  .profile-creation, .profile-info {
    margin-bottom: 2rem;
  }

  .profile-details {
    display: flex;
    flex-direction: column;
    gap: 1rem;
  }

  .profile-field {
    display: flex;
    justify-content: space-between;
    padding: 0.5rem;
    background: #f8fafc;
    border-radius: 8px;
  }

  .field-label {
    font-weight: 500;
    color: #64748b;
  }

  .field-value {
    font-weight: 600;
    color: #0f172a;
  }

  .provider-list {
    display: flex;
    flex-direction: column;
    gap: 1rem;
  }

  .provider-item {
    padding: 1rem;
    background: #f8fafc;
    border-radius: 8px;
  }

  .provider-header {
    display: flex;
    justify-content: space-between;
    margin-bottom: 0.5rem;
  }

  .provider-name {
    font-weight: 600;
    color: #0f172a;
  }

  .provider-reputation {
    color: #8b5cf6;
    font-weight: 500;
  }

  .provider-description {
    color: #64748b;
    margin-bottom: 0.5rem;
  }

  .provider-stats {
    display: flex;
    justify-content: space-between;
    font-size: 0.875rem;
    color: #64748b;
  }

  @media (max-width: 768px) {
    .container {
      padding: 1rem;
    }

    .market-stats {
      flex-direction: column;
      gap: 1rem;
    }

    .trading-actions {
      grid-template-columns: 1fr;
    }

    .transaction-item {
      grid-template-columns: 1fr;
      text-align: center;
    }
  }
</style>