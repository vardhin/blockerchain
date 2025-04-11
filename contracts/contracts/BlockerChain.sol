// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract BlockerChain {
    mapping(address => uint256) private balances;
    mapping(address => string) private usernames;
    
    event ValueStored(address indexed user, uint256 value);
    event UsernameSet(address indexed user, string username);
    
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
    
    // Payable function to receive ETH
    receive() external payable {}
}