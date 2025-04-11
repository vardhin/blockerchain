// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BlockerChain {
    mapping(address => uint256) private balances;
    mapping(address => string) private usernames;
    mapping(address => uint256) private carbonCredits;
    
    // New profile system
    struct CarbonProfile {
        string name;
        string description;
        uint256 creditsAvailable;
        uint256 creditsSold;
        bool isProvider;
        uint256 reputation;
    }
    
    mapping(address => CarbonProfile) private carbonProfiles;
    address[] private providers;
    
    uint256 private carbonCreditPrice;
    uint256 private totalCarbonCredits;
    uint256 private totalVolume;
    
    event ValueStored(address indexed user, uint256 value);
    event UsernameSet(address indexed user, string username);
    event CarbonCreditsBought(address indexed buyer, address indexed provider, uint256 amount, uint256 price);
    event CarbonCreditsSold(address indexed seller, uint256 amount, uint256 price);
    event CarbonCreditPriceUpdated(uint256 newPrice);
    event ProfileCreated(address indexed user, string name, bool isProvider);
    event CreditsAdded(address indexed provider, uint256 amount);
    
    constructor() {
        carbonCreditPrice = 0.01 ether; // Initial price: 0.01 ETH per carbon credit
    }
    
    function store(uint256 value) public {
        balances[msg.sender] = value;
        emit ValueStored(msg.sender, value);
    }
    
    function retrieve() public view returns (uint256) {
        return balances[msg.sender];
    }
    
    function setUsername(string memory name) public {
        usernames[msg.sender] = name;
        emit UsernameSet(msg.sender, name);
    }
    
    function getUsername(address user) public view returns (string memory) {
        return usernames[user];
    }
    
    // Carbon Credit Functions
    function getCarbonCredits() public view returns (uint256) {
        return carbonCredits[msg.sender];
    }
    
    function getCarbonCreditPrice() public view returns (uint256) {
        return carbonCreditPrice;
    }
    
    function getTotalCarbonCredits() public view returns (uint256) {
        return totalCarbonCredits;
    }
    
    function getTotalVolume() public view returns (uint256) {
        return totalVolume;
    }
    
    // New profile functions
    function createProfile(string memory name, string memory description, bool isProvider) public {
        require(bytes(carbonProfiles[msg.sender].name).length == 0, "Profile already exists");
        
        carbonProfiles[msg.sender] = CarbonProfile({
            name: name,
            description: description,
            creditsAvailable: 0,
            creditsSold: 0,
            isProvider: isProvider,
            reputation: 100
        });
        
        if (isProvider) {
            providers.push(msg.sender);
        }
        
        emit ProfileCreated(msg.sender, name, isProvider);
    }
    
    function getProfile(address user) public view returns (
        string memory name,
        string memory description,
        uint256 creditsAvailable,
        uint256 creditsSold,
        bool isProvider,
        uint256 reputation
    ) {
        CarbonProfile memory profile = carbonProfiles[user];
        return (
            profile.name,
            profile.description,
            profile.creditsAvailable,
            profile.creditsSold,
            profile.isProvider,
            profile.reputation
        );
    }
    
    function getProviders() public view returns (address[] memory) {
        return providers;
    }
    
    function addCredits(uint256 amount) public {
        require(carbonProfiles[msg.sender].isProvider, "Only providers can add credits");
        require(amount > 0, "Amount must be greater than 0");
        
        carbonProfiles[msg.sender].creditsAvailable += amount;
        totalCarbonCredits += amount;
        
        emit CreditsAdded(msg.sender, amount);
    }
    
    function buyCarbonCredits(uint256 amount) public payable {
        require(amount > 0, "Amount must be greater than 0");
        require(carbonProfiles[msg.sender].name.length > 0, "Buyer must have a profile");
        
        uint256 totalCost = amount * carbonCreditPrice;
        require(msg.value >= totalCost, "Insufficient payment");
        
        // Find a provider with available credits
        address provider = address(0);
        for (uint i = 0; i < providers.length; i++) {
            if (carbonProfiles[providers[i]].creditsAvailable >= amount) {
                provider = providers[i];
                break;
            }
        }
        
        require(provider != address(0), "No provider with sufficient credits available");
        
        // Transfer carbon credits from provider to buyer
        carbonProfiles[provider].creditsAvailable -= amount;
        carbonProfiles[provider].creditsSold += amount;
        carbonCredits[msg.sender] += amount;
        totalVolume += amount;
        
        // Pay the provider
        uint256 providerPayment = amount * carbonCreditPrice;
        payable(provider).transfer(providerPayment);
        
        // Refund excess payment if any
        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost);
        }
        
        emit CarbonCreditsBought(msg.sender, provider, amount, carbonCreditPrice);
    }
    
    function sellCarbonCredits(uint256 amount) public {
        require(amount > 0, "Amount must be greater than 0");
        require(carbonCredits[msg.sender] >= amount, "Insufficient carbon credits");
        require(carbonProfiles[msg.sender].name.length > 0, "Seller must have a profile");
        
        // Transfer carbon credits from seller
        carbonCredits[msg.sender] -= amount;
        totalCarbonCredits -= amount;
        
        // Pay the seller
        uint256 payment = amount * carbonCreditPrice;
        payable(msg.sender).transfer(payment);
        
        emit CarbonCreditsSold(msg.sender, amount, carbonCreditPrice);
    }
    
    function setCarbonCreditPrice(uint256 newPrice) public {
        require(newPrice > 0, "Price must be greater than 0");
        carbonCreditPrice = newPrice;
        emit CarbonCreditPriceUpdated(newPrice);
    }
    
    // Payable function to receive ETH
    receive() external payable {}
}