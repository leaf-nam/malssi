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

- Screen: `<Name>Screen` (예: `HomeScreen`, `LoginScreen`, `MyPageScreen`, `CommentScreen`).
- Repository: `<Name>Repository` 추상 클래스 + `<Name>RepositoryImpl` 구현체
  (예: `QuoteRepository` / `QuoteRepositoryImpl`).
- Provider/Notifier: `<Name>Provider`, `<Name>Notifier` (예: `randomQuoteProvider`, `QuoteNotifier`).
- 모델: `Quote`, `HomeQuote`, `Comment` (+ 향후 `User`, `Submission`, `Hashtag`/`Category`).
- Firestore 컬렉션: `CollectionNames` 상수 경유 (문자열 리터럴 금지).

## 3. 상태 관리

- 현재 `provider`와 `riverpod`가 혼용되어 있습니다.
  - `provider`: `AppShell`의 `MultiProvider`, 각 화면의 `context.watch<T>()` / `context.read<T>()`.
  - `riverpod`: `home_providers.dart`의 `StateNotifierProvider` (`QuoteNotifier`),
    `StreamProvider` (`likedQuotesStreamProvider`).
- 기존 파일의 패턴을 유지하십시오. 새 파일에서는 화면 상태 구독에 기존 화면(`home_screen.dart`,
  `mypage_screen.dart`)이 쓰는 패턴을 따르고, 비동기 스트림에는 `StreamProvider` + `.when()`을 사용합니다.
- `riverpod` 정식 의존성 승격 여부가 결정되기 전까지 `pubspec.yaml`의 섹션을 임의로 이동하지 마십시오.

## 4. 테마 (`AppTheme`)

- 색상/버튼/입력 장식은 `lib/core/theme/app_theme.dart`의 `AppTheme.light()`/`dark()`를 사용하고,
  화면 코드에 색상·패딩 하드코딩을 피합니다.
- 기준값: primary `Colors.indigo`, light 배경 `Colors.grey[50]`, dark 배경 `Colors.grey[900]`,
  ElevatedButton (indigo 배경/white 전경, 16×12 패딩, radius 8),
  InputDecoration (hint grey[400], radius 8 테두리).

## 5. 에러/로딩 처리 패턴

- `AsyncValue` 계열은 `.when(data:, loading:, error:)` 삼분기로 처리합니다.
  - 로딩: `const CircularProgressIndicator()`.
  - 에러: `Text('Error: $err')`.
  - 빈 데이터: 안내 문구 (예: `'명언을 불러올 수 없습니다.'`).
- 비동기 콜백 후 `context` 사용 전 `if (!context.mounted) return;` 가드를 둡니다
  (`login_screen.dart` 참조).

## 6. 라우팅

- 신규 화면은 `lib/routing/app_router.dart`에 `GoRoute(path: ...)`로 등록합니다.
- 경로 파라미터는 `state.pathParameters['quoteId'] ?? ''` 패턴으로 안전하게 읽습니다.
- 화면 이동은 `context.go(...)`를 사용합니다.
