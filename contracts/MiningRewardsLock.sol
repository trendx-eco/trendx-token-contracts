// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MiningRewardsLock {
    using SafeMath for uint256;

    IERC20 public immutable token; // Locked Tokens
    address public beneficiary; // Beneficiary address
    uint256 public immutable totalAmount; // Total amount of locked funds
    uint256 public immutable startTime; // The start time of lock-up
    uint256 public constant RELEASE_INTERVAL = 30 days; // The time interval between each release (1 month)
    uint256 public releasedAmount; // Released quantity
    uint256 public constant INITIAL_YEARLY_RELEASE = 200_000_000 * (10 ** 18); // Total release in the first year
    uint256 public constant TOTAL_YEARS = 20; // 20 years in total
    uint256 public constant MONTHS_IN_A_YEAR = 12; // 12 months per year

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

        uint256 elapsedTime = block.timestamp.sub(startTime); // Elapsed time from start
        uint256 elapsedMonths = elapsedTime / 30 days; // Calculate the number of months that have passed
        uint256 elapsedYears = elapsedMonths / MONTHS_IN_A_YEAR; // Calculate the years that have passed

        if (elapsedYears >= TOTAL_YEARS) {
            elapsedYears = TOTAL_YEARS - 1; // Up to 20 years
        }

        uint256 totalReleasable = 0;
        uint256 yearlyReleaseAmount = INITIAL_YEARLY_RELEASE;

        // Calculate the number of releases per year
        for (uint256 i = 0; i <= elapsedYears; i++) {
            uint256 yearlyRelease = yearlyReleaseAmount.div(MONTHS_IN_A_YEAR);
            if (elapsedMonths >= (i + 1) * MONTHS_IN_A_YEAR) {
                totalReleasable = totalReleasable.add(
                    yearlyRelease.mul(MONTHS_IN_A_YEAR)
                );
            } else {
                uint256 remainingMonths = elapsedMonths - i * MONTHS_IN_A_YEAR;
                totalReleasable = totalReleasable.add(
                    yearlyRelease.mul(remainingMonths)
                );
            }
            yearlyReleaseAmount = yearlyReleaseAmount.div(2); // 50% reduction in production each year
        }

        uint256 unreleasedAmount = totalReleasable.sub(releasedAmount);
        return unreleasedAmount > totalAmount ? totalAmount : unreleasedAmount; // Make sure the total amount is not exceeded
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
