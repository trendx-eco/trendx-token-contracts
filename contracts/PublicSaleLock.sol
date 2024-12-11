// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract PublicSaleLock {
    using SafeMath for uint256;

    IERC20 public immutable token; // Locked Tokens
    address public beneficiary; // Beneficiary address
    uint256 public immutable totalAmount; // Total amount of locked funds
    uint256 public immutable startTime; // The start time of lock-up
    uint256 public constant TGE_DELAY = 30 days; // TGE delay time (starts after 1 month)
    uint256 public constant TGE_PERCENTAGE = 20; // TGE release percentage
    uint256 public constant RELEASE_INTERVAL = 30 days; // The time interval between each release
    uint256 public constant RELEASE_PERCENTAGE = 15; // Percentage of each release
    uint256 public constant TOTAL_PERCENTAGE = 100; //  Total Percent

    uint256 public releasedAmount; // The number of tokens released
    mapping(address => bool) public authorized; // Authorized address

    event Released(uint256 amount);
    event BeneficiaryUpdated(address newBeneficiary);
    event Authorized(address account);
    event Revoked(address account);

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
            return 0; // Locking has not started
        }

        uint256 elapsedTime = block.timestamp.sub(startTime.add(TGE_DELAY)); // Elapsed time (minus TGE delay)

        uint256 initialRelease = totalAmount.mul(TGE_PERCENTAGE).div(
            TOTAL_PERCENTAGE
        ); // Initial release 20%
        if (elapsedTime < RELEASE_INTERVAL) {
            return initialRelease; // If only the TGE delay time has passed, 20% of the initial release amount will be returned.
        }

        uint256 intervals = elapsedTime.div(RELEASE_INTERVAL); // Release cycles that have passed
        uint256 totalReleasable = totalAmount.mul(TGE_PERCENTAGE).div(
            TOTAL_PERCENTAGE
        ) +
            intervals.mul(RELEASE_PERCENTAGE).mul(totalAmount).div(
                TOTAL_PERCENTAGE
            );

        if (totalReleasable > totalAmount) {
            totalReleasable = totalAmount; // Not exceeding the total
        }

        return totalReleasable.sub(releasedAmount); // Returns the number of available releases
    }

    /**
     * @dev Withdraw available tokens
     */
    function release() external {
        require(
            authorized[msg.sender] || msg.sender == beneficiary,
            "Not authorized"
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

    /**
     * @dev Authorized address to receive tokens
     * @param _account Address to authorize
     */
    function authorize(address _account) external {
        require(msg.sender == beneficiary, "Only beneficiary can authorize");
        require(_account != address(0), "Invalid address");

        authorized[_account] = true;
        emit Authorized(_account);
    }

    /**
     * @dev Revoke authorization of an address
     * @param _account Address to revoke authorization
     */
    function revoke(address _account) external {
        require(msg.sender == beneficiary, "Only beneficiary can revoke");
        require(authorized[_account], "Address is not authorized");

        authorized[_account] = false;
        emit Revoked(_account);
    }
}
