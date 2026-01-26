---
name: miso-qa-test
description: MISO 아이데이션 워크플로우를 테스트합니다. 주제를 입력하면 테스트 유형을 선택 후 멀티턴 대화로 테스트합니다.
argument-hint: "<주제>"
user-invocable: true
---

# MISO QA 테스트

주제를 입력받아 테스트 유형을 선택하고, MISO API와 멀티턴 대화를 수행합니다.

## 사용법

```
/miso-qa-test GS25 재고관리 앱
/miso-qa-test 건설현장 안전점검
```

## 실행 흐름

```
1. 주제 입력
2. AskUserQuestion으로 테스트 유형 선택 (복수 선택 가능)
3. 선택한 테스트 유형별로 순차 수행
4. 각 테스트마다 멀티턴 대화 진행
5. 결과를 results/raw/에 저장
6. /miso-qa-eval로 별도 평가 수행
```

## 테스트 유형 선택 (AskUserQuestion)

스킬 시작 시 반드시 AskUserQuestion으로 테스트 유형을 선택받습니다 (multiSelect: true):

### 질문
```
어떤 테스트를 수행할까요?
```

### 옵션
| 옵션 | 설명 |
|-----|------|
| F: 정상 플로우 | Happy Path - PRD까지 완주 |
| E: 예외 처리 | 폼 외 입력, 빈값, 특수문자 |
| C: 흐름 제어 | 주제 변경, 이전 단계, 처음부터 |
| B: 경계값 | 최소/최대 입력, 불가능 기능 |
| U: 사용성 | 모호한 응답, 반복 질문 |

## 테스트 케이스 상세

### F: 정상 플로우 (Functional)
| ID | 테스트 | 수행 방법 |
|----|-------|----------|
| F-01 | Happy Path | 모든 질문에 명확하게 답변, PRD 생성까지 완주 |
| F-02 | 단계 전환 | Ally→Kyle 핸드오프 확인 |
| F-03 | Form 응답 | form 선택값 정상 처리 확인 |

### E: 예외 처리 (Exception)
| ID | 테스트 | 수행 방법 |
|----|-------|----------|
| E-01 | 폼 외 입력 | form 옵션에 없는 값 입력 |
| E-02 | 빈값 입력 | 아무것도 입력하지 않음 |
| E-03 | 특수문자 | 이모지, 특수문자만 입력 |

### C: 흐름 제어 (Control)
| ID | 테스트 | 수행 방법 |
|----|-------|----------|
| C-01 | 주제 변경 | 중간에 완전히 다른 주제로 변경 |
| C-02 | 이전 단계 | "아까 거 수정할래요" 요청 |
| C-03 | 처음부터 | "처음부터 다시 할래요" 요청 |

### B: 경계값 (Boundary)
| ID | 테스트 | 수행 방법 |
|----|-------|----------|
| B-01 | 최소 입력 | 가능한 최소한의 정보로 진행 |
| B-02 | 최대 입력 | 모든 옵션 선택, 최대 정보 제공 |
| B-03 | 불가능 기능 | 구현 불가능한 기능만 요청 |

### U: 사용성 (Usability)
| ID | 테스트 | 수행 방법 |
|----|-------|----------|
| U-01 | 모호한 응답 | "그냥요", "몰라요" 등 |
| U-02 | 반복 질문 | 같은 질문 계속 반복 |
| U-03 | 이해 확인 | "뭐라고요?", "다시 설명해줘" |

## 환경변수

```bash
source .env  # MISO_API_KEY 로드
```

## API 호출

### 첫 번째 요청 (새 대화)
```bash
source .env && curl -s -X POST 'https://api.miso.52g.ai/ext/v1/chat' \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $MISO_API_KEY" \
  -d '{
    "inputs": {},
    "query": "메시지 내용",
    "mode": "blocking",
    "conversation_id": "",
    "user": "qa-tester"
  }'
```

### 이후 요청 (대화 이어가기)
```bash
source .env && curl -s -X POST 'https://api.miso.52g.ai/ext/v1/chat' \
  -H 'Content-Type: application/json' \
  -H "Authorization: Bearer $MISO_API_KEY" \
  -d '{
    "inputs": {},
    "query": "다음 메시지",
    "mode": "blocking",
    "conversation_id": "이전_응답의_conversation_id",
    "user": "qa-tester"
  }'
```

## Form 응답 방법

MISO가 `<form>` 태그로 질문하면 "header: 선택값" 형식으로 응답:

```
주요 사용자: 현장 작업자
핵심 기능: 바코드 스캔, 재고 조회
다음
```

## 워크플로우 스테이지

```
[문제 정의] → [문제 확정] → [기능 설계] → [기술 스펙] → [PRD 생성]
   (Ally)       (Ally)       (Kyle)       (Kyle)       (Kyle)
```

## 결과 저장

테스트 완료 후 `results/raw/`에 저장합니다. 평가는 하지 않습니다.

### 파일명
```
{YYYYMMDD_HHMMSS}_{테스트ID}_{주제슬러그}.md
```

### 파일 형식
```markdown
# 테스트: {테스트ID} - {주제}

**실행일시**: YYYY-MM-DD HH:MM:SS
**테스트 유형**: {유형}
**테스트 조건**: {조건 설명}

---

## 대화 로그

### Turn 1
**User**: ...
**MISO**: ...
(응답시간: X.Xs)

### Turn 2
**User**: ...
**MISO**: ...
(응답시간: X.Xs)

...

---

## 테스트 완료 상태
- PRD 생성: 완료/미완료
- 테스트 조건 수행: 완료/미완료
- 에러 발생: 없음/있음 (내용)
```

## 도메인 예시

| 도메인 | 예시 주제 |
|-------|----------|
| GS25 | 유통기한 관리, 발주, 재고, 청소점검 |
| GS더프레시 | 신선식품 관리, 클레임, 재고실사 |
| GS칼텍스 | 안전점검, 유류재고, 정산 |
| GS건설 | TBM, 자재관리, 공정관리 |

## 다음 단계

테스트 완료 후 `/miso-qa-eval`로 결과 평가:
```
/miso-qa-eval                    # 미평가 결과 전체
/miso-qa-eval 20260126_F-01_...  # 특정 파일
```
