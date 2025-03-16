// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract RNT is ERC20, ERC20Permit {

    constructor() ERC20("RNTToken", "RNT") ERC20Permit("RNT") {
        _mint(msg.sender, 1e7 * 1e18);
    }

}