// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Test, console} from "forge-std/Test.sol";
import "../contracts/TTA.sol";
import "../contracts/PublicSaleLock.sol";

contract PublicSaleLockTest is Test {
    TTA public ttaToken;
    PublicSaleLock public saleLock;
    address public receiver = address(0x000000000000aaaa);
    address public beneficiaryAddress = address(0x000000000000bbbb);
    uint256 public startTime = 1732982400; // 2024-12-01 00:00:00

    function setUp() public {
        ttaToken = new TTA("TTA", "TTA", receiver);
        saleLock = new PublicSaleLock(
            address(ttaToken),
            beneficiaryAddress,
            25_000_000 ether,
            startTime
        );
    }

    function testPublicSaleRelease() public {
        vm.prank(receiver);
        ttaToken.transfer(address(saleLock), 25_000_000 ether);
        vm.warp(startTime);
        uint256 num1 = saleLock.releasableAmount();
        assertEq(num1, 0);
        vm.warp(startTime + 30 days);
        uint256 num2 = saleLock.releasableAmount();
        assertEq(num2 / 1e18, 5000000);
        vm.prank(beneficiaryAddress);
        saleLock.release();

        vm.warp(startTime + 60 days);
        uint256 num3 = saleLock.releasableAmount();
        assertEq(num3 / 1e18, 3750000);
        vm.prank(beneficiaryAddress);
        saleLock.release();

        vm.warp(startTime + 90 days);
        uint256 num4 = saleLock.releasableAmount();
        assertEq(num4 / 1e18, 3750000);
        vm.prank(beneficiaryAddress);
        saleLock.release();

        vm.warp(startTime + 120 days);
        uint256 num5 = saleLock.releasableAmount();
        assertEq(num5 / 1e18, 3750000);
        vm.prank(beneficiaryAddress);
        saleLock.release();

        vm.warp(startTime + 150 days);
        uint256 num6 = saleLock.releasableAmount();
        assertEq(num6 / 1e18, 3750000);
        vm.prank(beneficiaryAddress);
        saleLock.release();

        vm.warp(startTime + 180 days);
        uint256 num7 = saleLock.releasableAmount();
        assertEq(num7 / 1e18, 3750000);
        vm.prank(beneficiaryAddress);
        saleLock.release();

        vm.warp(startTime + 210 days);
        uint256 num8 = saleLock.releasableAmount();
        assertEq(num8 / 1e18, 1250000);
        vm.prank(beneficiaryAddress);
        saleLock.release();

        vm.warp(startTime + 240 days);
        uint256 num9 = saleLock.releasableAmount();
        assertEq(num9 / 1e18, 0);
    }
}
