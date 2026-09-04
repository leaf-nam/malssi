# malssi Feature Specification (주요 기능 명세서)

> AI 에이전트용 개발 하네스 문서 중 하나입니다. 상위 지침: `AGENTS.md`.
> 관련: `docs/context/model_spec.md` (모델/컬렉션), `docs/architecture/architecture_spec.md` (구조/서비스).
> 본 문서는 3탭(씨앗 메인/보관/설정) 체제의 공식 기능 명세를 정의합니다.
> 각 항목의 **구현 상태**는 기준 시점의 실제 코드를 기준으로 표기하며,
> 미구현 부분은 "미구현"으로 명시합니다 (추측 금지).
> 2026-09-04 개정: 기존 7기능(오늘의 명언/내 명언/댓글/카테고리/좋아요·추천/공유/하루 1회 알림)
> 체제를 폐기하고 3탭 체제로 전면 개편합니다. 폐기 내역은 §6 참조.
> 테마 분류(명언·씨앗·열매 7종) 체계는 §4 참조.

## 1. 씨앗 탭 (메인, `/`)

- **요구**: 매일 1개의 씨앗이 생성된다. 씨앗을 깨면(탭 1회) 그날의 명언이 나온다.
  광고 시청 게이트는 없다. 씨앗은 7개 테마(§4 참조) 중 1개의 테마를 갖고,
  명언은 해당 테마로 분류된 것 중에서 선택된다.
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
  1. 설정 시각(`AppSettings.seedTime`, 기본 12:00)에 당일 `Seed` 문서 1개 생성
     (문서 ID = 날짜키, 예: `'2026-09-04'`) + 씨앗 알림 발송.
  2. 사용자가 씨앗을 탭 1회 → `openSeed()` → `status: locked → opened` →
     `quotes`에서 1개 선택 → `Fruit` 문서 생성 (수확).
  3. 개봉된 씨앗 자리에는 명언 카드 렌더링. 미개봉 씨앗은 다음 날 자정에 만료
     (이월 없음).
- **향후 과제 (후속 이슈로 분리)**: 씨앗→식물 성장 연출 단계,
  열매에 그날의 명언 충실도 기록 (`fidelityScore`/`memo`, `model_spec.md` §4.9 참조).

## 2. 보관 탭 (`/archive`)

- **요구**: 지금까지 수확한 열매들을 기록한다. 1차 범위(MVP)는 날짜+명언만.
  열매는 씨앗과 같은 테마를 가지며, 보관 목록에서 테마별 열매 이미지(§4 참조)로 표시한다.
- **구현 상태**: 미구현 (신규).
- **관련 코드 (예정)**:
  - 모델: `Fruit` (`model_spec.md` §4.9 참조).
  - 저장소: `FruitRepository.getFruitsStream()` (날짜 내림차순)
    (`lib/features/archive/data/` 예정).
  - 화면: `ArchiveScreen` (`lib/features/archive/presentation/archive_screen.dart` 예정).
  - 상태: `ArchiveProvider` (`lib/features/archive/providers/` 예정).
- **동작 플로우 (목표)**:
  1. 씨앗 개봉 시 생성된 `Fruit`가 보관 목록에 추가된다.
  2. 목록은 수확일 내림차순으로 노출 (날짜 + 명언 텍스트 + 저자).
- **향후 과제 (후속 이슈로 분리)**: 열매 상세 (충실도 점수/메모, 성장 단계 표시),
  기존 공유하기의 열매 상세 편입 여부 결정.

## 3. 설정 탭 (`/settings`)

- **요구**: 씨앗 생성시간 등을 설정한다. 설정 시각에 씨앗 생성과 알림이 동시에 동작한다.
- **구현 상태**: 미구현 (신규). 기존 `MyPageScreen`의 알림 토글·시간 설정 UI는
  본 탭으로 이관 후 `MyPageScreen`은 폐기한다.
- **관련 코드 (예정)**:
  - 모델: `AppSettings` (`model_spec.md` §4.10 참조).
  - 저장소: `SettingsRepository` (`getSettingsStream()`, `updateSeedTime()`,
    `setNotifyEnabled()`) (`lib/features/settings/data/` 예정).
  - 화면: `SettingsScreen` (`lib/features/settings/presentation/settings_screen.dart` 예정).
  - 알림: `NotificationService` (`lib/core/services/notification_service.dart`) —
    기존 1회 예약 API를 매일 반복 스케줄로 확장 (`scheduleDailySeedNotification()` 예정).
- **동작 플로우 (목표)**:
  1. 사용자가 씨앗 생성 시각 변경 (기본값 매일 12:00) → `updateSeedTime()` 저장.
  2. 다음 날부터 해당 시각에 씨앗 생성 + `NotificationService` 일일 알림 발송.
  3. 알림 탭 → 씨앗 탭(`/`)으로 이동 (딥링크/라우팅 연결).
- **향후 과제**: 알림 권한 요청 플로우, 타임존 처리, 서버 푸시(FCM) 필요 여부 결정,
  로그인(`/auth`) 연동 여부 (설정 저장을 Firestore `settings` vs 로컬 — 아키텍처 이슈로 분리).

## 4. 테마 분류 — 명언·씨앗·열매 (2026-09-04 확정)

- 명언은 아래 7개 테마로 분류하여 관리한다 (`quotes`의 `theme` 필드, 예정).
  일자별 씨앗 테마 선정 방식(순환/랜덤 등)은 후속 이슈에서 확정한다.
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
| 1 | 씨앗 (메인) | `seeds` (+`quotes` 원천) | `Seed` / `Quote` | `SeedRepository` | `SeedScreen`, `SeedProvider` | 미구현 |
| 2 | 보관 (열매) | `fruits` | `Fruit` | `FruitRepository` | `ArchiveScreen`, `ArchiveProvider` | 미구현 |
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
> 구현 브랜치에서 정리한다 (`architecture_spec.md` §3 참조). 본 문서는 요구 명세만 정의한다.
