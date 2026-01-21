# PLAI Maker 프롬프트 관리 가이드

이 저장소는 PLAI Maker 프로젝트의 LLM 프롬프트를 체계적으로 버전 관리하기 위해 설계되었습니다.

## 1. 디렉토리 구조

- **`prompts/`**: [HEAD] 현재 프로덕션에 배포되어 사용 중인 최신 프롬프트 (Source of Truth)
- **`prompts_legacy/`**: [Archive] 과거 버전의 프롬프트들이 스냅샷 형태로 보관되는 곳
- **`templates/`**: 참조용 워크플로우 YAML 템플릿 파일들

## 2. 버전 관리 철학

우리는 **이중 관리 전략**을 사용합니다:
1.  **Git**: 코드 베이스 전체의 변경 이력(Technical History)을 추적합니다.
2.  **Legacy 폴더**: "사람이 읽고 비교하기 쉬운" 파일 단위의 스냅샷(Human-readable History)을 유지합니다.

## 3. 프롬프트 수정 워크플로우 (Protocol)

프롬프트를 수정해야 할 때는 반드시 아래 절차를 따라주세요.

### 1단계: 아카이빙 (Archiving)
**도구 사용 권장**: 제공된 `archive_prompt.sh` 스크립트를 사용하면 번거로운 복사 과정을 자동화할 수 있습니다.

```bash
./archive_prompt.sh
# 1. 수정할 프롬프트 파일 선택
# 2. 버전 설명 입력 (예: 'fix_tone')
# -> prompts_legacy/ 폴더에 자동 백업 완료
```

수동으로 진행할 경우:
- **목적**: 수정 전 상태를 확실하게 보존
- **명명 규칙**: `YYYYMMDD_v{순번}_{간단한설명}.md`
    - 예: `20240121_v1_initial.md`
    - 예: `20240125_v2_add_retry_logic.md`

### 2단계: 편집 (Editing)
`prompts/` 폴더 내의 파일을 직접 수정합니다. 이곳의 파일명은 `prompt.md`로 항상 고정되어야 합니다.

### 3단계: 커밋 (Commit)
Git 커밋 메시지에 변경 사항과 아카이빙된 버전을 함께 기록하면 추적에 용이합니다.
- 예: `Update ally/ask prompt (Archived: v2_add_retry_logic)`

## 4. 파일명 및 경로 규칙

모든 프롬프트는 에이전트와 역할에 따라 구조화된 디렉토리에 저장됩니다.

- **경로**: `prompts/{category}/{agent_name}/{node_name}/prompt.md`
- **예시**:
    - `prompts/agents/ally/ask/prompt.md`
    - `prompts/router/orchestrator/prompt.md`
