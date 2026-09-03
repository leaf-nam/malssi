# malssi (말씨) — 오늘의 한 문장, 명언 공유 앱

Flutter 기반 명언 공유 앱의 MVP입니다. Firebase 실연동 전까지 인메모리 저장소로 동작합니다.

## 주요 기능 (MVP 상태)

| 기능 | 상태 |
|------|------|
| 홈 · 오늘의 명언 (랜덤 1개, 광고 보고 다음 명언, 연속 읽음) | MVP 구현 |
| 명언 상세 · 댓글 (베스트 3, 최근, 등록·좋아요) | MVP 구현 |
| 카테고리 (해시태그 그리드·전체 목록) | MVP 구현 |
| 내 명언 쓰기 (심사 요청, 상태 목록) | MVP 구현 |
| 마이페이지 (통계, 하루 1회 알림 토글·시간 설정) | MVP 구현 |
| 좋아요 목록 | MVP 구현 |
| 공유 (`share_plus`) | MVP 구현 (딥링크 수신 미포함) |
| Firestore/Auth 실연동, 실제 광고 SDK, 추천, 매일 반복 알림 | 후속 과제 (#1–#7) |

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
  routing/app_router.dart     # /, /home, /auth, /quote-detail/:quoteId, /category, /write, /liked, /mypage
  core/{constants,services,theme,widgets}
  features/<feature>/{data,domain,presentation,providers}
test/                         # widget + repository 단위 테스트
assets/fonts/                 # NotoSerifKR 번들 (OFL)
docs/                         # 아래 문서 인덱스 참조
```

## 문서 (개발 하네스)

AI 에이전트 및 기여자는 코드 수정 전 아래 문서를 먼저 읽어주세요
(상위 지침: `AGENTS.md`).

- `AGENTS.md` — 에이전트 지침·워크플로우 요약
- `docs/context/model_spec.md` — 도메인 모델·Firestore 스펙
- `docs/architecture/architecture_spec.md` — 아키텍처·의존성·확장 계획
- `docs/workflow/development_flow.md` — 이슈 기반 개발·브랜치·PR 절차
- `docs/features/feature_spec.md` — 7대 기능 명세·구현 상태
- `docs/conventions/convention.md` — 코드 컨벤션
- `docs/progress/` — 일자별 작업 기록

## 개발 방식

모든 작업은 GitHub 이슈 기반으로 진행합니다
(이슈 등록 → 개발자 확인 → 브랜치 → 개발 → PR → 개발자 승인·머지).
상세 절차는 `docs/workflow/development_flow.md`를 따릅니다.
