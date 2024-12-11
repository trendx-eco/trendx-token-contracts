// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Test, console} from "forge-std/Test.sol";
import "../contracts/TTA.sol";
import "../contracts/StakingRewardsLock.sol";

contract StakingRewardsLockTest is Test {
    TTA public ttaToken;
    StakingRewardsLock public srLock;
    address public receiver = address(0x000000000000aaaa);
    address public beneficiaryAddress = address(0x000000000000bbbb);
    uint256 public startTime = 1732982400; // 2024-12-01 00:00:00

    function setUp() public {
        ttaToken = new TTA("TTA", "TTA", receiver);
        srLock = new StakingRewardsLock(
            address(ttaToken),
            beneficiaryAddress,
            200_000_000 ether,
            startTime
        );
    }

    function testSRLockRelease() public {
        vm.prank(receiver);
        ttaToken.transfer(address(srLock), 200_000_000 ether);
        for (uint256 index = 0; index < 96; index++) {
            vm.warp(startTime + (index * 30 days));
            uint256 num1 = srLock.releasableAmount();
            if (index == 0) {
                assertEq(num1 / 1e18, 0);
            } else {
                assertEq(num1 / 1e18, 2083333);
            }
            if (num1 > 0) {
                vm.prank(beneficiaryAddress);
                srLock.release();
            }
        }
    }
}
