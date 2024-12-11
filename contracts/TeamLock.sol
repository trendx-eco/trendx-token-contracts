// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TeamLock {
    using SafeMath for uint256;

    IERC20 public immutable token; // Locked Tokens
    address public beneficiary; // Beneficiary address
    uint256 public immutable totalAmount; // Total amount of locked funds
    uint256 public immutable startTime; // The start time of lock-up
    uint256 public constant TGE_DELAY = 12 * 30 days; // TGE delay period (starts after 12 months)
    uint256 public constant RELEASE_INTERVAL = 30 days; // The time interval between each release
    uint256 public constant RELEASE_PERCENTAGE = 5; // Percentage of each release
    uint256 public constant TOTAL_PERCENTAGE = 100; // Total Percent

    uint256 public releasedAmount; // The number of tokens released

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
        if (block.timestamp < startTime.add(TGE_DELAY)) {
            return 0;
        }

        uint256 elapsedTime = block.timestamp.sub(startTime.add(TGE_DELAY));

        uint256 intervals = elapsedTime.div(RELEASE_INTERVAL).add(1);
        uint256 totalReleasable = totalAmount
            .mul(intervals.mul(RELEASE_PERCENTAGE))
            .div(TOTAL_PERCENTAGE);

        if (totalReleasable > totalAmount) {
            totalReleasable = totalAmount; // 不超过总量
        }

        return totalReleasable.sub(releasedAmount);
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
