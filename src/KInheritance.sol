// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/console.sol";

contract KInheritance {
  mapping(address => uint256) public balanceOf;
  mapping(address => address) public heirOf;
  mapping(address => uint256) public lastWithdraw;

  function setHeir(address heir) public {
    require(heir != msg.sender, "You cannot set yourself as heir");
    heirOf[msg.sender] = heir;
  }

  function deposit() public payable {
    require(heirOf[msg.sender] != address(0), "First set a heir");
    require(msg.value > 0, "You cannot deposit 0 ether");
    balanceOf[msg.sender] += msg.value;
    lastWithdraw[msg.sender] = block.timestamp;
  }

  function withdraw(uint256 amount) public {
    require(balanceOf[msg.sender] >= amount, "Insufficient funds");

    balanceOf[msg.sender] -= amount;
    lastWithdraw[msg.sender] = block.timestamp;
    if (amount > 0) {
      (bool ok, ) = msg.sender.call{value: amount}("");
      require(ok, "Did not withdraw");
    }
  }


  function transferFunds(address predecessor, address newHeir) public {
    require(heirOf[predecessor] == msg.sender, "You are not the heir");
    require(balanceOf[predecessor] != 0, "Predecessor has no funds");
    require(
      lastWithdraw[predecessor] + 30 days < block.timestamp,
      "Predecessor withdrew funds recently"
    );

    heirOf[predecessor] = address(0);
    heirOf[msg.sender] = newHeir;
    balanceOf[msg.sender] += balanceOf[predecessor];
    balanceOf[predecessor] = 0;
    lastWithdraw[msg.sender] = block.timestamp;
  }
}
