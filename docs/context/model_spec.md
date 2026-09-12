# malssi Model Specification (도메인 모델 정의서)

> AI 에이전트용 개발 하네스 문서 중 하나입니다. Firestore 직렬화/모델 수정 전 반드시 본 문서를 읽으십시오.
> 상위 지침: `AGENTS.md`. 관련: `docs/architecture/architecture_spec.md`, `docs/conventions/convention.md`.
> 기준 코드: `lib/features/quote.dart`, `lib/features/seed/domain/seed.dart`,
> `lib/features/archive/domain/fruit.dart`, `lib/features/settings/domain/app_settings.dart`,
> `lib/core/constants/collection_names.dart`, `lib/features/*/data/*_repository.dart`.
> 구 화면 모델(`HomeQuote`, `Comment` 등)은 #19에서 제거되어 §4.2~§4.6에
> 제거 상태로만 기록한다.

## 1. 개요

`malssi`는 명언 공유 앱입니다. 도메인 모델은 Firestore 문서와 1:1로 매핑되는
`fromMap` / `toMap` / `copyWith` 삼중 구조를 따릅니다. 모든 모델은 불변(immutable)이며
`final` 필드 + `const` 생성자를 사용합니다.

## 2. Firestore 컬렉션명 (`CollectionNames`)

`lib/core/constants/collection_names.dart`에 정의된 상수를 **반드시** 사용하십시오.
문자열 하드코딩 금지.

```dart
class CollectionNames {
  static const auth = 'auth';
  static const quotes = 'quotes';
  static const comments = 'comments';
  static const categories = 'categories';
  static const submissions = 'submissions';
  static const users = 'users';
  // 3탭 개편 (2026-09-04) 신규 컬렉션:
  static const seeds = 'seeds';
  static const fruits = 'fruits';
  static const settings = 'settings';
}
```

> 참고: `lib/core/services/firestore_refs.dart`는 `CollectionNames` 상수를 사용한다.
> `seeds`/`fruits`/`settings` 경로 상수 추가 여부는 아키텍처 이슈로 분리
> (`architecture_spec.md` §3-8 참조).

## 3. 직렬화 공통 규칙

1. `fromMap(Map<String, dynamic> map)` — Firestore 문서 → 객체.
   누락 필드는 `??` 기본값으로 방어 (`''`, `0`, `false`).
2. `toMap()` — 객체 → Firestore 문서 Map. 키는 필드명과 동일.
3. `copyWith({...})` — 불변 업데이트. `null`이면 기존 값 유지.
4. `createdAt` Timestamp 변환 규칙 (전 모델 공통):
   ```dart
   createdAt: (map['createdAt'] as dynamic).toDate() ?? DateTime.now(),
   ```
   `.toDate()` 방어 읽기로 `Timestamp` 호환 형태를 파싱한다.
   `toMap()`에서는 `DateTime`을 그대로 넣는다 (로컬 JSON 저장 시 ISO 문자열로 변환,
   `LocalStore.decodeDates`로 복원). 서버 연동은 미계획.

## 4. 모델별 스펙

### 4.1 `Quote` — 기본 추상 클래스

- **위치**: `lib/features/quote.dart`
- **성격**: 모든 명언 모델의 루트. 직접 인스턴스화는 `Quote._internal` 구현체 경유.
- **필드**:

