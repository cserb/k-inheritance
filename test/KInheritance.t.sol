// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/KInheritance.sol";
import "forge-std/console.sol";

contract KInheritanceTest is Test {
    KInheritance public kI;
    address alice;
    address bob;
    address carol;
    uint256 timestamp;

    function setUp() public {
      kI = new KInheritance();
      alice = address(0x1);
      bob = address(0x2);
      carol = address(0x3);
      vm.deal(address(alice), 1000 ether);
      vm.deal(address(bob), 1000 ether);
      vm.deal(address(carol), 1000 ether);
      timestamp = block.timestamp;
    }

    function test_setHeir() public {
      vm.prank(address(alice));

      kI.setHeir(address(bob));
      assertEq(kI.heirOf(address(alice)), address(bob));
    }

    function test_setHeir_change() public {
      vm.startPrank(address(alice));

      kI.setHeir(address(bob));
      kI.setHeir(address(carol));
      assertEq(kI.heirOf(address(alice)), address(carol));
    }

    function test_RevertWhen_SenderIsHeir() public {
      vm.startPrank(address(alice));

      vm.expectRevert("You cannot set yourself as heir");
      kI.setHeir(address(alice));
    }

    function test_RevertWhen_SenderHasNoHeirOnDeposit() public {
      vm.prank(address(alice));

      vm.expectRevert("First set a heir");
      kI.deposit{value: 1 ether}();
    }

    function test_deposit() public {
      vm.startPrank(address(alice));

      kI.setHeir(address(bob));
      kI.deposit{value: 1 ether}();
      assertEq(kI.balanceOf(address(alice)), 1 ether);
    }

    function test_RevertWhen_DepositIsZero() public {
      vm.startPrank(address(alice));

      kI.setHeir(address(bob));
      vm.expectRevert("You cannot deposit 0 ether");
      kI.deposit{value: 0 ether}();
    }

    function test_withdraw() public {
      vm.startPrank(address(alice));

      kI.setHeir(address(bob));
      kI.deposit{value: 1 ether}();
      assertEq(address(alice).balance, 999 ether);
      kI.withdraw(1 ether);
      assertEq(kI.balanceOf(address(alice)), 0 ether);
      assertEq(address(alice).balance, 1000 ether);
    }

    function test_RevertWhen_InsufficientFunds() public {
      vm.startPrank(address(alice));

      kI.setHeir(address(bob));
      kI.deposit{value: 1 ether}();
      vm.expectRevert("Insufficient funds");
      kI.withdraw(2 ether);
    }

    function test_UpdateLastWithdrawWith0() public {
      vm.startPrank(address(alice));
      vm.warp(timestamp + 1 days);

      kI.setHeir(address(bob));
      kI.deposit{value: 1 ether}();
      kI.withdraw(0 ether);
      assertEq(kI.lastWithdraw(address(alice)), block.timestamp);
      assertEq(block.timestamp > timestamp, true);
    }

    function test_RevertWhen_TransferFundsTooSoon() public {
      vm.startPrank(address(alice));

      kI.setHeir(address(bob));
      kI.deposit{value: 1 ether}();
      vm.stopPrank();

      vm.warp(timestamp + 20 days);
      vm.startPrank(address(bob));
      vm.expectRevert("Predecessor withdrew funds recently");
      kI.transferFunds(address(alice), address(carol));
    }

    function test_RevertWhen_TransferFundsFromWrongHeir() public {
      vm.startPrank(address(alice));

      kI.setHeir(address(bob));
      kI.deposit{value: 1 ether}();
      vm.stopPrank();

      vm.startPrank(address(carol));
      vm.expectRevert("You are not the heir");
      kI.transferFunds(address(alice), address(carol));
    }

    function test_TransferFunds() public {
      vm.startPrank(address(alice));

      kI.setHeir(address(bob));
      kI.deposit{value: 1 ether}();
      vm.stopPrank();

      vm.warp(timestamp + 31 days);
      vm.startPrank(address(bob));
      kI.transferFunds(address(alice), address(carol));
      assertEq(kI.balanceOf(address(alice)), 0 ether);
      assertEq(kI.balanceOf(address(bob)), 1 ether);
      assertEq(kI.heirOf(address(alice)), address(0));
      assertEq(kI.heirOf(address(bob)), address(carol));
      assertEq(kI.lastWithdraw(address(bob)), timestamp + 31 days);
    }
}
