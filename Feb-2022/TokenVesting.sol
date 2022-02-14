// SPDX-License-Identifier: None

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

/**
 * @title Token Vesting
 * @author Varun Patel, BlueHandCoding
 * @notice Created with help from the OpenZeppelin Github repository and other reading material.
 * @dev This contract utilizes a linear vesting curve.
 */
contract TokenVesting {
    event TokenReleased(address token, uint256 amount);

    mapping (address => uint256) private releasedTokens;
    address private recipient;
    uint64 private cliff;
    uint64 private start;
    uint64 private duration;

    /**
     * @dev This sets the recpient, cliff period, duration, and the start timestamp.
     * The cliff and duration are all set in seconds.
     */
    constructor(address _recipientAddress, uint64 _cliff, uint64 _start, uint64 _duration){
        require(_recipientAddress != address(0));
        require(_cliff < _duration);

        recipient = _recipientAddress;
        cliff = _cliff;
        start = _start;
        duration = _duration;
    }

    /**
     * @dev Getter for the recipient.
     */
    function seeRecipient() public view returns (address) {
        return recipient;
    }

    /**
     * @dev Determines if the cliff period is still active.
     */
    function cliffPeriodActive() private view returns (bool) {
        return (start + cliff) < block.timestamp;
    }

    /**
     * @dev See the amount of token released.
     */
    function releasedTokenValue(address token) private view returns (uint256) {
        return releasedTokens[token];
    }

    /**
     * @dev Releases vested tokens in accordance with the vesting schedule.
     *
     * Will emit a {TokenReleased} event.
     */
    function release(address token) public {
        uint256 releasable = releasableToken(token) - releasedTokenValue(token);
        releasedTokens[token] += releasable;
        emit TokenReleased(token, releasable);
        SafeERC20.safeTransfer(IERC20(token), recipient, releasable);
    }

    function releasableToken(address token) public view returns (uint256) {
        return vestingPeriod(IERC20(token).balanceOf(address(this)) + releasedTokens[token]);
    }

    function vestingPeriod(uint256 allocation) internal view returns (uint256) {
        if (cliffPeriodActive() || block.timestamp < start) {
            return 0;
        } else if (block.timestamp > (start + cliff + duration)) {
            return allocation;
        } else {
            return (allocation * (block.timestamp - start) / duration);
        }
    }
}
