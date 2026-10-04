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
  - 기존 테스트: `test/widget_test.dart` (홈 스모크), `test/repository_test.dart`,
    `test/screens_test.dart`.
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
- PR의 base는 **기능 PR은 `release/*`만, 릴리스 PR(`release/*` → `main`)만 `main`**입니다.
  기능 PR을 `main`에 직접 내는 것은 금지합니다
  (2026-10-03 확정 — `main` 직행 PR 5건(#227·#235~#238)이
  릴리스 흐름을 우회하고 불필요한 빌드를 유발한 전례).
  기능 브랜치끼리 머지하거나 base로 삼는 스택 방식도 금지합니다
  (2026-09-10 확정 — 스택 PR이 엉뚱한 base로 머지되어 릴리스 누락이 발생한 전례, #145).
  기능 간 코드 의존이 생기면 base 브랜치가 머지된 뒤 새 브랜치에서 rebase·cherry-pick으로 해소합니다.
- PR 생성 전 반드시 `flutter analyze`와 `flutter test`를 통과했는지 확인합니다.
- PR 생성 전 아래 **base 게이트**를 순서대로 통과해야 합니다 (하나라도 막히면 PR 생성 금지):

  ```
  [1] 이슈 마일스톤 확인 (예: v1.1.0)
       → [2] 대응 release/* 브랜치 존재 확인 (git branch -r / list_branches)
       → [3] 없으면 release/X.Y.Z를 main에서 먼저 생성 (개발자 확인 후)
       → [4] PR base = release/* 지정 후 생성
       → [5] 생성 직후 base 재확인 (pull_request_read의 base.ref)
  ```

  - `main`에 기능 PR을 내는 것은 어떤 경우에도 금지합니다.
    `main`을 base로 쓸 수 있는 PR은 릴리스 PR(`release/*` → `main`)뿐입니다.
  - 이미 `main` 기준으로 낸 PR이 있으면 즉시 base를 `release/*`로 변경합니다
    (`update_pull_request(base: ...)` 또는 `gh pr edit --base`).
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

### 3.1 이슈 단위 브랜치 정리 (매 이슈마다 수행, 2026-10-04 확정)

- 이슈의 PR이 머지되면 작업 브랜치를 릴리스 때까지 미루지 말고 즉시 삭제한다
  (원격 + 로컬):
  ```sh
  git push origin --delete <브랜치> && git branch -d <브랜치>
  ```
- `main`, `release/*`는 삭제 대상에서 항상 제외한다.

## 4. `battern` 패턴과의 대응표

| 항목 | `battern` | `malssi` (본 문서) |
|------|-----------|-------------------|
| 이슈 조회 | `gh issue list` | 이슈 목록 조회 (MCP/`gh`) — 동일 원칙 |
| 브랜치명 | 영어 또는 한글 (예: `fix/선-그리기-오류`) | 영어 타입 prefix 원칙 (예: `model/context-generation`) |
| 테스트 | `npm run test` (Vitest) | `flutter test` + `flutter analyze` |
| 커밋 메시지 | 한글 | 한글 — 동일 |
| PR | `gh pr create`, `Closes #N` 참조 | 동일 (MCP 또는 `gh`) |
| 머지 | 개발자만 수행 | 개발자만 수행 — 동일 |
| 작업 기록 | 없음 | 일일 기록 (`docs/progress/YYYY-MM-DD.md`, §5 참조) — `malssi` 추가 규칙 |

## 5. 일일 작업 기록 규칙

작업의 연속성을 위해 일자별 기록(`docs/progress/YYYY-MM-DD.md`)을 유지합니다.

### 5.1 매일 첫 작업 시 (LLM)

- 개발에 착수하기 전, 가장 최근의 일일 기록부터 역순으로 읽어 이전 작업 상태를 파악합니다.
  - 예: 오늘 9월 4일이면 `docs/progress/2026-09-03.md`부터 읽습니다.
  - 읽을 범위: 필요 시 최대 7일치. 이슈/PR 번호, 주요 결정 사항, 잔여 작업을 확인합니다.
- 기록에 남은 잔여 작업이 오늘 작업과 관련 있으면 이를 개발자에게 보고합니다.

### 5.2 날짜가 지난 기록의 커밋 (LLM)

- 날짜가 바뀐 뒤(또는 당일 작업 종료 시) 해당 날짜의 기록 파일이 있으면 반드시 커밋합니다.
  - 기록 형식: 개요, 이슈·PR 일람, 주요 결정 사항, 잔여 작업, 미커밋 잔여물.
  - 첫 기록이면 `docs/progress/` 디렉토리째 함께 추가합니다.
- 커밋은 단독으로 하거나 당일 마지막 작업 커밋에 포함합니다.
  - 단독 커밋 메시지 예시: `9월 3일 작업 기록 추가`
- 푸시까지 완료한 뒤 작업 종료를 알립니다 (`작업 완료 후` 규칙과 동일).

## 6. 버전 단위 릴리스 흐름 (1.0.2에서 확정)

> 한 버전에 여러 이슈를 묶어 내는 흐름입니다. 1.0.2(2026-09-11~12) 진행
> 방식을 기준으로 정리하며, 이후 버전도 동일하게 따릅니다.

```
[이슈 묶음 등록 + 마일스톤] → [작업 순서 확정] → [기능별 브랜치·PR (base=release/*)]
    → [리뷰·머지] → [버전 상향 + 출시노트] → [릴리스 PR (release/* → main)]
    → [테스트·머지] → [태그 + GitHub Release] → [이슈 정리]
```

### 6.1 이슈 묶음과 마일스톤 (개발자 + LLM)

- 버전 범위를 이슈 묶음으로 등록하고 `vX.Y.Z` 마일스톤을 붙입니다.
- 마일스톤에 없는 버전이 필요하면 새로 만듭니다 (예: 1.0.4 신설 후 #139 이동).
- LLM은 의존 순서(기반 버그 → 의존 기능 → 독립 UI 순)로 작업 순서를 정해
  개발자 확인을 받고 착수합니다.

### 6.2 기능 개발·머지 (LLM + 개발자)

- 기능별 브랜치 → PR (`base=release/*`, 스택 금지 — §2.7과 동일).
- 충돌 PR은 로컬에서 `rebase`로 동기화합니다. 이때 테스트·코드 양쪽 충돌을
  모두 살리고(union), `flutter analyze` + `flutter test` 통과 후
  `push --force-with-lease`로 갱신합니다.
  (`rebase --continue`가 비정상 거부되면 수동 커밋 + `rebase --quit`으로 마무리.)
- GitHub 웹 머지가 실패하면 로컬에서 `--no-ff` 머지 후 푸시합니다.
  머지 커밋 메시지는 `Merge pull request #N from <owner>/<branch>` 형식을 유지합니다.
- 머지는 개발자만 수행합니다 (LLM 자율 머지 금지 — §2.8과 동일).

### 6.3 출시 준비 (LLM)

- 버전 상향 커밋: `pubspec.yaml`을 다음 버전으로 올립니다
  (예: `1.0.1+2` → `1.0.2+3`. 빌드 번호는 스토어 업로드 순번을 잇습니다).
- 출시노트 커밋: `docs/releases/X.Y.Z.md`를 작성합니다 (1.0.1 형식 계승 —
  스토어 `복붙용` 블록 + PR·이슈 매핑표 + 검증 결과 + 출시 체크리스트).
- **출시노트는 `main`으로 머지하는 릴리스 PR에 포함되어야 합니다.**
  별도 PR로 분리하지 말고 릴리스 브랜치(`release/*`)에 커밋합니다.

### 6.4 릴리스 PR·배포 (개발자 + LLM)

- 릴리스 PR (`release/*` → `main`)을 만들고 실기기 테스트 후 한 번에 머지합니다
  (개발자가 직접 테스트·머지).
- 머지 후 태그 + GitHub Release를 발행합니다:
  ```sh
  git tag vX.Y.Z origin/main
  git push origin vX.Y.Z
  gh release create vX.Y.Z --title "말씨 X.Y.Z" --notes "..."
  ```
- Release 본문 양식 (1.0.1 계승, 2026-09-12 확정 — `docs/releases/*.md` 통째가 아님):
  ```
  말씨 X.Y.Z입니다.

  • 사용자 눈높이 변경점 1
  • 사용자 눈높이 변경점 2
  …

  포함: #PR 짧은 설명 · #PR 짧은 설명 · …
  ```
  - 제목은 `말씨 X.Y.Z`, 본문은 도입문 + 불릿 + `포함:` 한 줄.
  - `docs/releases/X.Y.Z.md`의 스토어 `복붙용` 블록도 동일 양식으로 둔다.
- 완료된 이슈를 `completed`로 닫고, 다음 버전 마일스톤 이월 여부를 확인합니다.

### 6.5 릴리스 브랜치 스위프 (출시 PR 전, 2026-10-04 확정)

- 머지済 작업 브랜치를 원격·로컬에서 일괄 삭제한다. 조건과 금지가 있다:
  - 보호 목록: `main`, `release/*` — 어떤 경우에도 삭제 금지.
    매칭은 **prefix**로 한다 (`release/`로 시작하는지).
    정확일치 앵커(`^(main|release/)$` 등)를 쓰면 `release/1.1.0` 같은
    브랜치가 제외되지 않아 원격 릴리스 브랜치를 통째로 날린다 (1.1.0 전례).
  - 삭제 조건: `origin/main` 또는 `origin/release/X.Y.Z`의 ancestor인 것만
    (`git merge-base --is-ancestor <브랜치> <기준>` 확인).
  - 비조상 브랜치(리베이스·스쿼시로 SHA가 바뀐 구 브랜치 등)는 삭제하지 않고
    목록으로 보고한다.
- 삭제 후 `git ls-remote origin "refs/heads/release/*"`로 릴리스 브랜치
  생존을 확인한다.
- 실수 삭제 시 로컬 브랜치에서 복원하고 (`git push origin <브랜치>`)
  닫힌 출시 PR은 `gh pr reopen`으로 되살린다.
