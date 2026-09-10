# malssi Architecture Specification (시스템 아키텍처 스펙)

> AI 에이전트용 개발 하네스 문서 중 하나입니다. 코드 수정 전 반드시 본 문서를 읽으십시오.
> 상위 지침: `AGENTS.md`. 관련: `docs/context/model_spec.md`, `docs/conventions/convention.md`.
> 본 문서는 `battern` 프로젝트의 `architecture.md` 패턴(현재 구조 분석 + 다이어그램 +
> 확장 계획 + 외부 연동 규격)을 Flutter/Firestore 스택에 맞게 적용한 것입니다.

## 1. 시스템 아키텍처

### 1.1 현재 아키텍처 분석

`malssi`는 Flutter 기반 명언 공유 앱입니다. feature-based 디렉토리 구조를 사용합니다.

- **진입점**: `lib/main.dart`의 `main()`이 `NotificationService` 초기화 →
  번들 명언 로드(`QuoteAssets`) → 로컬 저장소(`PrefsLocalStore`) 복원 →
  `AppShell` 실행 순으로 시작합니다.
- **앱 셸**: `lib/app.dart`의 `AppShell`(`StatelessWidget`)이 `MultiProvider`
  (저장소 + `Seed`/`Archive`/`Settings`/`Onboarding` Provider, `DummyAuthService`,
  `DebugUiProvider`)로 감싼 `MaterialApp.router`를 제공합니다.
  `SettingsProvider`에는 씨앗 알림 재예약 콜백(`NotificationService` 연결)이 주입됩니다.
