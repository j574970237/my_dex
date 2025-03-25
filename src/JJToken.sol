// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

// MyToken
contract JJToken is ERC20 {

    constructor() ERC20("JJToken", "JJT") {
        _mint(msg.sender, 1e8 * 1e18);
    }

}