// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Test, console} from "forge-std/Test.sol";
import "../contracts/FinanceTwoLock.sol";
import "../contracts/TTA.sol";

contract FinanceTwoLockTest is Test {
    TTA public ttaToken;
    FinanceTwoLock public lockTwo;
    address public receiver = address(0x000000000000aaaa);
    address public beneficiaryAddress = address(0x000000000000bbbb);
    uint256 public startTime = 1732982400; // 2024-12-01 00:00:00

    function setUp() public {
        ttaToken = new TTA("TTA", "TTA", receiver);
        lockTwo = new FinanceTwoLock(
            address(ttaToken),
            beneficiaryAddress,
            50_000_000 ether,
            startTime
        );
    }

    function testReleasableAmountTwo() public {
        vm.prank(receiver);
        ttaToken.transfer(address(lockTwo), 50_000_000 ether);
        vm.warp(startTime);
        uint256 relesaseNum = lockTwo.releasableAmount();
        assertEq(relesaseNum / 1e18, 5000000);
        vm.prank(beneficiaryAddress);
        lockTwo.release();
        ttaToken.balanceOf(beneficiaryAddress);
        vm.warp(startTime + 30 days);
        uint256 relesaseNum1 = lockTwo.releasableAmount();
        assertEq(relesaseNum1 / 1e18, 0);
        vm.warp(startTime + 60 days);
        uint256 relesaseNum2 = lockTwo.releasableAmount();
        assertEq(relesaseNum2 / 1e18, 0);
        vm.warp(startTime + 90 days);
        uint256 relesaseNum3 = lockTwo.releasableAmount();
        assertEq(relesaseNum3 / 1e18, 7500000);
        vm.prank(beneficiaryAddress);
        lockTwo.release();
        ttaToken.balanceOf(beneficiaryAddress);
        vm.warp(startTime + 120 days);
        uint256 relesaseNum4 = lockTwo.releasableAmount();
        assertEq(relesaseNum4 / 1e18, 0);
        vm.warp(startTime + 150 days);
        uint256 relesaseNum5 = lockTwo.releasableAmount();
        assertEq(relesaseNum5 / 1e18, 0);
    }
}
