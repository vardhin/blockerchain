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

  const CONTRACT_ADDRESS = '0x70997970C51812dc3A010C7d01b50e0d17dc79C8';
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
    }
  ];

  async function connectWallet() {
    if (typeof window.ethereum !== 'undefined') {
      try {
        loading = true;
        error = '';
        
        // Request permissions for all accounts
        await window.ethereum.request({
          method: 'wallet_requestPermissions',
          params: [{
            eth_accounts: {}
          }]
        });
        
        // Get all accounts after permission
        accounts = await window.ethereum.request({
          method: 'eth_accounts'
        });
        
        console.log('Connected accounts:', accounts); // Debug log
        
        // Set first account as default if none selected
        if (!selectedAccount) {
          selectedAccount = accounts[0];
        }
        
        // Initialize contract
        await initializeContract();
        
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
    const provider = new ethers.BrowserProvider(window.ethereum);
    const signer = await provider.getSigner(selectedAccount);
    contract = new ethers.Contract(CONTRACT_ADDRESS, CONTRACT_ABI, signer);
  }

  async function switchAccount(account) {
    selectedAccount = account;
    await initializeContract();
  }

  async function getBalance(account) {
    const provider = new ethers.BrowserProvider(window.ethereum);
    const balance = await provider.getBalance(account);
    return ethers.formatEther(balance);
  }

  async function setValue() {
    try {
      loading = true;
      error = '';
      const tx = await contract.store(value);
      await tx.wait();
    } catch (err) {
      error = 'Error setting value: ' + err.message;
      console.error('Error setting value:', err);
    } finally {
      loading = false;
    }
  }

  async function getValue() {
    try {
      const result = await contract.retrieve();
      value = Number(result);
    } catch (err) {
      error = 'Error getting value: ' + err.message;
      console.error('Error getting value:', err);
    }
  }

  async function sendEth() {
    try {
      loading = true;
      error = '';
      
      if (!ethers.isAddress(friendAddress)) {
        throw new Error('Invalid Ethereum address');
      }
      
      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner(selectedAccount);
      
      const tx = await signer.sendTransaction({
        to: friendAddress,
        value: ethers.parseEther(amountToSend.toString())
      });
      
      await tx.wait();
    } catch (err) {
      error = 'Error sending ETH: ' + err.message;
      console.error('Error sending ETH:', err);
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
</script>

<svelte:head>
  <link href="https://fonts.googleapis.com/css2?family=Quicksand:wght@300;400;500;600;700&display=swap" rel="stylesheet">
</svelte:head>

<main class="container">
  <h1 class="title">SimpleStorage DApp</h1>
  
  {#if error}
    <p class="error">{error}</p>
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
