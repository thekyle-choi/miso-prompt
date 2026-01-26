---
name: miso-qa-test
description: MISO 아이데이션 워크플로우를 테스트합니다. 주제를 입력하면 테스트 유형을 선택 후 멀티턴 대화로 테스트합니다.
argument-hint: "<주제>"
user-invocable: true
---

# MISO QA 테스트

주제를 입력받아 테스트 유형을 선택하고, MISO API와 멀티턴 대화를 수행합니다.

## 핵심 원칙 (반드시 준수!)

1. **Read 도구로 .env 파일 읽기** - API 키를 메모리에 저장
2. **JSON을 항상 파일로 작성** - heredoc 사용 (`cat > file.json <<EOF`)
3. **curl 명령어는 한 줄로** - 백슬래시 줄바꿈 절대 사용 금지
4. **conversation_id 매번 추출** - 직전 응답 파일에서 `jq -r '.conversation_id'`
5. **PRD 생성까지 완주** - 모든 테스트는 app_builder 전환까지 확인

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

## CURL 명령어 작성 규칙 (CRITICAL!)

**반드시 따라야 할 규칙**:
1. ❌ **절대 백슬래시(`\`) 줄바꿈 사용 금지** - Bash tool 파싱 오류 발생
2. ✅ **항상 JSON을 파일로 먼저 작성** - heredoc 사용
3. ✅ **curl 명령어는 한 줄로 작성** - 옵션 사이에 공백만 사용
4. ✅ **heredoc EOF는 따옴표로 감싸기** - `<<'EOF'` (변수 치환 없을 때) 또는 `<<EOF` (변수 치환 필요할 때)

**올바른 패턴**:
```bash
# JSON 파일 생성
cat > /tmp/request.json <<'EOF'
{"inputs": {}, "query": "메시지", "mode": "blocking", "conversation_id": "", "user": "qa-tester"}
EOF

# curl 한 줄로 실행
curl -s -X POST 'https://api.miso.52g.ai/ext/v1/chat' -H 'Content-Type: application/json' -H 'Authorization: Bearer 키값' -d @/tmp/request.json > /tmp/response.json
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
   - Read tool로 `/path/to/.env` 읽기
   - API 키 값을 직접 curl 명령어에 사용

### 잘못된 방법 (동작하지 않음)
```bash
# ❌ 서브셸 문제로 동작하지 않음
source .env && curl ...

# ❌ 환경변수가 Bash tool 세션 간 유지되지 않음
export MISO_API_KEY=...
```

---

## conversation_id 관리 (매우 중요!)

**CRITICAL**: 멀티턴 대화를 위해서는 **매 요청마다** 직전 응답에서 conversation_id를 추출해야 합니다!

### ❌ 잘못된 방법 (변수가 유지되지 않음)
```bash
# Turn 1
curl ... > turn1.json
CONV_ID=$(cat turn1.json | jq -r '.conversation_id')

# Turn 2 - 다른 Bash 호출이므로 CONV_ID가 비어있음!
curl ... -d "conversation_id: ${CONV_ID}" ...  # ❌ 빈 문자열!
```

### ✅ 올바른 방법 (매번 추출)
```bash
# Turn 1
curl ... > turn1.json

# Turn 2 - 직전 파일에서 추출
CONV_ID=$(cat turn1.json | jq -r '.conversation_id')
curl ... -d "conversation_id: ${CONV_ID}" ... > turn2.json

# Turn 3 - 또 직전 파일에서 추출
CONV_ID=$(cat turn2.json | jq -r '.conversation_id')
curl ... -d "conversation_id: ${CONV_ID}" ... > turn3.json
```

---

## API 호출

**CRITICAL**: Bash tool에서 백슬래시(`\`) 줄바꿈이 파싱 오류를 일으킬 수 있습니다.
**항상 JSON을 파일로 먼저 작성하고 `-d @파일명` 형식으로 전달하세요!**

### 첫 번째 요청 (새 대화)
```bash
# STEP 1: Read 도구로 .env 읽고 API 키 확인 (반드시 먼저!)
# STEP 2: JSON 파일 생성
cat > /tmp/miso_request1.json <<'EOF'
{
  "inputs": {},
  "query": "메시지 내용",
  "mode": "blocking",
  "conversation_id": "",
  "user": "qa-tester"
}
EOF

# STEP 3: API 호출 (한 줄로 작성!)
curl -s -X POST 'https://api.miso.52g.ai/ext/v1/chat' -H 'Content-Type: application/json' -H 'Authorization: Bearer app-FB4MDb98i07mq85KjZnbQoPw' -d @/tmp/miso_request1.json > /tmp/miso_turn1.json && cat /tmp/miso_turn1.json | jq -r '.answer'
```

### 이후 요청 (대화 이어가기)
```bash
# **CRITICAL**: 매 요청마다 직전 응답 파일에서 conversation_id를 추출해야 합니다!
# Bash 세션이 독립적이므로 변수가 유지되지 않습니다.

# STEP 1: 직전 응답에서 conversation_id 추출
CONV_ID=$(cat /tmp/miso_turn1.json | jq -r '.conversation_id')

# STEP 2: JSON 파일 생성 (EOF에 따옴표 주의!)
cat > /tmp/miso_request2.json <<EOF
{
  "inputs": {},
  "query": "다음 메시지",
  "mode": "blocking",
  "conversation_id": "${CONV_ID}",
  "user": "qa-tester"
}
EOF

# STEP 3: API 호출 (한 줄로 작성!)
curl -s -X POST 'https://api.miso.52g.ai/ext/v1/chat' -H 'Content-Type: application/json' -H 'Authorization: Bearer app-FB4MDb98i07mq85KjZnbQoPw' -d @/tmp/miso_request2.json > /tmp/miso_turn2.json && cat /tmp/miso_turn2.json | jq -r '.answer'
```

**올바른 패턴 (Turn 3 이후)**:
```bash
# 항상 직전 턴의 파일에서 conversation_id 추출
CONV_ID=$(cat /tmp/miso_turn2.json | jq -r '.conversation_id')
cat > /tmp/miso_request3.json <<EOF
{
  "inputs": {},
  "query": "세 번째 메시지",
  "mode": "blocking",
  "conversation_id": "${CONV_ID}",
  "user": "qa-tester"
}
EOF
curl -s -X POST 'https://api.miso.52g.ai/ext/v1/chat' -H 'Content-Type: application/json' -H 'Authorization: Bearer app-FB4MDb98i07mq85KjZnbQoPw' -d @/tmp/miso_request3.json > /tmp/miso_turn3.json && cat /tmp/miso_turn3.json | jq -r '.answer'
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

---

## 완전한 예시 (Turn 1-3)

```bash
# ===== TURN 1 (새 대화 시작) =====
# Step 1: JSON 생성
cat > /tmp/miso_request1.json <<'EOF'
{
  "inputs": {},
  "query": "간단한 인사챗봇",
  "mode": "blocking",
  "conversation_id": "",
  "user": "qa-tester"
}
EOF

# Step 2: API 호출 (한 줄!)
curl -s -X POST 'https://api.miso.52g.ai/ext/v1/chat' -H 'Content-Type: application/json' -H 'Authorization: Bearer app-FB4MDb98i07mq85KjZnbQoPw' -d @/tmp/miso_request1.json > /tmp/miso_turn1.json && cat /tmp/miso_turn1.json | jq -r '.answer'

# ===== TURN 2 (대화 이어가기) =====
# Step 1: conversation_id 추출
CONV_ID=$(cat /tmp/miso_turn1.json | jq -r '.conversation_id')

# Step 2: JSON 생성 (EOF 따옴표 없음 - 변수 치환 필요)
cat > /tmp/miso_request2.json <<EOF
{
  "inputs": {},
  "query": "사용자: 웹사이트 방문자\n해결하고 싶은 문제: 반복 질문 응대\n다음",
  "mode": "blocking",
  "conversation_id": "${CONV_ID}",
  "user": "qa-tester"
}
EOF

# Step 3: API 호출
curl -s -X POST 'https://api.miso.52g.ai/ext/v1/chat' -H 'Content-Type: application/json' -H 'Authorization: Bearer app-FB4MDb98i07mq85KjZnbQoPw' -d @/tmp/miso_request2.json > /tmp/miso_turn2.json && cat /tmp/miso_turn2.json | jq -r '.answer'

# ===== TURN 3 =====
CONV_ID=$(cat /tmp/miso_turn2.json | jq -r '.conversation_id')
cat > /tmp/miso_request3.json <<EOF
{
  "inputs": {},
  "query": "다음",
  "mode": "blocking",
  "conversation_id": "${CONV_ID}",
  "user": "qa-tester"
}
EOF
curl -s -X POST 'https://api.miso.52g.ai/ext/v1/chat' -H 'Content-Type: application/json' -H 'Authorization: Bearer app-FB4MDb98i07mq85KjZnbQoPw' -d @/tmp/miso_request3.json > /tmp/miso_turn3.json && cat /tmp/miso_turn3.json | jq -r '.answer'
```

---

## 다음 단계

테스트 완료 후 `/miso-qa-eval`로 결과 평가:
```bash
/miso-qa-eval                    # 미평가 결과 전체
/miso-qa-eval 20260126_F-01_...  # 특정 파일
```
