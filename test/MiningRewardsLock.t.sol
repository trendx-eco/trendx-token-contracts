// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Test, console} from "forge-std/Test.sol";
import "../contracts/TTA.sol";
import "../contracts/MiningRewardsLock.sol";

contract MiningRewardsLockTest is Test {
    TTA public ttaToken;
    MiningRewardsLock public mrLock;
    address public receiver = address(0x000000000000aaaa);
    address public beneficiaryAddress = address(0x000000000000bbbb);
    uint256 public startTime = 1732982400; // 2024-12-01 00:00:00

    function setUp() public {
        ttaToken = new TTA("TTA", "TTA", receiver);
        mrLock = new MiningRewardsLock(
            address(ttaToken),
            beneficiaryAddress,
            400_000_000 ether,
            startTime
        );
    }

    function testMiningRewardsRelease() public {
        vm.prank(receiver);
        ttaToken.transfer(address(mrLock), 400_000_000 ether);
        vm.warp(startTime);
        uint256 num = mrLock.releasableAmount();
        assertEq(num, 0);
        vm.warp(startTime + 30 days);
        uint256 num1 = mrLock.releasableAmount();
        assertEq(num1 / 1e18, 16666666);

        vm.warp(startTime + (12 * 30 days));
        vm.prank(beneficiaryAddress);
        mrLock.release();
        vm.warp(startTime + (13 * 30 days));

        uint256 num2 = mrLock.releasableAmount();
        assertEq(num2 / 1e18, 8333333);

        vm.warp(startTime + (24 * 30 days));
        vm.prank(beneficiaryAddress);
        mrLock.release();
        vm.warp(startTime + (25 * 30 days));

        uint256 num3 = mrLock.releasableAmount();
        assertEq(num3 / 1e18, 4166666);

        vm.warp(startTime + (36 * 30 days));
        vm.prank(beneficiaryAddress);
        mrLock.release();
        vm.warp(startTime + (37 * 30 days));

        uint256 num4 = mrLock.releasableAmount();
        assertEq(num4 / 1e18, 2083333);
    }
}
