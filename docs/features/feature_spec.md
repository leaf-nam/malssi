# malssi Feature Specification (주요 기능 명세서)

> AI 에이전트용 개발 하네스 문서 중 하나입니다. 상위 지침: `AGENTS.md`.
> 관련: `docs/context/model_spec.md` (모델/컬렉션), `docs/architecture/architecture_spec.md` (구조/서비스).
> 본 문서는 제품 요구 7종(오늘의 명언/내 명언/댓글/카테고리/좋아요·추천/공유/하루 1회 알림)의
> 공식 기능 명세를 정의합니다. 각 항목의 **구현 상태**는 기준 시점의 실제 코드를 기준으로 표기하며,
> 미구현 부분은 "미구현"으로 명시합니다 (추측 금지).

## 1. 오늘의 명언 (랜덤 1개 + 교체 시 광고 시청)

- **요구**: 명언 DB에서 1개를 가져와 보여준다. 명언을 바꿀 때마다 광고를 시청한다.
- **구현 상태**: 부분 구현 (광고 연동 없음).
- **관련 코드**:
  - 조회: `QuoteRepository.getRandomQuote()` (`lib/features/home/data/quote_repository.dart`) —
    추상 선언만 존재, `QuoteRepositoryImpl` 미구현.
  - 상태: `QuoteNotifier.fetchRandomQuote()` + `randomQuoteProvider`
    (`lib/features/home/providers/home_providers.dart`).
  - 화면: `HomeScreen` (`lib/features/home/presentation/home_screen.dart`)이
    `quoteAsync.when(data/loading/error)` 삼분기로 렌더링.
  - 광고: `AdService.loadAd()`/`showAd()` (`lib/core/services/ad_service.dart`) 스텁만 존재.
    명언 교체 플로우와 연결되어 있지 않음.
- **동작 플로우 (목표)**:
  1. `fetchRandomQuote()` → `quotes` 컬렉션에서 1개 조회 → 카드 렌더링.
  2. 사용자가 "바꾸기" 요청 → `AdService.showAd()` (보상형 광고) 시청 완료 후 → 다음 명언 조회.
- **향후 과제**: `QuoteRepositoryImpl.getRandomQuote` 구현 (랜덤 추출 방식 확정),
  교체 버튼 UI + 광고 시청 게이트 연결, 광고 SDK 연동.

## 2. 내 명언 (사용자 작성 → DB 등록, 관리자 승인 후 노출)

- **요구**: 내가 명언을 작성해서 DB에 올린다. 관리자 승인 후 노출된다.
- **구현 상태**: Repository 추상만 존재 (화면/Provider 미구현).
- **관련 코드**:
  - 제출: `SubmissionRepository.submitQuote({text, author, category})`,
    상태 변경: `updateSubmissionStatus({submissionId, status})`,
    목록: `getSubmissionsStream()`
    (`lib/features/my_quote/data/submission_repository.dart`).
  - 컬렉션: `submissions` (`CollectionNames.submissions`).
  - `lib/features/my_quote/presentation/`, `providers/`는 비어 있음.
- **동작 플로우 (목표)**:
  1. 사용자가 명언 작성 (`text`/`author`/`category`) → `submitQuote()` → `submissions` 문서 생성 (초기 `status`, 예: 대기).
  2. 관리자가 승인/반려 → `updateSubmissionStatus()`로 `status` 변경.
  3. 승인된 것만 `quotes` 컬렉션에 반영 (반영 방식 — 복사 vs 승격 — 미정, 아키텍처 이슈로 분리).
- **향후 과제**: `status` 값 상수/enum화, 작성 화면 + Provider, 관리자 승인 화면,
  승인→`quotes` 반영 규칙 확정 (`model_spec.md` §4.6 참조).

## 3. 명언 댓글 (오늘의 명언에 댓글, 베스트 댓글 3개 노출)

- **요구**: 오늘의 명언에 댓글을 단다. 베스트 댓글 3개를 노출한다.
- **구현 상태**: 모델만 존재 (화면은 플레이스홀더, 베스트 로직 미구현).
- **관련 코드**:
  - 모델: `Comment` (`lib/features/quote_detail/domain/comment.dart`) —
    `id`/`quoteId`/`author`/`text`/`likes`/`createdAt`, `fromMap`/`toMap`/`copyWith` 완비.
  - 컬렉션: `comments` (`CollectionNames.comments`), `quoteId`로 부모 명언 참조.
  - 화면: `CommentScreen` (`lib/features/quote_detail/presentation/comment_screen.dart`) —
    현재 `'Comment Screen - Coming Soon'` 플레이스홀더.
  - 라우트: `/quote-detail/:quoteId` (`lib/routing/app_router.dart`).
- **동작 플로우 (목표)**:
  1. `/quote-detail/:quoteId` 진입 → 해당 `quoteId`의 댓글 목록 조회.
  2. 댓글 작성 → `comments` 문서 생성.
  3. `likes` 상위 3개를 "베스트 댓글"로 상단 노출 (정렬 기준·동점 처리 미정).
- **향후 과제**: 댓글 Repository/Provider/화면 구현, 베스트 3개 쿼리
  (`orderBy likes desc limit 3` 등) 확정, 좋아요 API.

## 4. 카테고리 (해시태그로 명언 분류)

