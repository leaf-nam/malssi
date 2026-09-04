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
- **라우팅**: `lib/routing/app_router.dart`의 `appRouter`(`GoRouter`, `initialLocation: '/'`).
  3탭 체제 목표 라우트: `/` (`SeedScreen`, 메인), `/archive` (`ArchiveScreen`, 보관),
  `/settings` (`SettingsScreen`, 설정). `/auth` (LoginScreen) 잔류 여부는
  설정 저장 방식 결정 시 확정한다.
  구 라우트(`/home`, `/quote-detail/:quoteId`, `/category`, `/write`, `/liked`, `/mypage`)는
  구현 브랜치에서 제거 예정이며, 현 코드에는 아직 남아 있다.
- **상태 관리 (혼용 상태)**: `provider`(`AppShell`의 `MultiProvider`,
  각 화면의 `context.watch`/`context.read`)와
  `riverpod`(`home_providers.dart`의 `StateNotifierProvider`/`StreamProvider`)가 혼용됩니다.
  `pubspec.yaml`에서 `provider`는 정식 의존성, `riverpod`는 `dev_dependencies`에 있습니다.
- **데이터 계층**: feature별 `*_repository.dart` 추상 클래스.
  3탭 신규: `SeedRepository`, `FruitRepository`, `SettingsRepository`
  (`lib/features/{seed,archive,settings}/data/` 예정).
  구 repository (`QuoteRepository`, `UserRepository`, `HashtagRepository`,
  `SubmissionRepository`) 중 `QuoteRepository`는 씨앗의 명언 원천 조회 용도로만 유지하고
  나머지는 구 화면과 함께 폐기 예정 (`feature_spec.md` §5 참조).
- **저장 계층**: Firestore 컬렉션 9종 (`auth/quotes/comments/categories/submissions/users` +
  신규 `seeds/fruits/settings`, `CollectionNames` 참조).
  구 컬렉션(`comments/categories/submissions`)은 구 화면 폐기 후 사용처가 없으며,
  데이터 마이그레이션/삭제는 별도 이슈로 분리한다.
  Firebase Auth는 `DummyAuthService`로 대체 중.
- **저장 계층**: Firestore 컬렉션 9종 (`auth/quotes/comments/categories/submissions/users` +
  신규 `seeds/fruits/settings`, `CollectionNames` 및 `FirestoreRefs` 참조).
  구 컬렉션(`comments/categories/submissions`)의 데이터 처리는 별도 이슈로 분리한다.
  Firebase Auth는 `DummyAuthService`로 대체 중.
- **공용 서비스 (싱글톤)**: `AdService` (보상형 광고 로드/표시 스텁),
  `NotificationService` (`flutter_local_notifications` 기반 초기화/예약/표시).
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
│   quote (Quote 모델 + quotes 원천 조회, 화면 없음)            │
│   [폐기 예정] home/category/my_quote/liked/mypage/           │
│     quote_detail/auth — 구현 브랜치에서 제거                  │
├──────────────────────────────────────────────────────────────┤
│  Core: constants(CollectionNames)  services(AdService —      │
│    미사용 예정, NotificationService — 일일 반복으로 확장,    │
│    FirestoreRefs)  theme(AppTheme)  widgets(3탭 BottomNav)   │
│  Storage: Firestore (quotes—명언 원천 / seeds / fruits /     │
│    settings + 구 컬렉션 정리 예정)                            │
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
  3탭 체제의 feature명: `seed`, `archive`, `settings`
  (예: `lib/features/seed/presentation/seed_screen.dart`).
- 공용 코드는 `core/{constants,services,theme,widgets}`에 둡니다.
  (`core/widgets/`에 3탭 BottomNav 배치 — 기존 `MvpBottomNav` 5탭 교체.)
- `Quote` 기본 클래스는 예외적으로 `lib/features/quote.dart`에 위치합니다
  (향후 `core/` 또는 `features/quote/domain/` 이동 검토 가능 — 아키텍처 이슈로 분리).
  3탭 체제에서 `Quote`는 화면 없는 명언 원천 모델로 유지합니다.
- 구 feature (`home`, `category`, `my_quote`, `liked`, `mypage`, `quote_detail`)는
  폐기 예정이며 신규 코드에서 참조하지 마십시오. 제거는 구현 브랜치에서 수행합니다
  (`feature_spec.md` §5 참조).
- 라우트는 `lib/routing/app_router.dart`의 `GoRoute`에 등록합니다.
  목표 라우트: `/`, `/archive`, `/settings` (+ `/auth` 잔류 여부 미정).

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

### 2.4 광고 (`AdService` — #19에서 삭제됨)

- 씨앗 개봉 플로우에 광고 게이트가 없으므로 `lib/core/services/ad_service.dart`를
  #19에서 삭제했다. 광고를 다시 도입하려면 신규 이슈 + 본 스펙 개정부터 시작한다.

## 3. 확장 계획

1. **3탭 구현체**: `SeedRepository`/`FruitRepository`/`SettingsRepository`의
   Firestore(또는 InMemory 선행) 구현체 작성 (`model_spec.md` §4.8~§4.10, §5 참조).
   화면은 `SeedScreen`/`ArchiveScreen`/`SettingsScreen` + 3탭 BottomNav 교체,
   라우트 `/`·`/archive`·`/settings` 등록.
2. **구 탭/화면 정리** (#19에서 완료): `home`(화면·Provider·`HomeQuote`)/`category`/
   `my_quote`/`liked`/`mypage`/`quote_detail` feature, 구 라우트(`/home`,
   `/quote-detail/:quoteId`, `/category`, `/write`, `/liked`, `/mypage`),
   `MvpBottomNav` 5탭, `AdService`, 구 Provider·구 화면 테스트 제거.
   `Quote` 모델·`quotes` 조회(`lib/features/quote.dart`,
   `lib/features/home/data/quote_repository.dart`)는 씨앗 탭의 명언 원천으로 유지.
   구 컬렉션(`comments`/`categories`/`submissions`) 데이터 처리는 별도 이슈로 분리.
3. **`NotificationService` 일일 반복 확장**: `scheduleDailySeedNotification()` 등
   매일 `seedTime` 발송 + 알림 탭 → `/` 이동 연결, 권한 요청 플로우, 타임존 처리.
4. **설정 저장 방식 결정**: Firestore `settings` vs 로컬 저장, `/auth` 잔류 여부,
   비로그인 시 폴백 규칙 확정.
5. **충실도 기록 + 성장 연출 (후속)**: `Fruit`에 `fidelityScore`/`memo` 추가,
   씨앗→식물 성장 단계 UI, 열매 상세 화면 (`feature_spec.md` §1·§2 향후 과제 참조).
6. **`riverpod` 의존성 정리**: `dev_dependencies` → 정식 `dependencies` 승격 여부 결정.
7. **`Quote` 기본 클래스 위치 정리**: `lib/features/quote.dart` → 공용 위치 이동 검토.
8. **`FirestoreRefs` 상수화**: 문자열 리터럴 → `CollectionNames` 교체
   (신규 `seeds`/`fruits`/`settings` 포함).
9. **`User`/`Submission` 모델 클래스 신설**: 구 화면 폐기로 보류 — 필요시 재검토.
10. **테스트 보강**: `Seed`/`Fruit`/`AppSettings` 직렬화 단위 테스트,
    씨앗 생성→개봉→수확 플로우 테스트 추가.
