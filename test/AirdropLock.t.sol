// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import {Test, console} from "forge-std/Test.sol";
import "../contracts/TTA.sol";
import "../contracts/AirdropLock.sol";

contract AirdropLockTest is Test {
    TTA public ttaToken;
    AirdropLock public airdropLock;
    address public receiver = address(0x000000000000aaaa);
    address public beneficiaryAddress = address(0x000000000000bbbb);
    uint256 public startTime = 1732982400; // 2024-12-01 00:00:00

    function setUp() public {
        ttaToken = new TTA("TTA", "TTA", receiver);
        airdropLock = new AirdropLock(
            address(ttaToken),
            beneficiaryAddress,
            40_000_000 ether,
            startTime
        );
    }

    function testAirdropLockRelease() public {
        vm.prank(receiver);
        ttaToken.transfer(address(airdropLock), 40_000_000 ether);
        for (uint256 index = 0; index < 13; index++) {
            console.log(index);
            airdropLock.releasableAmount();

            vm.warp(startTime + (index * 30 days));
            uint256 num1 = airdropLock.releasableAmount();
            airdropLock.releasedAmount();
            if (index <= 3) {
                assertEq(num1 / 1e18, 5000000);
            } else if (index == 4) {
                assertEq(num1 / 1e18, 6668000);
            } else {
                assertEq(num1 / 1e18, 1664000);
            }

            if (num1 > 0) {
                vm.prank(beneficiaryAddress);
                airdropLock.release();
            }
        }
    }
}