- **요구**: 해시태그로 명언을 분류한다.
- **구현 상태**: Repository 추상 + 모델 필드만 존재.
- **관련 코드**:
  - `HashtagRepository` (`lib/features/category/data/hashtag_repository.dart`) —
    `getHashtagsStream()` / `addHashtag()` / `removeHashtag()` (추상, `String` 기반).
  - `HomeQuote.category` (`lib/features/home/domain/quote.dart`) — 명언 측 분류 필드.
  - 컬렉션: `categories` (`CollectionNames.categories`).
  - `lib/features/category/presentation/`는 비어 있음.
- **동작 플로우 (목표)**:
  1. 해시태그 목록 조회 (`getHashtagsStream`) → 카테고리 탭/필터 UI.
  2. 명언의 `category`와 매칭하여 분류별 목록 노출.
- **향후 과제**: 단일 `category` vs 복수 해시태그 스키마 확정 (`model_spec.md` §4.5),
  카테고리 화면/Provider 구현, 명언-해시태그 연결 쿼리 정의.

## 5. 좋아요 + 해시태그 기반 유사 명언 추천

- **요구**: 좋아요 기능 + 해시태그 기반 유사한 명언 추천.
- **구현 상태**: 좋아요 카운트/단일 업데이트만 부분 존재. 추천 로직 미구현.
- **관련 코드**:
  - 카운트: `Quote.likes`, `Comment.likes` (모델 필드).
  - 업데이트: `QuoteRepository.updateLike(quoteId)` (추상),
    `QuoteNotifier.likeCurrentQuote()` (현재 명언에 호출).
  - 좋아요 목록 스트림: `likedQuotesStreamProvider` (`home_providers.dart`).
  - 화면: `HomeScreen` FAB (❤) + 카드에 `💚 ${quote.likes}` 표시.
  - 추천(유사 명언) 관련 코드는 없음.
- **동작 플로우 (목표)**:
  1. FAB 탭 → `likeCurrentQuote()` → `likes` 증가 반영.
  2. 좋아요한 명언의 해시태그(`category`)를 기준으로 동일/유사 태그 명언을 추천 목록으로 노출
     (유사도 정의·쿼리 방식 미정).
- **향후 과제**: 좋아요 중복 방지 (유저별 like 기록), `updateLike` 구현,
  추천 알고리즘 명세 (태그 일치 → 최신/인기 정렬 등) 신규 이슈로 분리.

## 6. 공유 (명언 링크로 보내기)

- **요구**: 명언을 링크로 보낸다 (딥링크 공유).
- **구현 상태**: 미구현 (관련 코드 없음).
- **관련 코드**: 없음. 공유 패키지(`share_plus` 등) 미도입.
  딥링크 수신처 후보는 `/quote-detail/:quoteId` (이미 라우트 존재).
- **동작 플로우 (목표)**:
  1. 명언 카드에서 "공유" 탭 → `https://.../quote-detail/:quoteId` 형태 링크 생성.
  2. OS 공유 시트로 전송 → 수신자가 링크 열면 해당 명언 상세로 진입.
- **향후 과제**: 공유 패키지 선정, 링크 형식 + 딥링크(웹 URL/앱 링크) 방식 확정,
  공유 버튼 UI를 명언 카드에 추가. 신규 이슈로 분리.

## 7. 하루 1회 알림

- **요구**: 하루 1회 명언 알림을 보낸다.
- **구현 상태**: 서비스 + 수동 발송 예시만 존재 (하루 1회 스케줄 미구현).
- **관련 코드**:
  - `NotificationService` (`lib/core/services/notification_service.dart`) —
    `init()`, `scheduleNotification({id, title, body, scheduleTime})`,
    `showLocalNotification({id, title, body})` 싱글톤 구현.
  - 사용 예시: `HomeScreen` 알림 아이콘 탭 → 5초 후 예약 알림 1회 발송.
- **동작 플로우 (목표)**:
  1. `init()` 완료 후 매일 고정 시각에 `scheduleNotification()` 등록.
  2. 알림 탭 → 오늘의 명언 화면으로 이동 (이동 처리 미구현).
- **향후 과제**: 일일 반복 스케줄 확정 (매일 시각, 타임존 처리),
  알림 탭 → 라우팅 연결, 권한 요청 플로우, 서버 푸시(FCM) 필요 여부 결정.

## 8. 기능-코드 매핑표

| # | 기능 | 컬렉션 | 모델 | Repository | 화면/Provider | 상태 |
|---|------|--------|------|------------|---------------|------|
| 1 | 오늘의 명언 | `quotes` | `Quote`, `HomeQuote` | `QuoteRepository` (추상) | `HomeScreen`, `QuoteNotifier` | 부분 구현 |
| 2 | 내 명언 | `submissions` | (Map, 모델 없음) | `SubmissionRepository` (추상) | 없음 | 추상만 존재 |
| 3 | 명언 댓글 | `comments` | `Comment` | 없음 | `CommentScreen` (플레이스홀더) | 모델만 존재 |
| 4 | 카테고리 | `categories` | (`String` 기반) | `HashtagRepository` (추상) | 없음 | 추상만 존재 |
| 5 | 좋아요·추천 | `quotes` | `likes` 필드 | `QuoteRepository.updateLike` (추상) | FAB + `likeCurrentQuote` | 좋아요 부분 / 추천 미구현 |
| 6 | 공유 | — | — | — | — | 미구현 |
| 7 | 하루 1회 알림 | — | — | — | `NotificationService` + 예시 호출 | 서비스만 존재 |
