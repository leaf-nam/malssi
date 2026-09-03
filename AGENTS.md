# malssi 개발 하네스 — AI Agent 지침 및 Workflow 규칙

> **중요 (Mandatory)**: 이 프로젝트는 Flutter 기반 명언 공유 앱 `malssi`입니다.
> 문서에서 "하네스(Harness)"는 AI 에이전트(LLM)가 이 프로젝트를 개발할 때 읽고 따르는
> **개발 하네스(명세·규칙 컨텍스트 체계)**를 의미합니다.
> 에이전트는 모든 기능 구현, 아키텍처 확장, 모델/Firestore 설계 시 반드시 아래 명시된
> 명세 문서들을 가장 먼저 읽고 그 규범을 준수해야 합니다.
> 본 문서는 `battern` 프로젝트의 `AGENTS.md` / `workflow.md` / `architecture.md` 패턴을
> Flutter/Firestore 스택에 맞게 적용한 것입니다.

## 1. 필수 참조 명세 (Context Files)

모든 LLM 에이전트는 개발, 모델 설계, Firestore 마이그레이션, 워크플로우 적용 전에
다음 문서들을 반드시 읽어 컨텍스트로 확보해야 합니다.

*   **도메인 모델 정의서**: `docs/context/model_spec.md`
    *   **내용**: `Quote`(기본 추상 클래스), `HomeQuote`(확장), `Comment`,
        `User`(프로필 Map), `Hashtag/Category`, `Submission`의 공식 스펙.
        Firestore 컬렉션명(`CollectionNames`), `fromMap`/`toMap`/`copyWith`
        직렬화 규칙, Timestamp 변환 규칙.
*   **시스템 아키텍처 스펙**: `docs/architecture/architecture_spec.md`
    *   **내용**: feature-based 프로젝트 구조(`lib/features/*`, `lib/core/*`,
        `lib/routing/*`), 계층 규칙(data/domain/presentation/providers),
        의존성(`provider`, `go_router`, `firebase_core`, `flutter_local_notifications`,
        `riverpod`), 라우팅 및 싱글톤 서비스(`AdService`, `NotificationService`,
        `FirestoreRefs`) 규격.
*   **개발 워크플로우**: `docs/workflow/development_flow.md`
    *   **내용**: 이슈 기반 개발 사이클(브랜치/TDD/`flutter test`·`flutter analyze`/PR 검토·승인),
        브랜치 네이밍, 커밋 메시지, 푸시/PR 절차. `battern` 프로젝트 패턴과 일치.
*   **주요 기능 명세서**: `docs/features/feature_spec.md`
    *   **내용**: 오늘의 명언(랜덤 1개 + 교체 시 광고)/내 명언(관리자 승인)/명언 댓글(베스트 3개)/
        카테고리(해시태그)/좋아요·추천/공유(딥링크)/하루 1회 알림의 요구·구현 상태·관련 코드·향후 과제.
*   **코드 컨벤션**: `docs/conventions/convention.md`
    *   **내용**: Dart/Flutter 스타일, 네이밍 컨벤션, 상태 관리(`provider` + `riverpod`
        혼용 현황 및 지향점), 테마(`AppTheme`), 에러/로딩 처리 패턴.

---

## 2. LLM 에이전트 개발 행동 강령

1.  **컨텍스트 우선 로드**: `lib/features/*`, `lib/core/*`, `lib/routing/app_router.dart`,
    `lib/app.dart`, `lib/main.dart`를 수정하기 전, 무조건 해당 영역의 개별 명세서
    (`docs/context/model_spec.md`, `docs/architecture/architecture_spec.md`,
    `docs/workflow/development_flow.md`, `docs/conventions/convention.md`)들을
    먼저 읽어 최신 스펙을 싱크하십시오.
2.  **모델 무결성**: 모든 Firestore 직렬화는 `model_spec.md`의
    `fromMap`/`toMap`/`copyWith` 규칙과 `createdAt` Timestamp 변환
    (`(map['createdAt'] as dynamic).toDate() ?? DateTime.now()`)을 준수해야 합니다.
    컬렉션명은 반드시 `CollectionNames` 상수(`auth/quotes/comments/categories/submissions/users`)를
    사용하십시오. 하드코딩된 컬렉션 문자열을 새로 만들지 마십시오.
