// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MirkoToken is ERC20 {
    address owner;

    constructor(uint256 initialSupply) ERC20("MirkoToken", "MIRKO") {
        _mint(msg.sender, initialSupply);
        owner = msg.sender;
    }

    function mint(uint256 amount) public {
        require(msg.sender == owner, "you are not owner!");
        _mint(msg.sender, amount);
    }
}
