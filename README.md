[README.md](https://github.com/user-attachments/files/28250000/README.md)
# 🔗 ChainGive

> **기부가 사라지지 않는 세상을 만듭니다**  
> 블록체인 기반 투명한 기부 및 자금 추적 플랫폼

[![Solidity](https://img.shields.io/badge/Solidity-0.8.x-363636?logo=solidity)](https://soliditylang.org/)
[![React](https://img.shields.io/badge/React-TypeScript-61DAFB?logo=react)](https://react.dev/)
[![Ethereum](https://img.shields.io/badge/Ethereum-Sepolia_Testnet-3C3C3D?logo=ethereum)](https://ethereum.org/)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

---

## 📌 프로젝트 소개

ChainGive는 이더리움 스마트 컨트랙트와 DAO 거버넌스를 결합해, 기부금의 **모든 이동 경로를 온체인에 투명하게 기록**하는 탈중앙 기부 플랫폼입니다.

기존 기부 시스템의 3가지 핵심 문제를 해결합니다.

| 문제 | 설명 |
|------|------|
| 💸 자금 흐름 불투명 | 기부금이 중간 단체를 거치며 실제 수혜자에게 얼마나 전달되는지 확인 불가 |
| 🚨 중간 유실·횡령 위험 | 다수의 중개 기관을 통한 자금 이동으로 유실·횡령 사례 반복 발생 |
| 🚫 기부자 의사결정 배제 | 모금 이후 자금 집행에 기부자가 개입할 방법 없음 |

---

## ✨ 핵심 기능

### 1. 캠페인 생성 & 기부
누구나 모금 캠페인을 생성하고, 이더리움 기반 스마트 컨트랙트로 기부금을 직접 수탁합니다.

### 2. 온체인 자금 추적
`기부 → 단계별 잠금 → 투표 승인 → 수혜자 지급`까지 모든 트랜잭션이 블록체인에 영구 기록됩니다.

### 3. DAO 거버넌스 투표
기부자들이 프로젝트 진행 단계마다 투표로 자금 집행을 직접 승인 또는 거부합니다.

---

## 🔄 자금 지급 흐름

```
기부자 (ETH 기부)
    ↓
스마트 컨트랙트 (에스크로 보관)
    ↓
마일스톤 달성 요청
    ↓
DAO 투표 (기부자 참여)
    ↓ 가결               ✗ 부결
수혜자 자금 수령      자금 잠금 유지 또는 환불
```

모든 단계는 블록체인에 온체인으로 기록됩니다.
`기부 트랜잭션 → 단계 잠금 이벤트 → 투표 결과 → 자금 집행 트랜잭션 → 수혜자 수령 확인`

---

## 🛠 기술 스택

### 블록체인 레이어
| 기술 | 역할 |
|------|------|
| Ethereum (Sepolia Testnet) | 스마트 컨트랙트 배포 환경 |
| Solidity ^0.8.x | 기부 컨트랙트 및 DAO 로직 작성 |
| Hardhat | 컨트랙트 컴파일·테스트·배포 프레임워크 |
| OpenZeppelin | ERC20, AccessControl, Governor 라이브러리 |

### 프론트엔드
| 기술 | 역할 |
|------|------|
| React + TypeScript | 캠페인 대시보드 UI |
| ethers.js v6 | 지갑 연결 및 컨트랙트 호출 |
| MetaMask SDK | 사용자 지갑 인증 |
| Tailwind CSS | UI 스타일링 |

### AI / 기타 도구
| 기술 | 역할 |
|------|------|
| Claude API (Anthropic) | 캠페인 설명 자동 생성 및 사기 의심 분석 |
| The Graph (Subgraph) | 온체인 이벤트 인덱싱 및 쿼리 |
| IPFS / Pinata | 캠페인 메타데이터·증빙 서류 분산 저장 |
| Alchemy / Infura | Ethereum 노드 RPC 엔드포인트 |

---

## 🗺 개발 로드맵

```
Phase 1 — 기반 설계
  ✅ 스마트 컨트랙트 설계 (기부, 잠금, 지급)
  ✅ Solidity 코드 작성 및 단위 테스트
  ✅ Sepolia 테스트넷 배포

Phase 2 — 거버넌스 구현
  ✅ DAO 투표 컨트랙트 (OpenZeppelin Governor)
  ✅ 마일스톤 단계별 자금 잠금 로직
  ✅ 투표 집계 및 집행 자동화

Phase 3 — 프론트엔드
  ✅ React 대시보드 (캠페인 목록/상세)
  ✅ ethers.js 지갑 연결·트랜잭션 처리
  ✅ The Graph 서브그래프 연동

Phase 4 — AI & 통합
  ✅ Claude API 연동 (캠페인 분석)
  ✅ IPFS 증빙 파일 업로드 연동
  ✅ 통합 테스트 및 사용성 개선
```

---

## 📦 결과물

- **기부 스마트 컨트랙트** — Solidity로 작성된 에스크로·DAO 컨트랙트 (오픈소스)
- **React DApp 대시보드** — 캠페인 생성·기부·투표·추적 기능을 갖춘 완성 프론트엔드
- **온체인 Explorer 뷰** — The Graph 서브그래프로 자금 흐름을 시각화한 트래킹 페이지
- **AI 캠페인 분석 기능** — Claude API 연동으로 캠페인 신뢰도 분석 및 설명문 자동 생성

---

## 📈 기대 효과

| 지표 | 내용 |
|------|------|
| 100% | 자금 흐름 투명성 (온체인 공개 기록) |
| 0원 | 중간 수수료 (P2P 스마트 컨트랙트) |
| DAO | 기부자 직접 의사결정 참여 |
| 실시간 | 자금 추적 (The Graph 인덱싱) |

---

## 🚀 시작하기

```bash
# 저장소 클론
git clone https://github.com/your-username/chaingive.git
cd chaingive

# 의존성 설치
npm install

# 환경 변수 설정
cp .env.example .env
# .env 파일에 ALCHEMY_API_KEY, PRIVATE_KEY, CLAUDE_API_KEY 등 입력

# 컨트랙트 컴파일
npx hardhat compile

# Sepolia 테스트넷 배포
npx hardhat run scripts/deploy.js --network sepolia

# 프론트엔드 실행
cd frontend && npm install && npm run dev
```

---

## 👤 개발자

| 이름 | 학번 |
|------|------|
| 김기태 | 20222097 |

---

## 📄 라이선스

이 프로젝트는 [MIT License](LICENSE) 하에 배포됩니다.

---

<p align="center">
  <b>Ethereum · Solidity · React · ethers.js · The Graph · IPFS · Claude API</b><br/>
  <i>투명한 기부의 미래</i>
</p>
