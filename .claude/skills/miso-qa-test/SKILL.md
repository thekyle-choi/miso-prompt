---
name: miso-qa-test
description: MISO 아이데이션 워크플로우를 테스트합니다. 주제를 입력하면 테스트 유형을 선택 후 멀티턴 대화로 테스트합니다.
argument-hint: "<주제>"
user-invocable: true
---

# MISO QA 테스트

주제를 입력받아 테스트 유형을 선택하고, MISO API와 멀티턴 대화를 수행합니다.

## 사용법

```bash
/miso-qa-test GS25 재고관리 앱
/miso-qa-test 건설현장 안전점검
/miso-qa-test 백투백 계약서 비교 서비스
```

## 실행 흐름

```
1. 주제 입력
2. AskUserQuestion으로 테스트 유형 선택 (복수 선택 가능)
3. Read 도구로 .env 파일에서 MISO_API_KEY 확인 (필수!)
4. 선택한 테스트 유형별로 순차 수행
5. 각 테스트마다 멀티턴 대화 진행하여 PRD 생성까지 완주
6. 결과를 results/raw/에 저장
7. /miso-qa-eval로 별도 평가 수행
```

---

## 테스트 유형

**참고**: AskUserQuestion은 최대 4개 옵션만 지원하므로, 두 번 질문하거나 직접 텍스트로 입력받으세요.

| 코드 | 유형 | 설명 | 문서 |
|-----|------|------|------|
| **F** | 정상 플로우 | Happy Path - PRD까지 완주 | [F-functional.md](./modes/F-functional.md) |
| **E** | 예외 처리 | 폼 외 입력, 빈값, 특수문자 | [E-exception.md](./modes/E-exception.md) |
| **C** | 흐름 제어 | 주제 변경, 이전 단계, 처음부터 | [C-control.md](./modes/C-control.md) |
| **B** | 경계값 | 최소/최대 입력, 불가능 기능 | [B-boundary.md](./modes/B-boundary.md) |
| **U** | 사용성 | 모호한 응답, 반복 질문 | [U-usability.md](./modes/U-usability.md) |
| **H** | 개진상모드 | 최악의 유저, 극한 상황 🔥 | [H-hell.md](./modes/H-hell.md) |

**CRITICAL**: 모든 테스트 케이스는 PRD 생성까지 완주해야 합니다!
- 정상 플로우(F): 처음부터 끝까지 정상 진행
- 예외 케이스(E/C/B/U): 중간에 예외 삽입 → MISO 대응 → 이후 PRD까지
- 개진상모드(H): 처음부터 끝까지 극한 대응 → 기적의 PRD 완성

---

## 환경변수 로딩

**CRITICAL**: 반드시 아래 방법으로 API 키를 로드하세요.

### 올바른 방법
1. **Read 도구**로 `.env` 파일을 읽고 API 키 값을 메모리에 저장 (권장)
2. **bash**로 `cat .env` 실행하여 키 확인
3. curl 명령에서 직접 키 값 사용

### 잘못된 방법 (동작하지 않음)
```bash
# ❌ 이 방법은 서브셸 문제로 동작하지 않음
source .env && curl ...
```

---

## API 호출

### 첫 번째 요청 (새 대화)
```bash
# Read 도구로 .env 읽고 직접 키 값 사용 (가장 확실)
curl -s -X POST 'https://api.miso.52g.ai/ext/v1/chat' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer app-FB4MDb98i07mq85KjZnbQoPw' \
  -d '{"inputs": {}, "query": "메시지 내용", "mode": "blocking", "conversation_id": "", "user": "qa-tester"}' \
  > /tmp/miso_response.json
```

### 이후 요청 (대화 이어가기)
```bash
# conversation_id를 유지하며 계속 호출
curl -s -X POST 'https://api.miso.52g.ai/ext/v1/chat' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer app-FB4MDb98i07mq85KjZnbQoPw' \
  -d "{\"inputs\": {}, \"query\": \"다음 메시지\", \"mode\": \"blocking\", \"conversation_id\": \"${CONV_ID}\", \"user\": \"qa-tester\"}" \
  > /tmp/miso_response.json
```

### 응답 파싱
```bash
# 기본 정보
cat /tmp/miso_response.json | jq -r '.answer'
cat /tmp/miso_response.json | jq -r '.conversation_id'
cat /tmp/miso_response.json | jq -r '.metadata.usage.latency'

# PRD JSON 추출 (Python 사용, 더 안전)
cat /tmp/miso_response.json | jq -r '.answer' | python3 -c "
import sys, re, json
content = sys.stdin.read()
match = re.search(r'<prd>(.*?)</prd>', content, re.DOTALL)
if match:
    prd_json = json.loads(match.group(1))
    print(json.dumps(prd_json, indent=2, ensure_ascii=False))
"
```

---

## 공통 참조 문서

- **워크플로우**: [workflow.md](./common/workflow.md) - MISO 스테이지, 에이전트 전환, Form 응답
- **결과 형식**: [result-format.md](./common/result-format.md) - 파일명, 저장 형식, PRD JSON 추출

---

## 다음 단계

테스트 완료 후 `/miso-qa-eval`로 결과 평가:
```bash
/miso-qa-eval                    # 미평가 결과 전체
/miso-qa-eval 20260126_F-01_...  # 특정 파일
```
