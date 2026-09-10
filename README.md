# malssi (말씨) — 오늘의 한 문장, 씨앗 키우기 앱

Flutter 기반 3탭(말씨/정원/설정) 앱입니다. 저장은 `SharedPreferences` + JSON
로컬 지속화(`LocalStore`, #122)로 동작합니다.

## 주요 기능 (3탭)

| 기능 | 상태 |
|------|------|
| 말씨(`/`) · 오늘의 씨앗 심기→성장(2시간 간격 0~5단계)→수확·후기 | 구현됨 |
| 정원(`/archive`) · 연도별 잔디 그리드 + 읽기 전용 후기 카드 + 열매 비 | 구현됨 |
| 설정(`/settings`) · 씨앗 생성 시간·매일 알림·화면 모드·열매 비 효과 | 구현됨 |
| 첫 실행 도움말(`/onboarding`) | 구현됨 (#130) |
| 씨앗 도착 일일 알림 (`inexact`, 권한 불필요) | 구현됨 (#137) |
| 그날의 명언 직접 작성 | 미착수 (#129) |

서버 백엔드(Firebase 포함)는 사용하지 않는다. 모든 기록은 단말 로컬 저장이다.

## 시작하기

```sh
flutter pub get
flutter analyze   # 0 issues 필수
flutter test      # 전체 통과 필수
flutter run -d macos   # 또는 -d chrome
```

## 프로젝트 구조

```
lib/
  main.dart / app.dart        # 진입점, AppShell(MultiProvider + router)
  routing/app_router.dart     # /, /archive, /settings (+ 셸 밖 /auth, /onboarding)
  core/{constants,services,theme,widgets}
  features/<feature>/{data,domain,presentation,providers}  # seed, archive, settings, onboarding (+ 명언 원천 quote/home)
test/                         # 화면·저장소·에셋 단위 테스트 (153개)
assets/fonts/                 # Galmuri11 번들 (OFL)
android/                      # Android 플랫폼 폴더 (Play 번들용, 키 제외)
docs/                         # 아래 문서 인덱스 참조
```

## 문서 (개발 하네스)

AI 에이전트 및 기여자는 코드 수정 전 아래 문서를 먼저 읽어주세요
(상위 지침: `AGENTS.md`).

- `AGENTS.md` — 에이전트 지침·워크플로우 요약
- `docs/context/model_spec.md` — 도메인 모델·Firestore 스펙
- `docs/architecture/architecture_spec.md` — 아키텍처·의존성·확장 계획
- `docs/workflow/development_flow.md` — 이슈 기반 개발·브랜치·PR 절차
- `docs/features/feature_spec.md` — 3탭 기능 명세·구현 상태
- `docs/conventions/convention.md` — 코드 컨벤션
- `docs/progress/` — 일자별 작업 기록

## 개발 방식

모든 작업은 GitHub 이슈 기반으로 진행합니다
(이슈 등록 → 개발자 확인 → 브랜치 → 개발 → PR → 개발자 승인·머지).
상세 절차는 `docs/workflow/development_flow.md`를 따릅니다.
