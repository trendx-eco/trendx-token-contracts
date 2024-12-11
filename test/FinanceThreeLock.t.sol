// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Test, console} from "forge-std/Test.sol";
import "../contracts/FinanceThreeLock.sol";
import "../contracts/TTA.sol";

contract FinanceThreeLockTest is Test {
    TTA public ttaToken;
    FinanceThreeLock public lockThree;
    address public receiver = address(0x000000000000aaaa);
    address public beneficiaryAddress = address(0x000000000000bbbb);
    uint256 public startTime = 1732982400; // 2024-12-01 00:00:00

    function setUp() public {
        ttaToken = new TTA("TTA", "TTA", receiver);
        lockThree = new FinanceThreeLock(
            address(ttaToken),
            beneficiaryAddress,
            115_000_000 ether,
            startTime
        );
    }

    function testReleasableAmountThree() public {
        vm.prank(receiver);
        ttaToken.transfer(address(lockThree), 115_000_000 ether);
        vm.warp(startTime);
        uint256 relesaseNum = lockThree.releasableAmount();
        assertEq(relesaseNum / 1e18, 0);
        ttaToken.balanceOf(beneficiaryAddress);
        vm.warp(startTime + 180 days);
        uint256 relesaseNum1 = lockThree.releasableAmount();
        assertEq(relesaseNum1 / 1e18, 11500000);
        vm.prank(beneficiaryAddress);
        lockThree.release();
        vm.warp(startTime + 270 days);
        uint256 relesaseNum3 = lockThree.releasableAmount();
        assertEq(relesaseNum3 / 1e18, 12937500);
        vm.prank(beneficiaryAddress);
        lockThree.release();
        ttaToken.balanceOf(beneficiaryAddress);
    }
}
