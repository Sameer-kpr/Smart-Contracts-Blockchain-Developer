 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract PlayGame is ReentrancyGuard {
    IERC20 public gt;
    address public owner;
    uint256 public matchCounter;
    uint256 public timeoutSeconds = 24 hours;

    enum Status { NONE, CREATED, STAKED, SETTLED, REFUNDED }

    struct Match {
        address player1;
        address player2;
        uint256 stake; // stake per player (GT decimals)
        Status status;
        bool p1Staked;
        bool p2Staked;
        uint256 createdAt;
    }

    mapping(uint256 => Match) public matches;

    event MatchCreated(uint256 indexed id, address p1, address p2, uint256 stake);
    event Staked(uint256 indexed id, address player);
    event Settled(uint256 indexed id, address winner, uint256 amount);
    event Refunded(uint256 indexed id);

    modifier onlyOwner() {
        require(msg.sender == owner, "only owner");
        _;
    }

    constructor(address _gt) {
        gt = IERC20(_gt);
        owner = msg.sender;
    }

    function createMatch(address p1, address p2, uint256 stake) external returns (uint256) {
        require(p1 != address(0) && p2 != address(0) && stake > 0, "invalid");
        matchCounter++;
        matches[matchCounter] = Match({
            player1: p1,
            player2: p2,
            stake: stake,
            status: Status.CREATED,
            p1Staked: false,
            p2Staked: false,
            createdAt: block.timestamp
        });
        emit MatchCreated(matchCounter, p1, p2, stake);
        return matchCounter;
    }

    /// Player calls stakeMatch for their matchId after approving GT to this contract
    function stakeMatch(uint256 matchId) external nonReentrant {
        Match storage m = matches[matchId];
        require(m.status == Status.CREATED || m.status == Status.CREATED, "not creatable");
        require(msg.sender == m.player1 || msg.sender == m.player2, "not a player");

        // transfer GT from player
        require(gt.transferFrom(msg.sender, address(this), m.stake), "gt transfer failed");

        if (msg.sender == m.player1) {
            m.p1Staked = true;
        } else if (msg.sender == m.player2) {
            m.p2Staked = true;
        }

        emit Staked(matchId, msg.sender);

        if (m.p1Staked && m.p2Staked) {
            m.status = Status.STAKED;
        }
    }

    /// Commit result, only operator or one of the players can call. Winner receives 2x stake.
    function commitResult(uint256 matchId, address winner) external nonReentrant {
        Match storage m = matches[matchId];
        require(m.status == Status.STAKED, "not staked");
        require(winner == m.player1 || winner == m.player2, "invalid winner");

        uint256 payout = m.stake * 2;
        m.status = Status.SETTLED;

        // transfer payout
        require(gt.transfer(winner, payout), "payout failed");

        emit Settled(matchId, winner, payout);
    }

    /// Refund if timeout passed and not settled
    function refund(uint256 matchId) external nonReentrant {
        Match storage m = matches[matchId];
        require(m.status == Status.CREATED || m.status == Status.STAKED, "cannot refund");
        require(block.timestamp >= m.createdAt + timeoutSeconds, "too early");

        // return stakes to whoever staked
        if (m.p1Staked) {
            require(gt.transfer(m.player1, m.stake), "refund p1 failed");
        }
        if (m.p2Staked) {
            require(gt.transfer(m.player2, m.stake), "refund p2 failed");
        }
        m.status = Status.REFUNDED;
        emit Refunded(matchId);
    }

    // owner helpers
    function setTimeout(uint256 seconds_) external onlyOwner {
        timeoutSeconds = seconds_;
    }
}
