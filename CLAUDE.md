# MISO QA Test Suite

MISO 아이데이션 워크플로우 QA 테스트 도구입니다.

## 스킬

### /miso-qa-test
테스트 실행 - 주제 입력 후 테스트 유형 선택, 멀티턴 대화 수행

```bash
/miso-qa-test GS25 재고관리 앱
/miso-qa-test 건설현장 안전점검
```

### /miso-qa-eval
테스트 평가 - LLM-as-Judge 방식으로 결과 분석 및 판정

```bash
/miso-qa-eval                    # 미평가 전체
/miso-qa-eval 20260126_F-01_...  # 특정 파일
```

## 실행 흐름

```
/miso-qa-test <주제>
       ↓
AskUserQuestion (테스트 유형 선택)
 - F: 정상 플로우
 - E: 예외 처리
 - C: 흐름 제어
 - B: 경계값
 - U: 사용성
       ↓
선택한 테스트 순차 수행 (멀티턴 curl)
       ↓
results/raw/ 저장
       ↓
/miso-qa-eval
       ↓
LLM-as-Judge 평가 (6개 차원)
       ↓
results/passed/ 또는 results/review/
```

## 환경변수

```bash
source .env  # MISO_API_KEY 로드
```

## 프로젝트 구조

```
./
├── CLAUDE.md
├── .env                           # API 키 (git 제외)
├── .gitignore
├── .claude/skills/
│   ├── miso-qa-test/SKILL.md      # 테스트 실행
│   └── miso-qa-eval/SKILL.md      # 결과 평가
└── results/
    ├── raw/                       # 테스트 원본 결과
    ├── passed/                    # PASS 판정
    ├── review/                    # PARTIAL/FAIL 판정
    └── summary.md                 # 전체 현황
```

## 평가 기준 (LLM-as-Judge)

| 기준 | 가중치 | 설명 |
|-----|-------|------|
| Relevancy | 20% | 응답 관련성 |
| Coherence | 15% | 대화 일관성 |
| Helpfulness | 20% | 목표 달성 기여 |
| Tone Adherence | 15% | 역할별 톤 준수 |
| Error Handling | 15% | 예외 상황 처리 |
| Task Completion | 15% | 워크플로우 완료 |

## 판정 기준

- **PASS**: 총점 4.0+ AND 모든 항목 3점+
- **PARTIAL**: 총점 2.5~3.9 OR 1개 항목 2점
- **FAIL**: 총점 2.5 미만 OR 2개+ 항목 2점 이하

## MISO API

```
POST https://api.miso.52g.ai/ext/v1/chat
Authorization: Bearer $MISO_API_KEY
```

## 워크플로우 스테이지

```
[문제 정의] → [문제 확정] → [기능 설계] → [기술 스펙] → [PRD 생성]
   (Ally)       (Ally)       (Kyle)       (Kyle)       (Kyle)
```
