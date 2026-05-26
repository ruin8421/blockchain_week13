const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();

  console.log("==============================================");
  console.log("  ChainGive 배포 시작");
  console.log("==============================================");
  console.log("배포 계정:", deployer.address);
  console.log(
    "계정 잔액:",
    ethers.formatEther(await ethers.provider.getBalance(deployer.address)),
    "ETH\n"
  );

  // 1. 컨트랙트 배포
  const ChainGive = await ethers.getContractFactory("ChainGive");
  const chainGive = await ChainGive.deploy();
  await chainGive.waitForDeployment();

  const address = await chainGive.getAddress();
  console.log("✅ ChainGive 컨트랙트 배포 완료!");
  console.log("   컨트랙트 주소:", address);

  // 2. 샘플 캠페인 생성 (시연용)
  console.log("\n─── 샘플 캠페인 생성 중 ───");

  const goalEth  = "1.0"; // 1 ETH
  const goalWei  = ethers.parseEther(goalEth);

  // 마일스톤: 40% / 40% / 20%
  const m1 = ethers.parseEther("0.4");
  const m2 = ethers.parseEther("0.4");
  const m3 = ethers.parseEther("0.2");

  const tx = await chainGive.createCampaign(
    "아프리카 식수 지원 프로젝트",
    "케냐 농촌 지역 3개 마을에 정수 시설을 설치합니다.",
    "QmExampleCID1234567890abcdef",  // 실제 IPFS CID로 교체
    goalWei,
    30,                              // 30일 모금
    [
      "Phase 1: 현지 조사 및 기자재 구매",
      "Phase 2: 정수 시설 설치 공사",
      "Phase 3: 운영 교육 및 인수인계",
    ],
    [m1, m2, m3]
  );
  await tx.wait();
  console.log("✅ 샘플 캠페인 생성 완료! (캠페인 ID: 0)");

  // 3. 결과 요약
  console.log("\n==============================================");
  console.log("  배포 완료 요약");
  console.log("==============================================");
  console.log(`컨트랙트 주소  : ${address}`);
  console.log(`네트워크       : ${(await ethers.provider.getNetwork()).name}`);
  console.log(
    `Etherscan URL  : https://sepolia.etherscan.io/address/${address}`
  );
  console.log("\n.env 파일에 아래 값을 추가하세요:");
  console.log(`VITE_CONTRACT_ADDRESS=${address}`);
}

main().catch((err) => {
  console.error(err);
  process.exitCode = 1;
});
