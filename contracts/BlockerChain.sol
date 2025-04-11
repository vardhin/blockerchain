// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BlockerChain {
    mapping(address => uint256) private balances;
    mapping(address => string) private usernames;
    mapping(address => uint256) private carbonCredits;
    
    uint256 private carbonCreditPrice;
    uint256 private totalCarbonCredits;
    uint256 private totalVolume;
    
    event ValueStored(address indexed user, uint256 value);
    event UsernameSet(address indexed user, string username);
    event CarbonCreditsBought(address indexed buyer, uint256 amount, uint256 price);
    event CarbonCreditsSold(address indexed seller, uint256 amount, uint256 price);
    event CarbonCreditPriceUpdated(uint256 newPrice);
    
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
    
    function buyCarbonCredits(uint256 amount) public payable {
        require(amount > 0, "Amount must be greater than 0");
        uint256 totalCost = amount * carbonCreditPrice;
        require(msg.value >= totalCost, "Insufficient payment");
        
        // Transfer carbon credits to buyer
        carbonCredits[msg.sender] += amount;
        totalCarbonCredits += amount;
        totalVolume += amount;
        
        // Refund excess payment if any
        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost);
        }
        
        emit CarbonCreditsBought(msg.sender, amount, carbonCreditPrice);
    }
    
    function sellCarbonCredits(uint256 amount) public {
        require(amount > 0, "Amount must be greater than 0");
        require(carbonCredits[msg.sender] >= amount, "Insufficient carbon credits");
        
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