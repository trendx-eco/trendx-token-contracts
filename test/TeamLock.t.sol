// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Test, console} from "forge-std/Test.sol";
import "../contracts/TTA.sol";
import "../contracts/TeamLock.sol";

contract TeamLockTest is Test {
    TTA public ttaToken;
    TeamLock public teamLock;
    address public receiver = address(0x000000000000aaaa);
    address public beneficiaryAddress = address(0x000000000000bbbb);
    uint256 public startTime = 1732982400; // 2024-12-01 00:00:00

    function setUp() public {
        ttaToken = new TTA("TTA", "TTA", receiver);
        teamLock = new TeamLock(
            address(ttaToken),
            beneficiaryAddress,
            80_000_000 ether,
            startTime
        );
    }

    function testTeamLockRelease() public {
        vm.prank(receiver);
        ttaToken.transfer(address(teamLock), 80_000_000 ether);
        vm.warp(startTime);
        uint256 num1 = teamLock.releasableAmount();
        assertEq(num1, 0);
        for (uint256 index = 0; index < 20; index++) {
            // console.log(index);
            uint256 time = (startTime + 12 * 30 days) + index * 30 days;
            _relesaseEachMonth(time);
        }
    }

    function _relesaseEachMonth(uint256 time) internal {
        vm.warp(time);
        uint256 num = teamLock.releasableAmount();
        assertEq(num / 1e18, 4000000);
        vm.prank(beneficiaryAddress);
        teamLock.release();
    }
}
