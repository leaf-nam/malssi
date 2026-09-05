# malssi Feature Specification (주요 기능 명세서)

> AI 에이전트용 개발 하네스 문서 중 하나입니다. 상위 지침: `AGENTS.md`.
> 관련: `docs/context/model_spec.md` (모델/컬렉션), `docs/architecture/architecture_spec.md` (구조/서비스).
> 본 문서는 3탭(말씨/정원/설정) 체제의 공식 기능 명세를 정의합니다.
> 각 항목의 **구현 상태**는 기준 시점의 실제 코드를 기준으로 표기하며,
> 미구현 부분은 "미구현"으로 명시합니다 (추측 금지).
> 2026-09-04 개정: 기존 7기능(오늘의 명언/내 명언/댓글/카테고리/좋아요·추천/공유/하루 1회 알림)
> 체제를 폐기하고 3탭 체제로 전면 개편합니다. 폐기 내역은 §6 참조.
> 테마 분류(명언·씨앗·열매 7종) 체계는 §4 참조.

## 1. 말씨 탭 (메인, `/`)

- **요구**: 매일 1개의 씨앗이 생성된다. 씨앗을 심으면(개봉) **그날의 명언이 바로 공개**되고,
  명언 아래에 씨앗이 2시간 간격으로 자라는 에셋이 그려진다(0~5단계).
  완성되면 열매가 맺힌다. 씨앗은 7개 테마(§4 참조) 중 1개의
  테마를 갖고, 명언은 해당 테마로 분류된 것 중에서 선택된다.
