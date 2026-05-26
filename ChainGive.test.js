const { expect } = require("chai");
const { ethers } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

describe("ChainGive", function () {
  let chainGive, owner, creator, donor1, donor2;

  const GOAL   = ethers.parseEther("1.0");
  const M1_AMT = ethers.parseEther("0.4");
  const M2_AMT = ethers.parseEther("0.4");
  const M3_AMT = ethers.parseEther("0.2");

  beforeEach(async () => {
    [owner, creator, donor1, donor2] = await ethers.getSigners();
    const Factory = await ethers.getContractFactory("ChainGive");
    chainGive = await Factory.deploy();

    // 캠페인 생성
    await chainGive.connect(creator).createCampaign(
      "테스트 캠페인",
      "테스트 설명",
      "QmTestCID",
      GOAL,
      30,
      ["Phase 1", "Phase 2", "Phase 3"],
      [M1_AMT, M2_AMT, M3_AMT]
    );
  });

  // ── 기부 ──────────────────────────────────────────────────────────────
  describe("기부 (Donate)", () => {
    it("ETH 기부가 기록되어야 한다", async () => {
      await chainGive.connect(donor1).donate(0, { value: ethers.parseEther("0.5") });
      expect(await chainGive.getDonation(0, donor1.address))
        .to.equal(ethers.parseEther("0.5"));
    });

    it("마감 후 기부는 실패해야 한다", async () => {
      await time.increase(31 * 24 * 60 * 60);
      await expect(
        chainGive.connect(donor1).donate(0, { value: ethers.parseEther("0.1") })
      ).to.be.revertedWith("Campaign has ended");
    });
  });

  // ── DAO 투표 ──────────────────────────────────────────────────────────
  describe("DAO 투표 (Voting)", () => {
    beforeEach(async () => {
      // donor1: 0.6 ETH, donor2: 0.4 ETH 기부
      await chainGive.connect(donor1).donate(0, { value: ethers.parseEther("0.6") });
      await chainGive.connect(donor2).donate(0, { value: ethers.parseEther("0.4") });
    });

    it("투표 가결 시 자금이 수혜자에게 전달되어야 한다", async () => {
      // 투표 시작
      await chainGive.connect(creator).startMilestoneVoting(0, 0, 3);

      // 기부 금액 기준 의결권: donor1(0.6) > donor2(0.4) → 가결
      await chainGive.connect(donor1).vote(0, 0, true);
      await chainGive.connect(donor2).vote(0, 0, false);

      // 투표 종료 후 집계
      await time.increase(4 * 24 * 60 * 60);
      const before = await ethers.provider.getBalance(creator.address);
      await chainGive.finalizeVote(0, 0);
      const after  = await ethers.provider.getBalance(creator.address);

      expect(after - before).to.be.closeTo(M1_AMT, ethers.parseEther("0.01"));
    });

    it("이중 투표는 실패해야 한다", async () => {
      await chainGive.connect(creator).startMilestoneVoting(0, 0, 3);
      await chainGive.connect(donor1).vote(0, 0, true);
      await expect(
        chainGive.connect(donor1).vote(0, 0, true)
      ).to.be.revertedWith("Already voted");
    });
  });

  // ── 환불 ──────────────────────────────────────────────────────────────
  describe("환불 (Refund)", () => {
    it("목표 미달 시 환불이 가능해야 한다", async () => {
      await chainGive.connect(donor1).donate(0, { value: ethers.parseEther("0.3") });
      await time.increase(31 * 24 * 60 * 60);

      const before = await ethers.provider.getBalance(donor1.address);
      const tx     = await chainGive.connect(donor1).refund(0);
      const receipt= await tx.wait();
      const gas    = receipt.gasUsed * tx.gasPrice;
      const after  = await ethers.provider.getBalance(donor1.address);

      expect(after + gas - before).to.equal(ethers.parseEther("0.3"));
    });
  });
});
