// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @title ChainGive
 * @notice 블록체인 기반 투명한 기부 및 자금 추적 플랫폼
 * @dev 에스크로 + DAO 투표 + 마일스톤 기반 자금 집행
 */
contract ChainGive is Ownable, ReentrancyGuard {

    // ─────────────────────────────────────────────
    //  데이터 구조
    // ─────────────────────────────────────────────

    enum MilestoneStatus { Pending, Voting, Approved, Rejected, Released }

    struct Milestone {
        string  description;   // 마일스톤 설명
        uint256 amount;        // 집행 금액 (wei)
        MilestoneStatus status;
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 votingDeadline;
    }

    struct Campaign {
        address payable creator;      // 캠페인 생성자 (수혜자)
        string  title;
        string  description;
        string  ipfsMetadataCID;      // IPFS 메타데이터 CID
        uint256 goalAmount;           // 목표 금액 (wei)
        uint256 raisedAmount;         // 모금된 금액
        uint256 deadline;             // 모금 마감일
        bool    active;
        Milestone[] milestones;
    }

    // ─────────────────────────────────────────────
    //  상태 변수
    // ─────────────────────────────────────────────

    uint256 public campaignCount;

    // campaignId → Campaign
    mapping(uint256 => Campaign) public campaigns;

    // campaignId → donorAddress → donatedAmount
    mapping(uint256 => mapping(address => uint256)) public donations;

    // campaignId → milestoneIndex → voterAddress → voted?
    mapping(uint256 => mapping(uint256 => mapping(address => bool))) public hasVoted;

    // ─────────────────────────────────────────────
    //  이벤트 (온체인 추적용)
    // ─────────────────────────────────────────────

    event CampaignCreated(uint256 indexed campaignId, address indexed creator, string title, uint256 goal);
    event DonationReceived(uint256 indexed campaignId, address indexed donor, uint256 amount);
    event MilestoneVotingStarted(uint256 indexed campaignId, uint256 milestoneIndex, uint256 deadline);
    event VoteCast(uint256 indexed campaignId, uint256 milestoneIndex, address indexed voter, bool support, uint256 weight);
    event MilestoneApproved(uint256 indexed campaignId, uint256 milestoneIndex);
    event MilestoneRejected(uint256 indexed campaignId, uint256 milestoneIndex);
    event FundsReleased(uint256 indexed campaignId, uint256 milestoneIndex, address indexed recipient, uint256 amount);
    event RefundIssued(uint256 indexed campaignId, address indexed donor, uint256 amount);

    // ─────────────────────────────────────────────
    //  수정자
    // ─────────────────────────────────────────────

    modifier campaignExists(uint256 _id) {
        require(_id < campaignCount, "Campaign does not exist");
        _;
    }

    modifier onlyCampaignCreator(uint256 _id) {
        require(msg.sender == campaigns[_id].creator, "Not campaign creator");
        _;
    }

    // ─────────────────────────────────────────────
    //  캠페인 생성
    // ─────────────────────────────────────────────

    constructor() Ownable(msg.sender) {}

    /**
     * @notice 새 기부 캠페인을 생성합니다.
     * @param _title 캠페인 제목
     * @param _description 캠페인 설명
     * @param _ipfsCID IPFS 메타데이터 CID
     * @param _goalAmount 목표 모금액 (wei)
     * @param _durationDays 모금 기간 (일)
     * @param _milestoneDescriptions 마일스톤 설명 배열
     * @param _milestoneAmounts 마일스톤 집행 금액 배열 (wei)
     */
    function createCampaign(
        string  memory _title,
        string  memory _description,
        string  memory _ipfsCID,
        uint256 _goalAmount,
        uint256 _durationDays,
        string[] memory _milestoneDescriptions,
        uint256[] memory _milestoneAmounts
    ) external {
        require(_goalAmount > 0, "Goal must be > 0");
        require(_durationDays > 0 && _durationDays <= 365, "Invalid duration");
        require(_milestoneDescriptions.length == _milestoneAmounts.length, "Milestone mismatch");
        require(_milestoneDescriptions.length > 0, "Need at least one milestone");

        // 마일스톤 합계 검증
        uint256 total;
        for (uint i = 0; i < _milestoneAmounts.length; i++) {
            total += _milestoneAmounts[i];
        }
        require(total == _goalAmount, "Milestone amounts must sum to goal");

        uint256 id = campaignCount++;
        Campaign storage c = campaigns[id];
        c.creator      = payable(msg.sender);
        c.title        = _title;
        c.description  = _description;
        c.ipfsMetadataCID = _ipfsCID;
        c.goalAmount   = _goalAmount;
        c.deadline     = block.timestamp + (_durationDays * 1 days);
        c.active       = true;

        for (uint i = 0; i < _milestoneDescriptions.length; i++) {
            c.milestones.push(Milestone({
                description:    _milestoneDescriptions[i],
                amount:         _milestoneAmounts[i],
                status:         MilestoneStatus.Pending,
                votesFor:       0,
                votesAgainst:   0,
                votingDeadline: 0
            }));
        }

        emit CampaignCreated(id, msg.sender, _title, _goalAmount);
    }

    // ─────────────────────────────────────────────
    //  기부
    // ─────────────────────────────────────────────

    /**
     * @notice 캠페인에 ETH를 기부합니다. 기부금은 컨트랙트(에스크로)에 보관됩니다.
     */
    function donate(uint256 _campaignId) external payable campaignExists(_campaignId) nonReentrant {
        Campaign storage c = campaigns[_campaignId];
        require(c.active, "Campaign is not active");
        require(block.timestamp < c.deadline, "Campaign has ended");
        require(msg.value > 0, "Donation must be > 0");

        donations[_campaignId][msg.sender] += msg.value;
        c.raisedAmount += msg.value;

        emit DonationReceived(_campaignId, msg.sender, msg.value);
    }

    // ─────────────────────────────────────────────
    //  DAO 투표
    // ─────────────────────────────────────────────

    /**
     * @notice 마일스톤 투표를 시작합니다 (캠페인 생성자만 호출 가능).
     * @param _votingDays 투표 기간 (일)
     */
    function startMilestoneVoting(
        uint256 _campaignId,
        uint256 _milestoneIndex,
        uint256 _votingDays
    ) external campaignExists(_campaignId) onlyCampaignCreator(_campaignId) {
        Campaign storage c = campaigns[_campaignId];
        Milestone storage m = c.milestones[_milestoneIndex];

        require(m.status == MilestoneStatus.Pending, "Not in pending state");
        require(_votingDays >= 1 && _votingDays <= 14, "Invalid voting period");

        m.status = MilestoneStatus.Voting;
        m.votingDeadline = block.timestamp + (_votingDays * 1 days);

        emit MilestoneVotingStarted(_campaignId, _milestoneIndex, m.votingDeadline);
    }

    /**
     * @notice 마일스톤 투표에 참여합니다. 의결권 = 기부금액 (토큰 가중 투표).
     * @param _support true = 찬성, false = 반대
     */
    function vote(
        uint256 _campaignId,
        uint256 _milestoneIndex,
        bool _support
    ) external campaignExists(_campaignId) {
        Campaign storage c = campaigns[_campaignId];
        Milestone storage m = c.milestones[_milestoneIndex];

        require(m.status == MilestoneStatus.Voting, "Not in voting phase");
        require(block.timestamp <= m.votingDeadline, "Voting has ended");

        uint256 weight = donations[_campaignId][msg.sender];
        require(weight > 0, "No voting power: you have not donated");
        require(!hasVoted[_campaignId][_milestoneIndex][msg.sender], "Already voted");

        hasVoted[_campaignId][_milestoneIndex][msg.sender] = true;

        if (_support) {
            m.votesFor += weight;
        } else {
            m.votesAgainst += weight;
        }

        emit VoteCast(_campaignId, _milestoneIndex, msg.sender, _support, weight);
    }

    /**
     * @notice 투표 종료 후 결과를 집계하고 자금을 집행합니다.
     */
    function finalizeVote(
        uint256 _campaignId,
        uint256 _milestoneIndex
    ) external campaignExists(_campaignId) nonReentrant {
        Campaign storage c = campaigns[_campaignId];
        Milestone storage m = c.milestones[_milestoneIndex];

        require(m.status == MilestoneStatus.Voting, "Not in voting phase");
        require(block.timestamp > m.votingDeadline, "Voting period not over");

        if (m.votesFor > m.votesAgainst) {
            m.status = MilestoneStatus.Approved;
            emit MilestoneApproved(_campaignId, _milestoneIndex);

            // 자금 집행
            uint256 releaseAmount = m.amount;
            m.status = MilestoneStatus.Released;
            c.creator.transfer(releaseAmount);

            emit FundsReleased(_campaignId, _milestoneIndex, c.creator, releaseAmount);
        } else {
            m.status = MilestoneStatus.Rejected;
            emit MilestoneRejected(_campaignId, _milestoneIndex);
        }
    }

    // ─────────────────────────────────────────────
    //  환불 (캠페인 실패 시)
    // ─────────────────────────────────────────────

    /**
     * @notice 목표 미달 또는 캠페인 종료 시 기부금 환불.
     */
    function refund(uint256 _campaignId) external campaignExists(_campaignId) nonReentrant {
        Campaign storage c = campaigns[_campaignId];
        require(block.timestamp > c.deadline, "Campaign still active");
        require(c.raisedAmount < c.goalAmount, "Goal was reached; no refund");

        uint256 amount = donations[_campaignId][msg.sender];
        require(amount > 0, "Nothing to refund");

        donations[_campaignId][msg.sender] = 0;
        payable(msg.sender).transfer(amount);

        emit RefundIssued(_campaignId, msg.sender, amount);
    }

    // ─────────────────────────────────────────────
    //  조회 함수
    // ─────────────────────────────────────────────

    function getMilestoneCount(uint256 _campaignId) external view returns (uint256) {
        return campaigns[_campaignId].milestones.length;
    }

    function getMilestone(uint256 _campaignId, uint256 _index)
        external view returns (Milestone memory)
    {
        return campaigns[_campaignId].milestones[_index];
    }

    function getDonation(uint256 _campaignId, address _donor) external view returns (uint256) {
        return donations[_campaignId][_donor];
    }
}
