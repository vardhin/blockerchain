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

  // Update with your deployed contract address
  const CONTRACT_ADDRESS = '0xA88535C9C4F446857975fa18a154eD6AA57d98A1';
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
    }
  ];

  async function connectWallet() {
    if (typeof window.ethereum !== 'undefined') {
      try {
        loading = true;
        error = '';
        
        // Request accounts
        accounts = await window.ethereum.request({
          method: 'eth_requestAccounts'  // Changed from wallet_requestPermissions
        });
        
        console.log('Connected accounts:', accounts);
        
        if (!selectedAccount && accounts.length > 0) {
          selectedAccount = accounts[0];
        }
        
        // Initialize contract
        await initializeContract();
        
        // Load initial values
        await loadInitialData();
        
      } catch (err) {
        error = 'Error connecting wallet: ' + err.message;
        console.error('Error connecting wallet:', err);
      } finally {
        loading = false;
      }
    } else {
      error = 'Please install MetaMask!';
    }
  }

  async function initializeContract() {
    try {
      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner(selectedAccount);
      contract = new ethers.Contract(CONTRACT_ADDRESS, CONTRACT_ABI, signer);
    } catch (err) {
      error = 'Failed to initialize contract: ' + err.message;
      console.error('Contract initialization error:', err);
    }
  }
  
  async function loadInitialData() {
    if (contract && selectedAccount) {
      await getValue();
      await loadUsernames();
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
      
      const tx = await contract.store(value);
      txStatus = `Transaction sent! Hash: ${tx.hash.slice(0,10)}...`;
      
      // Wait for confirmation
      txStatus = 'Waiting for confirmation...';
      await tx.wait();
      txStatus = 'Value successfully stored!';
      await getValue();
      setTimeout(() => txStatus = '', 5000);
    } catch (err) {
      error = 'Error setting value: ' + err.message;
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
      if (!contract) return;
      const result = await contract.retrieve();
      value = Number(result);
    } catch (err) {
      error = 'Error getting value: ' + err.message;
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
</script>

<svelte:head>
  <link href="https://fonts.googleapis.com/css2?family=Quicksand:wght@300;400;500;600;700&display=swap" rel="stylesheet">
</svelte:head>

<main class="container">
  <h1 class="title">BlockerChain DApp</h1>
  
  {#if error}
    <p class="error">{error}</p>
  {/if}

  {#if txStatus}
    <div class="tx-status">{txStatus}</div>
  {/if}
  
  {#if accounts.length === 0}
    <button class="connect-btn" on:click={connectWallet} disabled={loading}>
      {loading ? 'Connecting...' : 'Connect Wallet'}
    </button>
  {:else}
    <div class="accounts card">
      <h2 class="section-title">Available Accounts</h2>
      {#each accounts as account}
        <div class="account-item">
          <button 
            class:selected={account === selectedAccount}
            on:click={() => switchAccount(account)}
          >
            {account.slice(0, 6)}...{account.slice(-4)}
          </button>
          {#await getBalance(account) then balance}
            <span class="balance">{balance} ETH</span>
          {/await}
        </div>
      {/each}
    </div>

    <div class="interaction">
      <h3 class="selected-account">Selected Account: {selectedAccount.slice(0, 6)}...{selectedAccount.slice(-4)}</h3>
      
      <div class="username-section card">
        <h4 class="card-title">Set Username</h4>
        <div class="input-group">
          <input type="text" bind:value={username} class="input" placeholder="Enter username">
          <button on:click={setUsername} disabled={loading} class="action-btn">
            {loading ? 'Setting...' : 'Set Username'}
          </button>
        </div>
      </div>

      <div class="accounts card">
        <h4 class="card-title">Usernames</h4>
        {#each accounts as account}
          <div class="account-item">
            <span>{account.slice(0, 6)}...{account.slice(-4)}</span>
            {#await loadUsername(account) then name}
              <span class="username">{name || 'No username set'}</span>
            {/await}
          </div>
        {/each}
      </div>
      
      <div class="contract-interaction card">
        <h4 class="card-title">Contract Interaction</h4>
        <div class="input-group">
          <input type="number" bind:value class="input" placeholder="Enter value">
          <div class="button-group">
            <button on:click={setValue} disabled={loading} class="action-btn">Set Value</button>
            <button on:click={getValue} disabled={loading} class="action-btn secondary">Get Value</button>
          </div>
        </div>
      </div>

      <div class="send-eth card">
        <h4 class="card-title">Send ETH</h4>
        <input 
          type="text" 
          bind:value={friendAddress} 
          placeholder="Enter friend's ETH address"
          class="input"
        >
        <input 
          type="number" 
          bind:value={amountToSend} 
          min="0" 
          step="0.0001" 
          placeholder="Amount in ETH"
          class="input"
        >
        <button on:click={sendEth} disabled={loading} class="action-btn full-width">
          {loading ? 'Sending...' : 'Send ETH'}
        </button>
      </div>
    </div>
  {/if}
</main>

<style>
  :global(body) {
    background-color: #111827;
    color: #e5e7eb;
    margin: 0;
    font-family: 'Quicksand', system-ui, -apple-system, sans-serif;
  }

  .container {
    max-width: 800px;
    margin: 0 auto;
    padding: 2rem;
  }

  .title {
    font-size: 2.5rem;
    font-weight: 700;
    color: #f3f4f6;
    margin-bottom: 2rem;
  }

  .error {
    background-color: rgba(220, 38, 38, 0.2);
    color: #fca5a5;
    padding: 1rem;
    border-radius: 8px;
    margin: 1rem 0;
  }

  .card {
    background-color: #1f2937;
    border-radius: 12px;
    padding: 1.5rem;
    box-shadow: 0 4px 6px rgba(0, 0, 0, 0.2);
    margin-bottom: 1.5rem;
    border: 1px solid #374151;
  }

  .section-title {
    font-size: 1.5rem;
    font-weight: 600;
    color: #f3f4f6;
    margin-bottom: 1rem;
  }

  .card-title {
    font-size: 1.25rem;
    font-weight: 600;
    color: #f3f4f6;
    margin-bottom: 1rem;
  }

  .account-item {
    display: flex;
    align-items: center;
    gap: 1rem;
    margin: 0.75rem 0;
  }

  .account-item button {
    padding: 0.5rem 1rem;
    border: 1px solid #374151;
    border-radius: 8px;
    background: #2d3748;
    color: #e5e7eb;
    cursor: pointer;
    transition: all 0.2s ease;
    font-size: 0.9rem;
    font-family: 'Quicksand', sans-serif;
  }

  .tx-status {
    background-color: rgba(59, 130, 246, 0.2);
    color: #93c5fd;
    padding: 0.75rem;
    border-radius: 8px;
    margin: 0.5rem 0;
    text-align: center;
    border-left: 4px solid #3b82f6;
  }
  
  .account-item button:hover {
    background: #374151;
  }

  .account-item button.selected {
    background: #4b5563;
    border-color: #6b7280;
    font-weight: 600;
  }

  .balance {
    font-family: 'Quicksand', monospace;
    color: #9ca3af;
  }
  
  .username {
    font-weight: 500;
    color: #60a5fa;
    padding-left: 0.5rem;
  }
  
  .username-section {
    margin-bottom: 1rem;
  }

  .selected-account {
    font-size: 1rem;
    color: #9ca3af;
    margin-bottom: 1rem;
  }

  .input-group {
    display: flex;
    flex-direction: column;
    gap: 1rem;
  }

  .button-group {
    display: flex;
    gap: 0.5rem;
  }

  .input {
    padding: 0.75rem;
    border: 1px solid #374151;
    border-radius: 8px;
    background: #2d3748;
    color: #e5e7eb;
    width: 100%;
    font-size: 1rem;
    transition: border-color 0.2s ease;
    font-family: 'Quicksand', sans-serif;
  }

  .input::placeholder {
    color: #6b7280;
  }

  .input:focus {
    outline: none;
    border-color: #60a5fa;
    background: #374151;
  }

  .action-btn {
    padding: 0.75rem 1.5rem;
    border: none;
    border-radius: 8px;
    background: #3b82f6;
    color: white;
    font-weight: 500;
    cursor: pointer;
    transition: background-color 0.2s ease;
    font-family: 'Quicksand', sans-serif;
  }

  .action-btn:hover {
    background: #2563eb;
  }

  .action-btn:disabled {
    background: #4b5563;
    cursor: not-allowed;
  }

  .action-btn.secondary {
    background: #374151;
    color: #e5e7eb;
  }

  .action-btn.secondary:hover {
    background: #4b5563;
  }

  .connect-btn {
    padding: 1rem 2rem;
    font-size: 1.1rem;
    font-weight: 500;
    background: #3b82f6;
    color: white;
    border: none;
    border-radius: 8px;
    cursor: pointer;
    transition: background-color 0.2s ease;
    font-family: 'Quicksand', sans-serif;
  }

  .connect-btn:hover {
    background: #2563eb;
  }

  .full-width {
    width: 100%;
  }

  @media (max-width: 640px) {
    .container {
      padding: 1rem;
    }

    .button-group {
      flex-direction: column;
    }
  }
</style>