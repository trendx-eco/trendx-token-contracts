// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract AirdropLock {
    using SafeMath for uint256;

    IERC20 public immutable token; // Locked Tokens
    address public beneficiary; // Beneficiary address
    uint256 public immutable totalAmount; // Total locked amount
    uint256 public immutable startTime; // Lock-up start time (TGE time)

    // When using integers to represent percentages, divide by 100 to get the correct ratio.
    uint256 public constant TGE_RELEASE_PERCENTAGE = 1250; // 12.5% * 100
    uint256 public constant FIRST_3_MONTHS_RELEASE_PERCENTAGE = 1250; // 12.5% * 100
    uint256 public constant FOURTH_MONTH_RELEASE_PERCENTAGE = 1667; // 16.67% * 100
    uint256 public constant REMAINING_MONTHS_RELEASE_PERCENTAGE = 416; // 4.16% * 100

    uint256 public releasedAmount; // Released quantity

    uint256 public constant RELEASE_INTERVAL = 30 days; // The time interval between each release (1 month)
    uint256 public constant TOTAL_RELEASES = 12; // Total release times (12 months)

    event Released(uint256 amount);
    event BeneficiaryUpdated(address newBeneficiary);

    /**
     * @dev Constructor
     * @param _token The address of locked tokens
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
     * @dev Calculate the current number of tokens that can be released
     */
    function releasableAmount() public view returns (uint256) {
        if (block.timestamp < startTime) {
            return 0; // Locking has not started
        }

        uint256 elapsedTime = block.timestamp.sub(startTime); // Elapsed time from start
        uint256 elapsedMonths = elapsedTime / 30 days; // Months that have passed

        uint256 totalReleasable = 0;

        // TGE release phase: 12.5%
        if (elapsedMonths >= 0) {
            totalReleasable = totalAmount.mul(TGE_RELEASE_PERCENTAGE).div(
                10000
            ); // Divide by 1000 to get the correct scale
        }

        // First 3 months: 12.5% ​​released every month
        if (elapsedMonths >= 1) {
            uint256 em = 0;
            if (elapsedMonths <= 3) {
                em = elapsedMonths;
            } else {
                em = 3;
            }
            uint256 first3MonthsRelease = totalAmount
                .mul(FIRST_3_MONTHS_RELEASE_PERCENTAGE)
                .div(10000); // Divide by 1000 to get the correct scale
            totalReleasable = totalReleasable.add(first3MonthsRelease.mul(em));
        }

        // 第4个月：16.67%
        if (elapsedMonths >= 4) {
            uint256 fourthMonthRelease = totalAmount
                .mul(FOURTH_MONTH_RELEASE_PERCENTAGE)
                .div(10000); // Divide by 1000 to get the correct scale
            totalReleasable = totalReleasable.add(fourthMonthRelease);
        }

        // Remaining 8 months: 4.16% per month
        if (elapsedMonths >= 5) {
            uint256 remainingRelease = totalAmount
                .mul(REMAINING_MONTHS_RELEASE_PERCENTAGE)
                .div(10000); // Divide by 1000 to get the correct scale
            totalReleasable = totalReleasable.add(
                remainingRelease.mul(elapsedMonths - 4)
            );
        }

        // Make sure the total locked amount is not exceeded
        if (totalReleasable > totalAmount) {
            totalReleasable = totalAmount;
        }

        return totalReleasable.sub(releasedAmount); // Returns the remaining freeable amount
    }

    /**
     * @dev Withdraw available tokens
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
