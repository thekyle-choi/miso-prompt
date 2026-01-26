# 테스트 결과 저장 형식

## 저장 위치
`results/raw/`

## 파일명 형식
```
{YYYYMMDD_HHMMSS}_{테스트ID}_{주제슬러그}.md
```

예시:
- `20260126_144434_F-01_back-to-back-contract-comparison.md`
- `20260126_153022_H-01_impossible-requirements.md`

## 파일 내용 구조

```markdown
# 테스트: {테스트ID} - {주제}

**실행일시**: YYYY-MM-DD HH:MM:SS
**테스트 유형**: {유형}
**테스트 조건**: {조건 설명}

---

## 대화 로그

### Turn 1
**User**: ...
**MISO** (Ally): ...
(응답시간: X.Xs)

### Turn 2
**User**: ...
**MISO** (Ally): ...
(응답시간: X.Xs)

### Turn N (PRD 생성)
**User**: 다음
**MISO** (Kyle): ...
<prd>
{JSON 원문 그대로}
</prd>
(응답시간: X.Xs)

---

## 최종 PRD (JSON)

**CRITICAL**: MISO API 응답의 `<prd>` 태그 안 JSON을 원문 그대로 저장하세요.

```json
{
  "title": "...",
  "problem_definition": {
    "purpose": "...",
    "target_users": "...",
    "core_problem": "...",
    "pain_points": "..."
  },
  "solution": {
    "implementation_type": "workflow",
    "summary": "...",
    "reference_file_name": "...",
    "io_spec": {
      "inputs": [...],
      "outputs": [...]
    }
  },
  "features_feasibility": [...]
}
```

---

## 테스트 완료 상태
- PRD 생성: ✅ 완료 / ❌ 미완료
- 테스트 조건 수행: ✅ 완료 / ❌ 미완료
- 예외 상황 처리: ✅ 적절 / ⚠️ 부적절 / N/A (정상 플로우)
- MISO 대응: (예외 케이스의 경우 MISO가 어떻게 처리했는지 기록)
- 에러 발생: ❌ 없음 / ⚠️ 있음 (내용)

**CRITICAL**: 모든 테스트는 PRD 생성 완료를 확인해야 합니다!

---

## 스테이지 진행
[문제 정의] → [문제 확정] → [기능 설계] → [기술 스펙] → [PRD 생성] ✅
   (Ally)       (Ally)       (Kyle)       (Kyle)       (Kyle)

## 최종 결과
conversation_id: ...
총 턴 수: N
완료 시간: 약 X분
```

## PRD JSON 추출 방법

### 방법 1: grep + sed (간단)
```bash
cat response.json | jq -r '.answer' | grep -oP '(?<=<prd>).*(?=</prd>)' | jq .
```

### 방법 2: Python (더 안전, 복잡한 JSON 처리)
```bash
cat response.json | jq -r '.answer' | python3 -c "
import sys, re, json
content = sys.stdin.read()
match = re.search(r'<prd>(.*?)</prd>', content, re.DOTALL)
if match:
    prd_json = json.loads(match.group(1))
    print(json.dumps(prd_json, indent=2, ensure_ascii=False))
"
```
