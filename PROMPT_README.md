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

### 1단계: 수정 및 자동 아카이빙 (Editing & Auto-Archive)

개선된 `archive_prompt.sh`는 수정 전 백업과 커밋을 자동으로 처리합니다.

**권장 워크플로우:**
1.  `prompts/` 내의 파일을 자유롭게 수정합니다.
2.  터미널에서 `./archive_prompt.sh`를 실행합니다.
3.  스크립트가 수정사항을 자동으로 감지합니다.
4.  변경 내용에 대한 간단한 설명을 입력합니다.
    - 스크립트가 **수정 전 원본(Committed version)**을 `prompts_legacy/`에 자동으로 저장합니다.
    - 수정된 파일과 레거시 파일을 세트로 묶어 `git commit`까지 완료합니다.

```bash
./archive_prompt.sh
# 1. 수정사항 자동 감지 및 목록 표시
# 2. 설명 입력 (예: 'fix_tone')
# -> 원본 백업 + 현재 수정본 Git 커밋 완료!
```
- **명명 규칙**: `YYYYMMDD_v{순번}_{간단한설명}.md`
    - 예: `20240121_v1_initial.md`
    - 예: `20240125_v2_add_retry_logic.md`

### 2단계: Git Push (Optional)
로컬 커밋이 완료된 후 원격 저장소에 반영하려면 `git push`를 실행하세요.

## 4. 파일명 및 경로 규칙

모든 프롬프트는 에이전트와 역할에 따라 구조화된 디렉토리에 저장됩니다.

- **경로**: `prompts/{category}/{agent_name}/{node_name}/prompt.md`
- **예시**:
    - `prompts/agents/ally/ask/prompt.md`
    - `prompts/router/orchestrator/prompt.md`
