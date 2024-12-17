// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

interface Events {
    event LandRegistered(address _landOwner, uint indexed _landIndex, string indexed _landLocation);
    event LandListedForSale(address _landOwner, uint indexed _landIndex, uint indexed _price, uint indexed plotsForSell);
    event LandDelistedForSale(address _landOwner, uint indexed _landIndex);
    event LandVerified(address indexed _landOwner, uint indexed _landIndex);
    event LandSold(address indexed _previousOwner, address indexed _newOwner, uint indexed _amount);
}
