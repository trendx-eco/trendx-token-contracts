// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract FinanceTwoLock {
    using SafeMath for uint256;

    IERC20 public immutable token; // Locked Tokens
    address public beneficiary; // Beneficiary address
    uint256 public immutable totalAmount; // Total amount of locked funds
    uint256 public immutable startTime; // The start time of lock-up
    uint256 public constant TGE_PERCENTAGE = 10; // TGE release percentage
    uint256 public constant RELEASE_INTERVAL = 90 days; // The time interval between each release
    uint256 public constant RELEASE_DURATION = 18 * 30 days; // Total release time
    uint256 public constant TOTAL_PERCENTAGE = 100; // Total Percent

    uint256 public releasedAmount; //  The number of tokens released

    event Released(uint256 amount);
    event BeneficiaryUpdated(address newBeneficiary);

    /**
     * @dev Constructor
     * @param _token The contract address of the locked tokens
     * @param _beneficiary Beneficiary address
     * @param _totalAmount Total locked amount
     * @param _startTime Lock-up start time (TGE time)
     */
    constructor(
        address _token,
        address _beneficiary,
        uint256 _totalAmount,
        uint256 _startTime
    ) {
        require(_token != address(0), "Invalid token address");
        require(_beneficiary != address(0), "Invalid beneficiary address");
        require(_totalAmount > 0, "Total amount must be greater than 0");

        token = IERC20(_token);
        beneficiary = _beneficiary;
        totalAmount = _totalAmount;
        startTime = _startTime;
    }

    /**
     * @dev Get the current number of tokens available
     */
    function releasableAmount() public view returns (uint256) {
        if (block.timestamp < startTime) {
            return 0; // Locking has not started
        }

        uint256 elapsedTime = block.timestamp.sub(startTime);

        if (elapsedTime >= RELEASE_DURATION) {
            // The lock-up period ends and all positions are released
            return totalAmount.sub(releasedAmount);
        }

        // Calculate the total releasable amount
        uint256 totalReleasable = totalAmount.mul(TGE_PERCENTAGE).div(
            TOTAL_PERCENTAGE
        ); // TGE release
        uint256 intervals = elapsedTime.div(RELEASE_INTERVAL); // 已经经过的释放周期数
        uint256 remainingPercentage = TOTAL_PERCENTAGE.sub(TGE_PERCENTAGE);
        uint256 periodicRelease = totalAmount
            .mul(remainingPercentage)
            .div(TOTAL_PERCENTAGE)
            .div(RELEASE_DURATION.div(RELEASE_INTERVAL));
        totalReleasable = totalReleasable.add(intervals.mul(periodicRelease));

        if (totalReleasable > totalAmount) {
            totalReleasable = totalAmount;
        }

        return totalReleasable.sub(releasedAmount);
    }

    /**
     * @dev  Withdraw available tokens
     */
    function release() external {
        require(
            msg.sender == beneficiary,
            "Only beneficiary can release tokens"
        );
        uint256 amount = releasableAmount();
        require(amount > 0, "No tokens available for release");

        releasedAmount = releasedAmount.add(amount);
        token.transfer(beneficiary, amount);

        emit Released(amount);
    }

    /**
     * @dev Update beneficiary address
     * @param _newBeneficiary New beneficiary address
     */
    function updateBeneficiary(address _newBeneficiary) external {
        require(msg.sender == beneficiary, "Only beneficiary can update");
        require(_newBeneficiary != address(0), "Invalid beneficiary address");

        beneficiary = _newBeneficiary;
        emit BeneficiaryUpdated(_newBeneficiary);
    }
}
