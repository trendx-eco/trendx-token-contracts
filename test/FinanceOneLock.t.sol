// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Test, console} from "forge-std/Test.sol";
import "../contracts/FinanceOneLock.sol";
import "../contracts/TTA.sol";

contract FinanceOneLockTest is Test {
    TTA public ttaToken;
    FinanceOneLock public lockOne;
    address public receiver = address(0x000000000000aaaa);
    address public beneficiaryAddress = address(0x000000000000bbbb);
    uint256 public startTime = 1732982400; // 2024-12-01 00:00:00

    function setUp() public {
        ttaToken = new TTA("TTA", "TTA", receiver);
        lockOne = new FinanceOneLock(
            address(ttaToken),
            beneficiaryAddress,
            30_000_000 ether,
            startTime
        );
    }

    function testReleasableAmount() public {
        vm.prank(receiver);
        ttaToken.transfer(address(lockOne), 30_000_000 ether);
        vm.warp(startTime);
        uint256 relesaseNum = lockOne.releasableAmount();
        assertEq(relesaseNum / 1e18, 1500000);
        vm.prank(beneficiaryAddress);
        lockOne.release();
        ttaToken.balanceOf(beneficiaryAddress);
        vm.warp(startTime + 30 days);
        uint256 relesaseNum1 = lockOne.releasableAmount();
        assertEq(relesaseNum1 / 1e18, 0);
        vm.warp(startTime + 60 days);
        uint256 relesaseNum2 = lockOne.releasableAmount();
        assertEq(relesaseNum2 / 1e18, 0);
        vm.warp(startTime + 90 days);
        uint256 relesaseNum3 = lockOne.releasableAmount();
        assertEq(relesaseNum3 / 1e18, 4750000);
        vm.prank(beneficiaryAddress);
        lockOne.release();
        ttaToken.balanceOf(beneficiaryAddress);
        vm.warp(startTime + 120 days);
        uint256 relesaseNum4 = lockOne.releasableAmount();
        assertEq(relesaseNum4 / 1e18, 0);
        vm.warp(startTime + 150 days);
        uint256 relesaseNum5 = lockOne.releasableAmount();
        assertEq(relesaseNum5 / 1e18, 0);
    }
}