- **메인 화면 구성** (미니멀, #39, 레이아웃 #51):
  상단 타이틀 없음 (#49). 성장 중에는 명언 + 저자가 2/3, 성장 에셋이 1/3을 차지하고,
  완성 시에는 명언 + 저자(2/3)와 열매 이미지(1/3)가 나온다.
  성장 중 에셋 영역에는 단계·안내 문구와 도트를 두지 않고 형태만 보여준다 (#57).
  명언 + 저자 영역(`_QuoteBlock`)은 잠금 화면 재사용을 전제로 분리되어 있다
  (잠금 상태 명언 노출은 후속 이슈).
  안내 문구·열매 헤더·카드 테두리·태그 칩은 삭제. 저자는 작게(11px) 흰색 통일.
- **구현 상태**: 미구현 (신규). 기존 `HomeScreen`의 랜덤 명언 + 광고 게이트 플로우를 대체한다.
- **관련 코드 (예정)**:
  - 모델: `Seed`, `Fruit` (`model_spec.md` §4.8·§4.9 참조).
  - 저장소: `SeedRepository` (`getTodaySeed()`, `openSeed(seedId)`),
    `FruitRepository` (`harvestFromSeed(seedId)`, `getFruitsStream()`)
    (`lib/features/seed/data/`, `lib/features/archive/data/` 예정).
  - 화면: `SeedScreen` (`lib/features/seed/presentation/seed_screen.dart` 예정) —
    기존 `HomeScreen` (`lib/features/home/presentation/home_screen.dart`)을 대체.
  - 상태: `SeedProvider` (`lib/features/seed/providers/` 예정).
  - 명언 원천: 기존 `quotes` 컬렉션 + `Quote` 모델 재사용
    (`lib/features/quote.dart`, `CollectionNames.quotes`).
- **동작 플로우 (목표)**:
  1. 설정 시각(`AppSettings.seedTime`, 기본 08:00)에 당일 `Seed` 문서 1개 생성
     (문서 ID = 날짜키, 예: `'2026-09-04'`, 테마 랜덤 부여) + 씨앗 알림 발송.
  2. 사용자가 씨앗을 탭 1회 → `plantSeed()` → `status: locked → growing` →
     같은 테마의 명언 확정 + **명언 즉시 공개** (해당 테마가 없으면 전체 랜덤 폴백).
  3. 명언 아래에 성장 에셋 표시. 릴리즈 2시간마다 1단계씩 성장 (디버그 5초,
     단계 이미지는 §4·`model_spec.md` §4.11).
     앱 실행 중 자동 갱신(릴리즈 15분·디버그 5초) + 말씨 탭 진입 시 갱신 + 재실행 시 경과 시간 계산 (#62, #64).
  4. 5단계 도달 → `complete` → `Fruit` 수확.
     미심김 씨앗만 자정에 만료되고, 성장 중 씨앗은 다음 날로 이월된다.
  5. 완성된 명언을 탭 → 리뷰 카드 (별점 1~5 + 한줄 후기, `FruitReviewSheet` 공용).
     후기는 첫 저장 이후 수정 불가(읽기만, #71). 빈 내용의 첫 저장은 무시된다.
     저장된 후기가 있어야 잔디가 심어진다 (#65).
  6. 개발 모드 한정 임시 버튼 (`kDebugMode` — `디버그: +1단계` 1단계 진행,
     `디버그: 열매 만들기` 즉시 완성·수확, #69).
- **향후 과제 (후속 이슈로 분리)**: 성장 단계 연출 에셋 17개 확보
  (`model_spec.md` §4.11), 열매에 그날의 명언 충실도 기록 (#41 리뷰 작성으로 해소 예정).

## 2. 정원 탭 (`/archive`, 구 보관)

- **요구**: 지금까지 수확한 열매들을 기록한다.
  GitHub 잔디 스타일로 **최근 1년을 그리드**로 보여주고, 각 칸은 해당 날짜 열매의
  **테마 색깔로만** 표시한다. 칸을 터치하면 확대되면서 **열매 + 저장된 후기 및 점수 카드**가 나온다.
  **후기 작성은 불가**하며 이미 저장된 후기만 불러온다 (#48).
  **잔디는 후기를 남긴 열매만 심어진다** — 수확만으로는 표시되지 않는다 (#65).
  작성은 말씨 탭의 완성 열매 흐름(#41)에서만 가능하고, 저장 후에는 수정할 수 없다 (#71).
- **그리드 표시**: 화면 너비에 53주 전체가 최소 칸(22px) 이상으로 들어가면
  스크롤 없이 꽉 채워 표시하고 (칸 최대 30px, 남는 폭 중앙 정렬),
  좁으면 가로 스크롤을 유지한다 (#72).
  스크롤 모드에서도 보이는 주 수에 딱 맞게 칸을 키워 정지 시 가장자리에
  반칸이 생기지 않는다 (#83). 스크롤바는 항상 표시해 1년 전체 이동을 알린다 (#86).
- **구현 상태**: 잔디 그리드 + 읽기 전용 상세 카드 구현됨 (#31, #48).
  기존 목록형 MVP는 본 형태로 대체되었다.
- **관련 코드**:
  - 모델: `Fruit` (`model_spec.md` §4.9 참조) — `memo`/`fidelityScore`(0~5, `0`=미평가) 포함.
  - 저장소: `FruitRepository.getFruitsStream()` (날짜 내림차순),
    `updateReview({fruitId, memo, fidelityScore})` (0~5 범위 외는 `ArgumentError`).
  - 화면: `ArchiveScreen` (`lib/features/archive/presentation/archive_screen.dart`) —
    `_GrassGrid`(53주 × 7일, 가로 스크롤) + 공용 `FruitReviewSheet`(읽기 전용, `readOnly: true`).
  - 상태: `ArchiveProvider` (`load()`, `fruitsByDateKey`, `updateReview()`).
  - 메인 진입점: 완성 명언 탭 → 같은 `FruitReviewSheet` 작성 모드 (`SeedProvider.saveReview()` 저장, #41).
  - 셀 색상: `ThemeAssets.cellColor(theme)` (`lib/core/theme/theme_assets.dart`).
- **동작 플로우 (목표)**:
  1. 후기를 남긴 `Fruit`만 잔디의 해당 날짜 칸에 테마 색으로 표시된다 (#65).
     (`Fruit.isReviewed` = 후기 텍스트 있음 또는 별점 1~5).
  2. 칸 터치 → 상세 카드 (열매 이미지 + 명언 + 저장된 별점 + 저장된 후기 또는 빈 상태 문구).
  3. 정원 탭 진입 시마다 보관 목록을 다시 불러온다 (#62).
- **향후 과제 (후속 이슈로 분리)**: 1년 이전 데이터 페이징, 열매 상세에 기존 공유하기 편입 여부.

## 3. 설정 탭 (`/settings`)

- **요구**: 씨앗 생성시간·화면 모드 등을 설정한다. 설정 시각에 씨앗 생성과 알림이 동시에 동작한다.
  화면 모드(라이트/다크/시스템, #47)와 씨앗 기본 생성시간 08:00 (#47)을 제공한다.
- **구현 상태**: 미구현 (신규). 기존 `MyPageScreen`의 알림 토글·시간 설정 UI는
  본 탭으로 이관 후 `MyPageScreen`은 폐기한다.
- **관련 코드 (예정)**:
  - 모델: `AppSettings` (`model_spec.md` §4.10 참조).
  - 저장소: `SettingsRepository` (`getSettingsStream()`, `updateSeedTime()`,
    `setNotifyEnabled()`, `setThemeMode()`) (`lib/features/settings/data/` 예정).
  - 화면: `SettingsScreen` (`lib/features/settings/presentation/settings_screen.dart` 예정).
  - 알림: `NotificationService` (`lib/core/services/notification_service.dart`) —
    기존 1회 예약 API를 매일 반복 스케줄로 확장 (`scheduleDailySeedNotification()` 예정).
- **동작 플로우 (목표)**:
  1. 사용자가 씨앗 생성 시각 변경 (기본값 매일 08:00) → `updateSeedTime()` 저장.
  2. 사용자가 화면 모드 변경 (라이트/다크/시스템, 기본 시스템) → `setThemeMode()` 저장·즉시 적용.
     말씨 탭(`/`)은 항상 다크 고정으로 제외.
  3. 다음 날부터 해당 시각에 씨앗 생성 + `NotificationService` 일일 알림 발송.
  4. 알림 탭 → 말씨 탭(`/`)으로 이동 (딥링크/라우팅 연결).
- **향후 과제**: 알림 권한 요청 플로우, 타임존 처리, 서버 푸시(FCM) 필요 여부 결정,
  로그인(`/auth`) 연동 여부 (설정 저장을 Firestore `settings` vs 로컬 — 아키텍처 이슈로 분리).

## 4. 테마 분류 — 명언·씨앗·열매 (2026-09-04 확정)

- 명언은 아래 7개 테마로 분류하여 관리한다 (`quotes`의 `theme` 필드).
  일자별 씨앗 테마는 **랜덤**으로 부여한다 (중복 허용, #30에서 확정).
- 저장 스펙(정규 키·필드 귀속·에셋 규칙)은 `model_spec.md` §4.11 참조.

| 테마 | 씨앗 | 최종 열매 | 에셋 (`assets/images/`) |
|---|---|---|---|
| 🔴 활력 | 빨간 딸기 씨앗 | 🍓 딸기 | `strawberry_seed.png` / `strawberry.png` |
| 🟠 행복 | 주황 씨앗 | 🍊 오렌지 | `orange_seed.png` / `orange.png` |
| 🟡 성장 | 노란 씨앗 | 🍋 레몬 | `lemon_seed.png` / `lemon.png` |
| 🟢 건강 | 초록 씨앗 | 🥝 키위 | `kiwi_seed.png` / `kiwi.png` |
| 🔵 평온 | 파란 씨앗 | 🫐 블루베리 | `blueberry_seed.png` / `blueberry.png` |
| 🟦 관계 | 남색 씨앗 | 🍇 포도 | `grape_seed.png` / `grape.png` |
| 🩷 지혜 | 분홍 자몽 씨앗 | 자몽 | `grapefruit_seed.png` / `grapefruit.png` |

> 변경 이력: 초안의 `보라 지혜 → 블랙베리`는 `분홍 지혜 → 자몽`으로 교체.
> 초안의 `빨간 사과`는 업로드된 에셋에 맞춰 `빨간 딸기`로 확정.

## 5. 기능-코드 매핑표

| # | 기능 | 컬렉션 | 모델 | Repository | 화면/Provider | 상태 |
|---|------|--------|------|------------|---------------|------|
| 1 | 말씨 (메인) | `seeds` (+`quotes` 원천) | `Seed` / `Quote` | `SeedRepository` | `SeedScreen`, `SeedProvider` | 미구현 |
| 2 | 정원 (열매) | `fruits` | `Fruit` | `FruitRepository` | `ArchiveScreen`, `ArchiveProvider` | 미구현 |
| 3 | 설정 | `settings` | `AppSettings` | `SettingsRepository` | `SettingsScreen` | 미구현 |

## 6. 폐기된 기존 7기능과 사유 (2026-09-04 확정)

기존 GitHub 이슈 #1~#7은 3탭 개편에 따라 Close하고, 아래와 같이 대체/폐기한다.

| 기존 이슈 | 기능 | 처리 |
|-----------|------|------|
| #1 | 오늘의 명언 DB (랜덤 1개 + 광고 게이트) | 대체 — 명언 DB(`quotes`)는 씨앗의 명언 원천으로 재사용, 광고 게이트는 폐기 |
| #2 | 내 명언 생성 (작성→관리자 승인) | 폐기 — 3탭에 없음. 수요 발생 시 별도 이슈로 부활 |
| #3 | 명언 댓글 (베스트 3개) | 폐기 — 3탭에 없음. 충실도 기록과 통합 여부는 후속 이슈에서 결정 |
| #4 | 카테고리 (해시태그 분류) | 폐기 — 3탭에 없음. 추천 활용 계획도 함께 폐기 |
| #5 | 좋아요 (+해시태그 추천) | 폐기 — 3탭에 없음 |
| #6 | 공유 (딥링크) | 폐기 — 1차 제외. 보관 상세 편입 여부는 후속 이슈에서 결정 |
| #7 | 하루 1회 알림 | 대체 — 설정 탭의 씨앗 생성 시각 알림으로 흡수 (씨앗 생성+알림 동시) |

> 기존 코드(`HomeScreen`, `CategoryScreen`, `WriteScreen`, `LikedScreen`,
> `MyPageScreen`, `CommentScreen`, `MvpBottomNav` 5탭, `AdService` 광고 게이트 등)는
> #19에서 정리 완료했다. 본 문서는 요구 명세만 정의한다.
