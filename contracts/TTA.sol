// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TTA is ERC20 {
    constructor(
        string memory _name,
        string memory _symbol,
        address _to
    ) ERC20(_name, _symbol) {
        _mint(_to, 10 * 1e8 * 1e18);
    }
}