- **라우팅**: `lib/routing/app_router.dart`의 `appRouter`(`GoRouter`, `initialLocation: '/'`).
  3탭은 `StatefulShellRoute.indexedStack` + `AppShellView` 셸 구조 (#79):
  `MainBottomNav` 1개가 셸에 상주하고 `goBranch`로 내용만 교체한다.
  탭별 분기: `/` (`SeedScreen`, 말씨), `/archive` (`ArchiveScreen`, 정원),
  `/settings` (`SettingsScreen`, 설정). `/auth` (LoginScreen)와
  `/onboarding` (첫 실행 도움말, #130)은 셸 밖에 둔다.
  셸에서는 화면이 계속 살아있어 탭 진입 시 `initState`가 돌지 않으므로,
  셸 탭 핸들러에서 명시적으로 새로고침한다 (말씨 `refreshGrowth()`·정원 `load()`, #62 계승).
  구 라우트(`/home`, `/quote-detail/:quoteId`, `/category`, `/write`, `/liked`, `/mypage`)는
  #19에서 제거 완료했다.
- **상태 관리**: `provider` + `ChangeNotifier` + `context.watch`/`context.read`
  단일 패턴 (`AppShell`의 `MultiProvider`, 각 화면·Provider).
  `riverpod`는 `dev_dependencies`에 잔류하지만 `lib/`에서 import하지 않으므로
  신규 코드에서 사용하지 마십시오 (정식 의존성 승격·제거 여부는 아키텍처 이슈로 분리).
- **데이터 계층**: feature별 `*_repository.dart` 추상 클래스 +
  `InMemory*` 구현체 (`lib/features/{seed,archive,settings}/data/`).
  `QuoteRepository` (`lib/features/home/data/quote_repository.dart`)는 씨앗의 명언 원천
  조회 용도로만 유지한다 (`getRandomQuoteByTheme` 포함).
  구 repository (`UserRepository`, `HashtagRepository`, `SubmissionRepository`)와
  구 화면은 #19에서 제거 완료했다 (`feature_spec.md` §6 참조).
- **저장 계층**: 로컬 저장 (`SharedPreferences` + JSON, #122).
  `seeds`/`fruits`/`settings`를 `CollectionNames` 키 그대로 저장하고
  (`LocalStore`, `core/services/local_store.dart`),
  `InMemory*` 저장소가 변경마다 저장·시작 시 복원한다.
  온보딩 완료 여부도 같은 `SharedPreferences`를 공유한다 (#130).
  Firebase Auth는 `DummyAuthService`로 대체 중.
- **공용 서비스 (싱글톤)**: `AdService` (보상형 광고 로드/표시 스텁),
  `NotificationService` (`flutter_local_notifications` 기반 초기화/예약/표시),
  `DebugClock` (디버그 시간 이동용 앱 공용 시계, #115).
- **테마**: `AppTheme.light()` (indigo primary, grey[50] 배경, ElevatedButton/InputDecoration 테마),
  `AppTheme.dark()` (dark 복사 + grey[900] 배경).

```
┌──────────────────────────────────────────────────────────────┐
│                    Flutter App (UI + Routing)                │
│   main.dart (MyApp) → app.dart (AppShell: MultiProvider)     │
│   routing/app_router.dart (GoRouter: / /archive /settings)   │
│   ┌────────────┐ ┌─────────────┐ ┌────────────────────────┐  │
│   │ SeedScreen │ │ArchiveScreen│ │ SettingsScreen         │  │
│   │ (메인)     │ │ (보관)      │ │ (설정)                 │  │
│   └─────┬──────┘ └──────┬──────┘ └───────────┬────────────┘  │
└─────────┼───────────────┼────────────────────┼───────────────┘
          ▼               ▼                    ▼
┌─────────┴───────────────┴────────────────────┴───────────────┐
│              Feature Modules (features/<feature>/)           │
│   seed (SeedRepository/SeedProvider)                          │
│   archive (FruitRepository/ArchiveProvider)                  │
│   settings (SettingsRepository + NotificationService 연동)   │
│   onboarding (OnboardingRepository/OnboardingProvider, #130) │
│   quote (Quote 모델 + quotes 원천 조회, 화면 없음)            │
├──────────────────────────────────────────────────────────────┤
│  Core: constants(CollectionNames)  services(NotificationService —│
│    일일 반복 + inexact 모드, FirestoreRefs, LocalStore,      │
│    DebugClock)  theme(AppTheme)  widgets(3탭 BottomNav)      │
│  Storage: 로컬 (SharedPreferences + JSON: seeds / fruits /  │
│    settings + 온보딩 플래그, 명언 원천은 번들, #122·#130)     │
└──────────────────────────────────────────────────────────────┘
```

> 2026-09-04 개정: 3탭 다이어그램으로 교체. 구 5탭(`HomeScreen`/`CategoryScreen`/
> `WriteScreen`/`LikedScreen`/`MyPageScreen` + `MvpBottomNav`) 다이어그램은 폐기.

### 1.2 디렉토리 규칙

```
lib/
  main.dart                # 진입점 (MyApp)
  app.dart                 # AppShell (MultiProvider + MaterialApp.router)
  routing/app_router.dart  # GoRoute 등록 (신규 화면은 여기에 추가)
  core/
    constants/             # CollectionNames 등 공용 상수
    services/              # AdService, NotificationService, FirestoreRefs (싱글톤)
    theme/                 # AppTheme (light/dark)
    widgets/               # 공용 위젯 (현재 비어 있음)
  features/
    <feature>/
      data/                # Repository 추상/구현, Service (예: quote_repository.dart)
      domain/              # 도메인 모델 (예: quote.dart, comment.dart)
      presentation/        # Screen/Widget (예: home_screen.dart)
      providers/           # 상태 관리 (예: home_providers.dart)
```

- 새 기능은 `features/<feature>/{data,domain,presentation,providers}` 4계층으로 추가합니다.
  3탭 체제의 feature명: `seed`, `archive`, `settings`, `onboarding`
  (예: `lib/features/seed/presentation/seed_screen.dart`).
- 공용 코드는 `core/{constants,services,theme,widgets}`에 둡니다.
- `Quote` 기본 클래스는 예외적으로 `lib/features/quote.dart`에 위치합니다
  (향후 `core/` 또는 `features/quote/domain/` 이동 검토 가능 — 아키텍처 이슈로 분리).
  3탭 체제에서 `Quote`는 화면 없는 명언 원천 모델로 유지합니다.
  명언 원천 조회는 `lib/features/home/data/quote_repository.dart` +
  번들 로더 `quote_assets.dart` (`assets/docs/quotes.json`, #123).
- 구 feature (`home` 화면·Provider, `category`, `my_quote`, `liked`, `mypage`,
  `quote_detail`)는 #19에서 제거 완료했다. 신규 코드에서 참조하지 마십시오.
- 라우트는 `lib/routing/app_router.dart`의 `GoRoute`에 등록합니다.
  현재 라우트: `/`, `/archive`, `/settings` (셸 3탭) + 셸 밖 `/auth`, `/onboarding`.

### 1.3 의존성 관리 (`pubspec.yaml`)

| 패키지 | 버전 | 용도 | 비고 |
|--------|------|------|------|
| `flutter` | SDK | 프레임워크 | `uses-material-design: true` |
| `provider` | `^6.0.0` | 상태 관리 (주) | `AppShell` MultiProvider, 화면 watch/read |
| `go_router` | `^13.2.0` | 라우팅 | `appRouter` |
| `firebase_core` | `^2.24.2` | Firebase 초기화 | `lib/`에서 미사용 중. Auth/Firestore 실연동 시 사용 |
| `flutter_local_notifications` | `^22.3.0` | 로컬 알림 | `NotificationService` (v22 named-parameter API) |
| `timezone` | `^0.11.1` | 알림 예약 시각 | `zonedSchedule`용 타임존 |
| `share_plus` | `^10.1.2` | 공유 | `lib/`에서 미사용 중. 보관 상세 편입 여부는 후속 이슈에서 결정 (`feature_spec.md` §6 #6) |
| `shared_preferences` | `^2.5.5` | 로컬 지속화 | `LocalStore` (씨앗·열매·설정·온보딩, #122·#130) |
| `riverpod` (`dev`, 미사용) | `^2.4.9` | — | `lib/`에서 import 없음. 승격·제거 여부 이슈 분리 |
| `build_runner` (`dev`) | `^2.4.6` | 코드 생성 | — |
| `flutter_test` (`dev`) | SDK | 테스트 | `flutter test` |
| `flutter_lints` | — | 린트 | `analysis_options.yaml`에서 include |

신규 의존성 추가 시 `flutter pub get` 실행 후 `pubspec.lock` 변경분을 함께 커밋합니다.

## 2. 외부 연동 규격

### 2.1 Firestore

- 컬렉션명: `CollectionNames` 상수 사용 (`docs/context/model_spec.md` §2 참조).
- 문서 스키마: `model_spec.md` §4의 모델별 필드표 준수.
- `createdAt`은 Firestore `Timestamp` ↔ Dart `DateTime` 변환 규칙 준수.

### 2.2 Firebase Auth (예정)

- 현재 `DummyAuthService` 스텁 상태. 실제 연동 시 `firebase_core` 초기화 후
  `firebase_auth` 의존성 추가 및 `auth` 컬렉션 스키마 확정이 필요합니다.

### 2.3 로컬 알림 (`NotificationService`)

- 채널: `channel_id`/`channel_name` (Android, high importance/priority).
- 초기화: `init()`에서 `AndroidInitializationSettings('@mipmap/ic_launcher')` +
  타임존 초기화. 실패해도 앱 시작을 막지 않는다 (`main()`에서 try/catch).
- API: `scheduleNotification({id, title, body, scheduleTime})` (1회),
  `scheduleDailySeedNotification({id, title, body, hour, minute})`
  (매일 반복, `matchDateTimeComponents: time`),
  `scheduleSeedCompleteNotification({id, title, body, completeAt})`
  (씨앗 완성 1회, #140 — 이미 지났으면 예약 안 함),
  `showLocalNotification({id, title, body})`, `cancelSeedNotification(id)`.
  씨앗 도착 알림 ID는 `seedNotificationId` (1001),
  완성 알림 ID는 `seedCompleteNotificationId` (1002).
  알림 탭 → `/` 이동은 `init(onTap:)` 주입으로 연결한다 (`main()` → `appRouter`).
- 스케줄 모드: `inexactAllowWhileIdle` 고정 (#137).
  `SCHEDULE_EXACT_ALARM` 권한이 필요 없고 수분 오차가 날 수 있다
  (일일 씨앗 알림 용도로 허용).

### 2.4 광고 (`AdService` — #19에서 삭제됨)

- 씨앗 개봉 플로우에 광고 게이트가 없으므로 `lib/core/services/ad_service.dart`를
  #19에서 삭제했다. 광고를 다시 도입하려면 신규 이슈 + 본 스펙 개정부터 시작한다.

## 3. 확장 계획

1. **3탭 구현체** (완료): `SeedRepository`/`FruitRepository`/`SettingsRepository`
   (`InMemory*` + `LocalStore` 지속화) 및
   `SeedScreen`/`ArchiveScreen`/`SettingsScreen` + 3탭 BottomNav,
   라우트 `/`·`/archive`·`/settings` 등록. 온보딩(`/onboarding`, #130) 포함.
2. **구 탭/화면 정리** (#19에서 완료): `home`(화면·Provider·`HomeQuote`)/`category`/
   `my_quote`/`liked`/`mypage`/`quote_detail` feature, 구 라우트(`/home`,
   `/quote-detail/:quoteId`, `/category`, `/write`, `/liked`, `/mypage`),
   `MvpBottomNav` 5탭, `AdService`, 구 Provider·구 화면 테스트 제거.
   `Quote` 모델·`quotes` 조회(`lib/features/quote.dart`,
   `lib/features/home/data/quote_repository.dart`)는 씨앗 탭의 명언 원천으로 유지.
   구 컬렉션(`comments`/`categories`/`submissions`) 데이터 처리는 별도 이슈로 분리.
3. **`NotificationService` 일일 반복** (발송 완료, #137):
   `scheduleDailySeedNotification()`으로 매일 `seedTime` 발송.
   스케줄 모드는 `inexact` 고정이라 권한 요청 플로우 불필요.
   남은 과제: 알림 탭 → `/` 이동 연결.
4. **저장 방식 결정** (#122에서 로컬로 확정): `seeds`/`fruits`/`settings`는
   `SharedPreferences` + JSON (`LocalStore`, `core/services/local_store.dart`)에
   저장한다. `InMemory*` 저장소가 `store` 연결 시 변경마다 저장하고,
   `main()` 시작 시 1회 복원한다. Firestore 연동은 동기화·공유 수요 발생 시
   별도 이슈로 분리한다. `/auth` 잔류 여부, 비로그인 시 폴백 규칙은 미확정.
5. **성장 연출 후속** (`fidelityScore`/`memo`·성장 단계 UI·열매 상세는 구현됨):
   남은 과제(`feature_spec.md` §1·§2 향후 과제 참조).
6. **`riverpod` 의존성 정리**: `lib/`에서 미사용 중. 정식 승격 vs 제거 결정.
7. **`Quote` 기본 클래스 위치 정리**: `lib/features/quote.dart` → 공용 위치 이동 검토.
8. **`FirestoreRefs` 신규 컬렉션 경로**: `CollectionNames` 상수화는 완료.
   `seeds`/`fruits`/`settings` 경로 상수 추가 여부 결정.
9. **`User`/`Submission` 모델 클래스 신설**: 구 화면 폐기로 보류 — 필요시 재검토.
10. **테스트 보강**: 현재 153개 통과. 신규 기능 추가 시 회귀 테스트 함께 작성.
