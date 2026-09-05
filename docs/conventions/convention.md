# malssi Code Convention (코드 컨벤션)

> AI 에이전트용 개발 하네스 문서 중 하나입니다. 상위 지침: `AGENTS.md`.
> 관련: `docs/architecture/architecture_spec.md`, `docs/context/model_spec.md`.
> `analysis_options.yaml`에서 `package:flutter_lints/flutter.yaml`을 include합니다.

## 1. Dart/Flutter 스타일

- `flutter_lints` 권장 린트를 따릅니다. `flutter analyze` 통과를 필수로 합니다.
- 파일명은 `snake_case.dart`, 클래스명은 `UpperCamelCase`, 변수/함수는 `lowerCamelCase`,
  상수는 `lowerCamelCase` 또는 `SCREAMING_CAPS` 관례가 아닌 기존 코드(`CollectionNames.auth` 등)를 따릅니다.
- import 순서: `flutter` → 서드파티(`provider`, `go_router`, `riverpod` 등) → `package:malssi/...`.
- 위젯 생성자는 `const` 가능하면 `const`로 선언하고 `super.key`를 받습니다.

## 2. 네이밍 컨벤션

- Screen: `<Name>Screen` (예: `SeedScreen`, `ArchiveScreen`, `SettingsScreen`).
  구 화면(`HomeScreen`, `LoginScreen` 제외 — `/auth` 유지,
  `MyPageScreen`, `CommentScreen`, `CategoryScreen`, `WriteScreen`, `LikedScreen`)은
  #19에서 제거됨.
- BottomNav: 3탭 고정 (`말씨`/`정원`/`설정` 라벨, `eco`/`grass`/`settings` 아이콘,
  `SeedScreen`/`ArchiveScreen`/`SettingsScreen` 순서, #45).
  크기: 아이콘 30·라벨 12.5·상단 패딩 8 (#60).
  바 배경: 말씨 `abyss`(양 모드) · 정원 흙색(라이트 `navGardenLight`/다크 `navGardenDark`) ·
  설정 회색(라이트 `navSettingsLight`/다크 `navSettingsDark`) (#75).
  전환은 250ms `AnimatedContainer` (#77).
  탭 추가·순서 변경 시 `feature_spec.md`와 본 문서 §6을 함께 개정하십시오.
- Repository: `<Name>Repository` 추상 클래스 + `<Name>RepositoryImpl` 구현체
  (예: `QuoteRepository` / `QuoteRepositoryImpl`).
- Provider/Notifier: `<Name>Provider`, `<Name>Notifier` (예: `randomQuoteProvider`, `QuoteNotifier`).
- 모델: `Quote`, `HomeQuote`, `Comment`, `Seed`, `Fruit`, `AppSettings`
  (+ 향후 `User`, `Submission` — 구 화면 폐기로 보류.
  `Hashtag`/`Category`와 `Quote.tags`는 미사용 확정으로 2026-09-05 제외).
- Firestore 컬렉션: `CollectionNames` 상수 경유 (문자열 리터럴 금지).

## 3. 상태 관리

- 현재 `provider`와 `riverpod`가 혼용되어 있습니다.
  - `provider`: `AppShell`의 `MultiProvider`, 각 화면의 `context.watch<T>()` / `context.read<T>()`.
  - `riverpod`: `home_providers.dart`의 `StateNotifierProvider` (`QuoteNotifier`),
    `StreamProvider` (`likedQuotesStreamProvider`).
- 기존 파일의 패턴을 유지하십시오. 새 파일에서는 화면 상태 구독에 `provider` +
  `ChangeNotifier` + `context.watch`/`context.read` 패턴(구 `home_screen.dart`가 쓰던 방식)을 따르고,
  비동기 스트림에는 `StreamProvider` + `.when()`을 사용합니다.
- `riverpod` 정식 의존성 승격 여부가 결정되기 전까지 `pubspec.yaml`의 섹션을 임의로 이동하지 마십시오.

## 4. 테마 (`AppTheme`)

- 톤앤매너: 도트풍 **Galmuri11** (`assets/fonts/`, OFL) + 밝은 크림(라이트) / 잉크(다크).
  전역 `fontFamily`와 명언(`quoteTextStyle`) 모두 Galmuri11을 쓴다.
  런타임 폰트 다운로드는 금지 (macOS 샌드박스 차단 이슈).
- 모드 규칙: 말씨 탭(`/`)은 **항상 니어블랙(`abyss`) 고정** (명언 가독성, #59).
  나머지 화면(정원/설정)은 **설정 탭의 화면 모드(라이트/다크/시스템)**를 따른다 (#47).
  각 탭 상단 타이틀(AppBar)은 두지 않는다 (하단 탭 라벨과 중복, #49).
- 화면 코드는 `Theme.of(context)` (`cardColor`, `colorScheme`, `dividerColor`)를 쓰고,
  `AppTheme.ink*`/`paper` 직접 참조는 씨앗 탭(다크 고정)에만 허용한다.
- 기준값: 라이트 배경 `cream`(`0xFFFFF8EC`), 카드 흰색, 본문 `cocoa`,
  강조 `goldDeep`; 다크 배경 `ink900`, 강조 `gold`.
  잔디 셀 색상은 테마 7종 × 모드 2종 (`ThemeAssets.cellColor(theme, brightness)` —
  라이트는 밝은 열매색, 다크는 다크톤, #56).
  BottomNav 색상은 하드코딩하지 않고 `bottomNavigationBarTheme`을 따른다.

## 5. 에러/로딩 처리 패턴

- `AsyncValue` 계열은 `.when(data:, loading:, error:)` 삼분기로 처리합니다.
  - 로딩: `const CircularProgressIndicator()`.
  - 에러: `Text('Error: $err')`.
  - 빈 데이터: 안내 문구 (예: `'명언을 불러올 수 없습니다.'`).
- 비동기 콜백 후 `context` 사용 전 `if (!context.mounted) return;` 가드를 둡니다
  (`login_screen.dart` 참조).

## 6. 라우팅

- 신규 화면은 `lib/routing/app_router.dart`에 등록합니다.
  3탭은 `StatefulShellRoute.indexedStack` 분기로 등록하고 (#79),
  바는 셸(`AppShellView`)이 상주로 들고 있어 화면에 두지 않습니다.
  목표 라우트: `/`, `/archive`, `/settings` (+ `/auth` 셸 외부).
  구 라우트(`/home`, `/quote-detail/:quoteId`, `/category`, `/write`, `/liked`, `/mypage`)는
  폐기 예정이며 신규 코드에서 연결하지 마십시오.
- 경로 파라미터는 `state.pathParameters['quoteId'] ?? ''` 패턴으로 안전하게 읽습니다.
- 화면 이동은 `context.go(...)`를 사용합니다.
- 탭 이동은 셸 바 경유를 원칙으로 합니다 (`AppShellView` → `goBranch`, #79).
  알림 탭 → `/` 이동도 `context.go('/')`를 사용합니다.
  셸에서는 화면이 유지되므로 탭 선택 시 명시적 새로고침이 필요합니다
  (말씨 `refreshGrowth()`·정원 `load()` — 셸 핸들러에서 호출).