3.  **아키텍처 무결성**: feature-based 구조를 유지하십시오.
    새 기능은 `features/<feature>/{data,domain,presentation,providers}` 4계층으로 추가하고,
    공용 코드는 `core/{constants,services,theme,widgets}`에 두십시오.
    라우트는 `lib/routing/app_router.dart`의 `GoRoute`에 등록하십시오.
4.  **상태 관리 일관성**: 현재 `provider`(`AppShell`의 `MultiProvider`)와
    `riverpod`(`home_providers.dart`의 `StateNotifierProvider`/`StreamProvider`)가 혼용되어 있습니다.
    기존 파일의 패턴을 유지하되, 신규 코드는 `convention.md`의 지향점을 따르십시오.
    `riverpod`를 `dev_dependencies`가 아닌 정식 의존성으로 둘지 여부는 아키텍처 이슈로
    분리하여 논의하십시오 (현재 `pubspec.yaml`에서 `riverpod`는 `dev_dependencies`에 있음).
5.  **테스트 필수**: 수정 후 반드시 `flutter analyze`와 `flutter test`를 실행하여
    회귀가 없는지 확인하십시오. PR 생성의 필수 조건입니다.

---

## 3. Workflow 규칙

모든 개발은 이슈 기반으로 진행합니다:
개발자 이슈 등록 → LLM이 이슈 목록 조회 및 제안 → 개발자 확인 후 이슈 선택 → 개발 → PR 생성 → 개발자 검토/승인.
상세 절차는 `docs/workflow/development_flow.md`를 따릅니다. 요약:

## 이슈
- 모든 개발 작업은 개발자가 GitHub에 등록한 이슈를 기준으로 시작할 것
- LLM은 이슈 목록 조회로 열린 이슈 목록을 조회하고, 우선순위 판단 근거와 함께 개발자에게 제시할 것
- 처리할 이슈는 반드시 개발자가 확인/지정한 것으로 확정하며, 승인 전에는 개발에 착수하지 말 것

## 브랜치
- 작업 시작 전에 항상 `main` 브랜치에서 새 브랜치를 생성할 것
- 브랜치 이름은 작업 내용을 나타내는 짧은 영어 타입 prefix + 설명으로 작성
  (예: `model/context-generation`, `feat/quote-like`, `fix/comment-screen`)
- 브랜치를 만들기 전 `git fetch origin`으로 최신 상태 확인

## 커밋
- 작업이 완료되면 적절한 커밋 메시지와 함께 커밋할 것
- 커밋 메시지는 어떤 작업을 했는지 알 수 있게 한글로 작성

## 푸시
- 커밋 후 항상 원격에 푸시(`git push origin <브랜치명>`)할 것

## PR
- 푸시 후 PR을 생성하고, 본문에 관련 이슈 번호(예: `Closes #8`)를 참조할 것
- PR 생성 전 반드시 `flutter analyze`와 `flutter test`를 통과했는지 확인할 것

## 승인
- 머지(승인)는 오직 개발자만 수행하며, LLM이 자율적으로 머지하지 말 것
- PR에 수정 요청이 있으면 피드백을 반영하여 다시 커밋/푸시할 것

## 작업 완료 후
- 모든 변경사항을 커밋하고 원격에 푸시한 뒤에 작업 완료를 알릴 것

## 일일 작업 기록
- 매일 첫 작업 전 가장 최근의 `docs/progress/YYYY-MM-DD.md`부터 역순으로 읽고 이전 상태를 파악할 것
- 날짜가 지난(또는 당일 종료 시) 기록 파일은 반드시 커밋·푸시할 것
- 상세: `docs/workflow/development_flow.md` §5

---

## 4. MCP 서버 사용 지침

opencode에 설치된 MCP 서버 구성과 각 서버의 용도입니다. 작업 성격에 맞는 서버를 우선 활용하십시오.

*   **context7** (remote): 라이브러리/프레임워크 공식 문서 조회.
    Flutter, `provider`, `riverpod`, `go_router`, `firebase_core`,
    `flutter_local_notifications` 등의 API 문법·설정·마이그레이션을 확인할 때
    웹 검색보다 우선 사용.
*   **github** (remote): 이슈/PR/커밋 조회 및 생성, 코드 검색, 리뷰 작업.
    `gh` CLI로 수행하던 GitHub 작업의 대체 수단.
*   **playwright** (local): 브라우저 자동화 기반 UI 검증.
    Flutter 웹 빌드(`flutter run -d chrome`) 결과물의 시각적 검증,
    스크린샷/접근성 스냅샷 확인, E2E 흐름 점검 시 사용.
