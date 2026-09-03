# malssi Architecture Specification (시스템 아키텍처 스펙)

> AI 에이전트용 개발 하네스 문서 중 하나입니다. 코드 수정 전 반드시 본 문서를 읽으십시오.
> 상위 지침: `AGENTS.md`. 관련: `docs/context/model_spec.md`, `docs/conventions/convention.md`.
> 본 문서는 `battern` 프로젝트의 `architecture.md` 패턴(현재 구조 분석 + 다이어그램 +
> 확장 계획 + 외부 연동 규격)을 Flutter/Firestore 스택에 맞게 적용한 것입니다.

## 1. 시스템 아키텍처

### 1.1 현재 아키텍처 분석

`malssi`는 Flutter 기반 명언 공유 앱입니다. feature-based 디렉토리 구조를 사용합니다.

- **진입점**: `lib/main.dart`의 `MyApp`(`StatelessWidget`) → `AppShell` 렌더링.
  현재 `MaterialApp(title: 'Flutter App', ...)` 직접 구성과
  `lib/app.dart`의 `AppShell`(`MaterialApp.router` + `MultiProvider`) 구성이 병존합니다.
- **앱 셸**: `lib/app.dart`의 `AppShell`(`StatefulWidget`)이 `GoRouterObserver`를 등록하고
  `MultiProvider(providers: [...])` (현재 비어 있음, core 서비스 주입 예정)로 감싼
  `MaterialApp.router`를 제공합니다.
- **라우팅**: `lib/routing/app_router.dart`의 `appRouter`(`GoRouter`, `initialLocation: '/home'`).
  등록된 라우트: `/` (HomeScreen), `/auth` (LoginScreen),
  `/quote-detail/:quoteId` (CommentScreen), `/mypage` (MyPageScreen).
- **상태 관리 (혼용 상태)**: `provider`(`AppShell`의 `MultiProvider`,
  각 화면의 `context.watch`/`context.read`)와
  `riverpod`(`home_providers.dart`의 `StateNotifierProvider`/`StreamProvider`)가 혼용됩니다.
  `pubspec.yaml`에서 `provider`는 정식 의존성, `riverpod`는 `dev_dependencies`에 있습니다.
- **데이터 계층**: feature별 `*_repository.dart` 추상 클래스
  (`QuoteRepository`, `UserRepository`, `HashtagRepository`, `SubmissionRepository`).
  `QuoteRepositoryImpl` 등 구현체는 아직 없습니다.
- **저장 계층**: Firestore 컬렉션 6종 (`auth/quotes/comments/categories/submissions/users`,
  `CollectionNames` 및 `FirestoreRefs` 참조). Firebase Auth는 `DummyAuthService`로 대체 중.
- **공용 서비스 (싱글톤)**: `AdService` (보상형 광고 로드/표시 스텁),
  `NotificationService` (`flutter_local_notifications` 기반 초기화/예약/표시).
- **테마**: `AppTheme.light()` (indigo primary, grey[50] 배경, ElevatedButton/InputDecoration 테마),
  `AppTheme.dark()` (dark 복사 + grey[900] 배경).

```
┌──────────────────────────────────────────────────────────────┐
│                    Flutter App (UI + Routing)                │
│   main.dart (MyApp) → app.dart (AppShell: MultiProvider)     │
│   routing/app_router.dart (GoRouter: / /auth                 │
│     /quote-detail/:quoteId /mypage)                          │
│   ┌────────────┐ ┌─────────────┐ ┌────────────────────────┐  │
│   │ HomeScreen │ │ LoginScreen │ │ CommentScreen /        │  │
│   │            │ │             │ │ MyPageScreen           │  │
│   └─────┬──────┘ └──────┬──────┘ └───────────┬────────────┘  │
└─────────┼───────────────┼────────────────────┼───────────────┘
          ▼               ▼                    ▼
┌─────────┴───────────────┴────────────────────┴───────────────┐
│              Feature Modules (features/<feature>/)           │
│   home (QuoteNotifier/StateNotifier + StreamProvider)        │
│   auth (DummyAuthService)  category (HashtagRepository)      │
│   my_quote (SubmissionRepository)  mypage (UserRepository)   │
│   quote_detail (Comment)                                     │
├──────────────────────────────────────────────────────────────┤
│  Core: constants(CollectionNames)  services(AdService,       │
│    NotificationService, FirestoreRefs)  theme(AppTheme)      │
│  Storage: Firestore (auth/quotes/comments/categories/       │
│    submissions/users) — Firebase Auth 연동 예정              │
└──────────────────────────────────────────────────────────────┘
```

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
- 공용 코드는 `core/{constants,services,theme,widgets}`에 둡니다.
- `Quote` 기본 클래스는 예외적으로 `lib/features/quote.dart`에 위치합니다
  (향후 `core/` 또는 `features/quote/domain/` 이동 검토 가능 — 아키텍처 이슈로 분리).
- 라우트는 `lib/routing/app_router.dart`의 `GoRoute`에 등록합니다.

### 1.3 의존성 관리 (`pubspec.yaml`)

| 패키지 | 버전 | 용도 | 비고 |
|--------|------|------|------|
| `flutter` | SDK | 프레임워크 | `uses-material-design: true` |
| `provider` | `^6.0.0` | 상태 관리 (주) | `AppShell` MultiProvider, 화면 watch/read |
| `go_router` | `^13.2.0` | 라우팅 | `appRouter` |
| `firebase_core` | `^2.24.2` | Firebase 초기화 | Auth/Firestore 연동 예정 |
| `flutter_local_notifications` | `^16.1.0` | 로컬 알림 | `NotificationService` |
| `riverpod` (`dev`) | `^2.4.9` | 상태 관리 (혼용) | 정식 의존성 승격 여부 이슈 분리 |
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
- 초기화: `init()`에서 `AndroidInitializationSettings('@mipmap/ic_launcher')`.
- API: `scheduleNotification({id, title, body, scheduleTime})`,
  `showLocalNotification({id, title, body})`.

### 2.4 광고 (`AdService`)

- 싱글톤 (`AdService.instance`). `loadAd()` → `showAd()` → 재로드 사이클의 스텁 구현.
  실제 AdMob 연동 시 본 스펙에 명세 추가 필요.

## 3. 확장 계획

1. **Repository 구현체**: `QuoteRepositoryImpl` 등 4개 repository의 Firestore 구현체 작성
   (`model_spec.md` §5 참조). `home_providers.dart`가 이미 `QuoteRepositoryImpl()`을 참조하므로 우선순위 높음.
2. **`riverpod` 의존성 정리**: `dev_dependencies` → 정식 `dependencies` 승격 여부 결정.
3. **`Quote` 기본 클래스 위치 정리**: `lib/features/quote.dart` → 공용 위치 이동 검토.
4. **`FirestoreRefs` 상수화**: 문자열 리터럴 → `CollectionNames` 교체.
5. **`HomeQuote.toMap()` 오버라이드**: `category`/`isFeatured` 직렬화 누락 해소.
6. **`User`/`Submission` 모델 클래스 신설**: 현재 Map 기반 → `fromMap`/`toMap`/`copyWith` 모델로 승격.
7. **테스트 보강**: `test/widget_test.dart` 카운터 템플릿 → 도메인 단위 테스트로 교체/확장.
