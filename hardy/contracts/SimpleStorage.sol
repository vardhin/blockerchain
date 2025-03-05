// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract SimpleStorage {
    uint256 private number;

    // Store a number
    function store(uint256 _number) public {
        number = _number;
    }

    // Retrieve the stored number
    function retrieve() public view returns (uint256) {
        return number;
    }
}