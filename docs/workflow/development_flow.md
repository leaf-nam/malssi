# malssi Development Workflow (개발 워크플로우)

> AI 에이전트용 개발 하네스 문서 중 하나입니다. 상위 지침: `AGENTS.md`.
> 본 문서는 `battern` 프로젝트의 `workflow.md` / `AGENTS.md` §3 패턴을
> Flutter 스택(`flutter analyze`, `flutter test`)에 맞게 적용한 것입니다.
> 이슈 #8의 기대 워크플로우 다이어그램을 규범화합니다.

## 1. 개요

모든 개발은 **개발자가 등록한 GitHub 이슈**를 기점으로 진행됩니다.
LLM 에이전트는 이슈 목록을 조회하여 처리할 이슈를 제안하고,
**개발자의 확인/지정 없이는 개발에 착수하지 않습니다.**
이후 브랜치 생성 → 개발(TDD 권장) → 커밋/푸시 → PR 생성 → 개발자 검토/승인(머지) 순으로 진행합니다.

```
[개발자: 이슈 작성] → [LLM: 이슈 목록 조회] → [LLM: 이슈 선택 (개발자 확인)]
                    ↘                              ↓
                 [LLM: 브랜치 생성] → [LLM: 개발 (TDD)] → [LLM: PR 생성]
                                    ↑
                              [개발자: 검토/승인] → [머지]
```

## 2. 단계별 가이드라인

### 2.1 이슈 등록 (개발자)

- 개발자가 GitHub에 작업 이슈를 작성합니다.
- 제목과 본문에 요구사항, 재현 조건(버그인 경우), 완료 기준을 명확히 기술합니다.
- 예시: 이슈 #8 "Model Context Generation & Workflow Documentation" —
  개요/완료된 작업/생성할 컨텍스트/기대 산출물/완료 기준으로 구성.

### 2.2 이슈 목록 조회 및 선택 (LLM → 개발자 확인)

- LLM은 이슈 목록 조회(github MCP `list_issues`/`search_issues` 또는 `gh issue list`)로
  열린 이슈 목록을 조회합니다.
- 이슈 목록과 우선순위 판단 근거를 개발자에게 제시합니다.
- 처리할 이슈는 **개발자가 확인/지정한 것으로 확정**하며, 승인 전에는 개발에 착수하지 않습니다.

### 2.3 브랜치 생성 (LLM)

- 작업 시작 전에 항상 `main` 브랜치에서 새 브랜치를 생성합니다.
- 생성 전 `git fetch origin`으로 최신 상태를 확인합니다.
- 브랜치 이름은 작업 내용을 나타내는 짧은 **영어 타입 prefix + 설명**으로 작성합니다.
  - 형식: `<type>/<short-description-kebab-case>`
  - 예시: `model/context-generation` (본 이슈 #8의 작업 브랜치),
    `feat/quote-like`, `fix/comment-screen`
  - `battern`에서는 한글 브랜치명도 허용했지만, `malssi`에서는 영어 prefix를 원칙으로 합니다.

### 2.4 개발 (LLM, TDD 권장)

- `AGENTS.md` §2의 행동 강령(컨텍스트 우선 로드, 모델/아키텍처 무결성)을 준수합니다.
- 수정 전 관련 명세(`docs/context/model_spec.md`, `docs/architecture/architecture_spec.md`,
  `docs/conventions/convention.md`)를 먼저 읽습니다.
- 테스트 중심 개발 권장:
  - 기존 테스트: `test/widget_test.dart` (현재 기본 카운터 템플릿 — 도메인 단위 테스트 보강 필요).
  - 신규/수정 로직에 대응하는 테스트 케이스를 함께 작성합니다.
- 검증 명령 (PR 생성의 **필수 조건**):
  ```sh
  flutter analyze
  flutter test
  ```
  (`battern`의 `npm run test`에 대응.)

### 2.5 커밋 (LLM)

- 작업이 완료되면 적절한 커밋 메시지와 함께 커밋합니다.
- 커밋 메시지는 어떤 작업을 했는지 알 수 있게 **한글**로 작성합니다.
  - 예시: `모델 컨텍스트 및 워크플로우 문서 작성 (#8)`

### 2.6 푸시 (LLM)

- 커밋 후 항상 원격에 푸시합니다: `git push origin <브랜치명>`.

### 2.7 PR 생성 (LLM)

- 푸시 후 PR을 생성하고, 본문에 관련 이슈 번호(예: `Closes #8`)를 참조합니다.
- PR 생성 전 반드시 `flutter analyze`와 `flutter test`를 통과했는지 확인합니다.
- PR 본문에는 변경 파일(`AGENTS.md`, `docs/context/model_spec.md`,
  `docs/workflow/development_flow.md`, `docs/architecture/architecture_spec.md`,
  `docs/conventions/convention.md` 등)과 검증 결과를 명시합니다.

### 2.8 검토 및 승인 (개발자)

- 개발자가 PR을 리뷰한 뒤 승인(머지)합니다.
- LLM 에이전트가 **자율적으로 머지하는 것은 금지**입니다.
- 수정 요청이 있으면 피드백을 반영하여 2.4~2.7단계를 반복합니다.

## 3. 작업 완료 후

- 모든 변경사항을 커밋하고 원격에 푸시한 뒤에 작업 완료를 알립니다.
- 이슈의 완료 기준(체크리스트)이 충족되었는지 확인합니다.

## 4. `battern` 패턴과의 대응표

| 항목 | `battern` | `malssi` (본 문서) |
|------|-----------|-------------------|
| 이슈 조회 | `gh issue list` | 이슈 목록 조회 (MCP/`gh`) — 동일 원칙 |
| 브랜치명 | 영어 또는 한글 (예: `fix/선-그리기-오류`) | 영어 타입 prefix 원칙 (예: `model/context-generation`) |
| 테스트 | `npm run test` (Vitest) | `flutter test` + `flutter analyze` |
| 커밋 메시지 | 한글 | 한글 — 동일 |
| PR | `gh pr create`, `Closes #N` 참조 | 동일 (MCP 또는 `gh`) |
| 머지 | 개발자만 수행 | 개발자만 수행 — 동일 |
