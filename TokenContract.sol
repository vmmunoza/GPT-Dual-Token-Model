// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract YointsToken is ERC20, Ownable {
    mapping(address => bool) private _blacklist;

    constructor() ERC20("Yoints Token", "YOINTS") {
        _mint(msg.sender, 100_000_000 * 10**18); // Minting 100 million YOINTS tokens
    }

    function blacklistAddress(address account) public onlyOwner {
        _blacklist[account] = true;
    }

    function unblacklistAddress(address account) public onlyOwner {
        _blacklist[account] = false;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(!_blacklist[msg.sender], "Sender is blacklisted");
        return super.transfer(recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(!_blacklist[sender], "Sender is blacklisted");
        return super.transferFrom(sender, recipient, amount);
    }
}