| 필드      | 타입       | Firestore 키 | 기본값 (`fromMap` 누락 시) |
| --------- | ---------- | ------------ | -------------------------- |
| id        | `String`   | `id`         | `''`                       |
| text      | `String`   | `text`       | `''`                       |
| author    | `String`   | `author`     | `''`                       |
| likes | `int` | `likes` | `0` |
| createdAt | `DateTime` | `createdAt` | `DateTime.now()` |
| theme | `String` | `theme` | `''` (테마 미분류, `SeedTheme` 키 값 — §4.11) |
| source | `String` | `source` | `''` (명언 출처 표시문, 비어 있으면 출처 버튼 숨김, #123) |

> 2026-09-05: 해시태그(`tags`) 필드 제거 — 해시태그 기능 미사용 확정 (#54 작업에서 함께 제외).

- **직렬화**: `fromMap` 팩토리, `toMap()`, `copyWith({id, text, author, likes, createdAt})` 제공.
  `Quote._internal` 클래스가 `implements Quote`로 실제 저장소 역할을 합니다.

### 4.2 `HomeQuote` — 제거됨 (#19)

- **현황**: 구 홈 화면과 함께 제거됨. (제거 전 위치: `lib/features/home/domain/quote.dart`,
  `Quote` 확장 + `category`/`isFeatured` 필드.)
- **참고**: `Quote` 기본 클래스(§4.1)는 씨앗의 명언 원천으로 유지한다.

### 4.3 `Comment` — 제거됨 (#19)

- **현황**: 구 명언 상세 화면과 함께 제거됨.
  (제거 전 위치: `lib/features/quote_detail/domain/comment.dart`,
  `id`/`quoteId`/`author`/`text`/`likes`/`createdAt` 필드,
  최상위 `comments` 컬렉션 방식.)
- **참고**: 충실도 기록과의 통합 여부는 후속 이슈에서 결정한다
  (`feature_spec.md` §6 참조).

### 4.4 `User` — 제거됨 (#19)

- **현황**: 구 마이페이지와 함께 제거됨. 전용 Dart 모델 클래스는 만든 적 없고
  `Map<String, dynamic>` 프로필을 직접 사용했었다.
  (제거 전 위치: `lib/features/mypage/data/user_repository.dart`,
  컬렉션 `users`.)
- **향후 과제**: 필요시 `User` 모델 클래스(`fromMap`/`toMap`/`copyWith`) 신설을 재검토한다.

### 4.5 `Hashtag` / `Category` — 해시태그·카테고리 (미사용 확정, 2026-09-05 제외)

- **현황**: 해시태그 기능을 앞으로 사용하지 않기로 확정하여 워크스페이스에서 제외한다.
  `HashtagRepository`는 #19에서 이미 제거되었고, `Quote.tags` 필드도 본 개정에서 제거했다.
  (제거 전 위치: `lib/features/category/data/hashtag_repository.dart`)
- **컬렉션**: `categories` (`CollectionNames.categories`) — 사용 중단.

### 4.6 `Submission` — 제거됨 (#19)

- **현황**: 구 내 명언 화면과 함께 제거됨. 전용 모델 클래스 없이
  `Map<String, dynamic>`으로 다루었었다.
  (제거 전 위치: `lib/features/my_quote/data/submission_repository.dart`,
  컬렉션 `submissions`.)
- **향후 과제**: 자작 명언 부활 시(#129) 모델·상태 정책을 새로 확정한다.

### 4.7 `Auth` — 인증 (백엔드 없음, 확정)

- **위치**: `lib/features/auth/data/dummy_auth_service.dart` (`DummyAuthService`)
- **현황**: 인증 백엔드 없이 더미 구현으로 확정
  (`signInAnonymously`, `signInWithGoogle`, `signOut`,
  `currentUserId => 'anonymous_user'`). Firebase 미사용.
- **컬렉션**: `auth` (`CollectionNames.auth`) — 로컬 키로만 사용한다.

### 4.8 `Seed` — 씨앗 (3탭 개편 신규, 2026-09-04, 구현됨)

- **위치**: `lib/features/seed/domain/seed.dart`
- **성격**: 하루 1개 생성되는 씨앗. 문서 ID는 날짜키(예: `'2026-09-04'`) 사용을 권장.
  불변 모델이며 `fromMap`/`toMap`/`copyWith` 삼중 구조를 따른다 (§3 준수).
- **필드**:

| 필드      | 타입       | Firestore 키 | 기본값 (`fromMap` 누락 시) |
| --------- | ---------- | ------------ | -------------------------- |
| id        | `String`   | `id`         | `''` (날짜키 권장)         |
| dateKey   | `String`   | `dateKey`    | `''` (`'YYYY-MM-DD'`)      |
| quoteId   | `String`   | `quoteId`    | `''` (개봉 시 확정, 그 전은 `''`) |
| status    | `String`   | `status`     | `'locked'` (`locked`/`growing`/`complete`/`opened`(구)/`expired`) |
| createdAt | `DateTime` | `createdAt`  | `DateTime.now()`           |
| theme     | `String`   | `theme`      | `''` (`SeedTheme` 키 값 — §4.11, 생성 시 랜덤 부여) |
| growthStage | `int`    | `growthStage` | `0` (0~5, 2시간마다 +1)   |
| plantedAt | `DateTime` | `plantedAt`  | `createdAt` (심은 시각, 단계 계산 기준) |

- **상태 전이**: `locked` (생성, 탭 → 심기) → `growing` (2시간 간격 성장) →
  `complete` (5단계 도달, 열매 수확 대상).
  미심김(`locked`) 씨앗은 당일 14시를 넘기면 `expired`로 전환된다
  (14시 정각까지 심기 가능, `Seed.deadlineHour = 14`, #147 —
  14시 심기 → 10시간 성장 → 24시 완성으로 당일 수확 가능).
  `seedTime`과 무관한 고정 마감이다.
  자정 만료도 유지된다 (날짜가 바뀌면 지난 `locked` 만료).
  `growing`은 다음 날로 이월된다 (정오 전 심기 → 늦어도 22시 완성이므로
  실제로 자정을 넘기지 않는다).
  (`opened`는 성장 도입 전 상태로 호환용으로만 유지.)
- **컬렉션**: `seeds` (`CollectionNames.seeds`).
- **향후 과제**: 성장 단계 연출 에셋 확정 시 §4.11 개정.

### 4.9 `Fruit` — 열매 (3탭 개편 신규, 2026-09-04, 구현됨)

- **위치**: `lib/features/archive/domain/fruit.dart`
- **성격**: 씨앗 개봉 시 수확되는 기록.
  불변 모델이며 `fromMap`/`toMap`/`copyWith` 삼중 구조를 따른다 (§3 준수).
- **필드**:

| 필드        | 타입       | Firestore 키 | 기본값 (`fromMap` 누락 시) |
| ----------- | ---------- | ------------ | -------------------------- |
| id          | `String`   | `id`         | `''`                       |
| seedId      | `String`   | `seedId`     | `''` (원천 씨앗의 날짜키)  |
| quoteId     | `String`   | `quoteId`    | `''` (원천 명언 FK)        |
| text        | `String`   | `text`       | `''` (명언 스냅샷)         |
| author      | `String`   | `author`     | `''` (명언 스냅샷)         |
| harvestedAt | `DateTime` | `harvestedAt`| `DateTime.now()`           |
| theme       | `String`   | `theme`      | `''` (수확 시점 `Quote.theme` 스냅샷 — §4.11) |
| memo        | `String`   | `memo`       | `''` (그날의 후기, 미작성) |
| fidelityScore | `int`    | `fidelityScore` | `0` (그날의 점수 0~5, `0` = 미평가) |
| source      | `String`   | `source`     | `''` (수확 시점 `Quote.source` 스냅샷, #123) |

- **스냅샷 규칙**: `text`/`author`/`theme`/`source`은 수확 시점의 `Quote` 복사본이다.
  원천 `quotes` 문서가 변경/삭제되어도 보관 목록은 변하지 않는다.
  `memo`/`fidelityScore`는 말씨 탭의 완성 열매 흐름에서 작성하고 (#41),
  보관 상세 카드에서는 읽기만 한다 (#48).
- **컬렉션**: `fruits` (`CollectionNames.fruits`).
- **향후 과제 (후속 이슈로 분리)**: 성장 단계 필드 추가 시 본 스펙 개정.

### 4.10 `AppSettings` — 앱 설정 (3탭 개편 신규, 2026-09-04, 구현됨)

- **위치**: `lib/features/settings/domain/app_settings.dart`
- **성격**: 사용자별 1문서. 씨앗 생성 시각 등을 담는다.
  불변 모델이며 `fromMap`/`toMap`/`copyWith` 삼중 구조를 따른다 (§3 준수).
- **필드**:

| 필드           | 타입   | Firestore 키    | 기본값 (`fromMap` 누락 시) |
| -------------- | ------ | --------------- | -------------------------- |
| seedTime       | `String` | `seedTime`    | `'08:00'` (`'HH:mm'`, #47) |
| notifyEnabled  | `bool` | `notifyEnabled` | `true`                     |
| themeMode      | `String` | `themeMode`   | `'system'` (`'light'`/`'dark'`/`'system'`, #47) |
| fruitRainEnabled | `bool` | `fruitRainEnabled` | `true` (열매 비 효과 on/off, #108) |

- **동작 귀속**: `seedTime` 시각에 씨앗 생성 + 알림 발송이 동시에 동작한다
  (`feature_spec.md` §3 참조).
  당일 마감(14시, #147) 이후 값은 저장할 수 없다
  (`isAllowedSeedTime` — 14:00 정각까지 허용, #159).
- **컬렉션**: `settings` (`CollectionNames.settings`).
- **저장**: 로컬 저장으로 확정 (#122, `LocalStore` + `SharedPreferences`).
  Firestore 연동은 동기화·공유 수요 발생 시 별도 이슈로 분리한다.

### 4.11 테마 분류 — 씨앗·열매·명언 (2026-09-04)

- **개념**: 명언은 7개 테마로 분류하여 관리한다. 씨앗 1개는 테마 1개를 갖고,
  그 씨앗에서 수확되는 열매도 같은 테마다. 일자별 씨앗 테마는 **랜덤**으로 부여한다
  (중복 허용, 2026-09-04 확정, #30). 심을 때 같은 테마의 명언을 확정하고,
  **명언은 심는 즉시 공개되며, 명언 아래에 성장 에셋이 2시간 간격으로 그려진다**
  (#46, 2026-09-05 개정 — 종전 "성장 완성 시 공개" 폐기).
  해당 테마 명언이 없으면 전체에서 랜덤 선택한다 (폴백).
- **명언 원천** (#123, #176에서 속담 88件 추가, #180에서 14件 정리):
  `assets/docs/quotes.json` 182件
  (위키 94件 — 원본 `wikiquote.json` 719件에서 엄선. 페미니즘 사상·인용부호 포함·
  생존 인물 등 제외, 카테고리 불일치·단편·정보성·극단 제외, 250자 초과는
  핵심문장으로 단축, 한국어 위키인용집, CC BY-SA 4.0.
  #180에서 82자(기준 문구: 나폴레옹 `가라, 달려라 … 시간만은 안된다`) 초과 12件·
  한자 포함 4件(겹침 2件) 제거 → 위키 94件.
  속담 88件 — 국립국어원 우리말샘 9,999건에서 7테마 1차 선정 100건 후
  리뷰 제외 12건 반영. 성적·폭력·차별 표현 및 무귀속 항목 제외,
  동의 속담은 대표 1개. 선정 과정·이유는 `docs/quotes/proverbs_review.md`,
  위키 재검토 26건은 `docs/quotes/wiki_review.md`).
  항목별 `source`로 출처를 관리하고, 명언이 보이는 위치(말씨 탭·후기 카드)의
  출처 버튼으로 확인한다.
  `tool/classify_quotes.py`로 7테마 분류·선정. 앱 시작 시 `QuoteAssets`로 읽어
  명언 풀로 사용하고, 로드 실패 시 기본 7시드로 동작한다.
- **성장 간격**: 2시간 (`Seed.stageInterval`, #95에서 디버그 5초 폐기).
  자동 갱신 타이머 15분 (`SeedProvider.refreshInterval`).
  디버그 날짜 이동: 앱 공용 시계 `DebugClock.shift()` + 저장소별 `debugShiftTime()`
  (씨앗·수확물 저장소 시각 이동, #95·#115).
- **성장 단계 에셋** (과일별 5단계, #67 — 2026-09-05 확보, 35개):
  - 0단계: 테마 씨앗 이미지 (`<이름>_seed.png`, 기존).
  - 1~5단계: `<이름>-<n>.png`
    (`<이름>`은 strawberry/orange/lemon/kiwi/blueberry/grape/grapefruit).
  - 완성 화면의 열매는 기존 테마 열매 이미지 (`<이름>.png`) 그대로 재사용.
  - 종전 혼합 전략(공용 `growth_<n>.png` + `growth_<이름>_<n>.png`, 17개)은 폐기
    (해당 파일 없이 과일별 에셋으로 대체됨).
  - 매핑: `ThemeAssets.growthImage(theme, stage)`.
- **정규 키** (7종, `lib/core/constants/seed_themes.dart`의 `SeedTheme`로 상수화됨):
  `vitality` / `happiness` / `growth` / `health` / `peace` / `relationship` / `wisdom`.

| 키 | 테마 | 씨앗 | 최종 열매 | 에셋 (`assets/images/`) |
|---|---|---|---|---|
| `vitality` | 🔴 활력 | 빨간 딸기 씨앗 | 🍓 딸기 | `strawberry_seed.png` / `strawberry.png` |
| `happiness` | 🟠 행복 | 주황 씨앗 | 🍊 오렌지 | `orange_seed.png` / `orange.png` |
| `growth` | 🟡 성장 | 노란 씨앗 | 🍋 레몬 | `lemon_seed.png` / `lemon.png` |
| `health` | 🟢 건강 | 초록 씨앗 | 🥝 키위 | `kiwi_seed.png` / `kiwi.png` |
| `peace` | 🔵 평온 | 파란 씨앗 | 🫐 블루베리 | `blueberry_seed.png` / `blueberry.png` |
| `relationship` | 🟪 관계 | 보라 씨앗 | 🍇 포도 | `grape_seed.png` / `grape.png` |
| `wisdom` | 🩷 지혜 | 분홍 자몽 씨앗 | 자몽 | `grapefruit_seed.png` / `grapefruit.png` |

- **필드 귀속** (구현됨, #28):
  - `Quote.theme` — 명언의 분류 테마 (관리용, `String`, 키 값).
  - `Seed.theme` — 당일 씨앗의 테마. 개봉 시 같은 테마의 명언을 선택한다.
  - `Fruit.theme` — 수확 열매의 테마 스냅샷. 보관 탭에서 테마별 열매 이미지 렌더링에 사용한다.
  - `fromMap` 누락 시 기본값은 `''`. §3 직렬화 규칙을 따른다.
- **에셋 규칙**: 열매 이미지는 `<이름>.png`, 씨앗 이미지는 `<이름>_seed.png`.
  `pubspec.yaml`의 `assets/images/`에 등록되어 있다.
- **변경 이력**: 초안의 `보라 지혜 → 블랙베리`는 `분홍 지혜 → 자몽`으로 교체됨.
  초안의 `빨간 사과`는 업로드된 에셋(`strawberry.png`)에 맞춰 `빨간 딸기`로 확정됨.

## 5. Repository 추상 스펙 (참고)

| Repository             | 위치                                                    | 핵심 메서드                                                                    |
| ---------------------- | ------------------------------------------------------- | ------------------------------------------------------------------------------ |
| `QuoteRepository`      | `lib/features/home/data/quote_repository.dart`          | `getRandomQuote`, `getRandomQuoteByTheme` (테마 폴백 포함), `getQuotesStream`, `addQuote`, `updateLike`, `deleteQuote` — 씨앗 탭의 명언 원천 조회 용도로 유지 |
| `UserRepository` (제거됨, #19) | — | 구 `mypage` 화면과 함께 제거 |
| `HashtagRepository` (제거됨, #19) | — | 구 `category` 화면과 함께 제거 |
| `SubmissionRepository` (제거됨, #19) | — | 구 `my_quote` 화면과 함께 제거 |
| `SeedRepository` | `lib/features/seed/data/seed_repository.dart` | `getTodaySeed`, `getActiveSeed`, `getSeedsStream`, `openSeed`, `plantSeed`, `refreshGrowth`, `debugFastForward`, `debugShiftTime` |
| `FruitRepository` | `lib/features/archive/data/fruit_repository.dart` | `harvestFromSeed`, `getFruits`/`getFruitsStream` (수확일 내림차순), `updateReview` (후기·점수 저장), `pruneUnreviewedBeforeToday` (이월 만료 폐기, #113), `debugShiftTime` |
| `SettingsRepository` | `lib/features/settings/data/settings_repository.dart` | `getSettings`, `getSettingsStream`, `updateSeedTime`, `setNotifyEnabled`, `setThemeMode`, `setFruitRainEnabled` (#108), `load` (로컬 복원, #122) |

> `Quote` 명언 원천은 번들(`assets/docs/quotes.json`, #123)을 `QuoteAssets`로 읽어
> `InMemoryQuoteRepository`에 주입한다. 로드 실패 시 기본 7시드로 동작한다.
