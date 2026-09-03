# malssi Model Specification (도메인 모델 정의서)

> AI 에이전트용 개발 하네스 문서 중 하나입니다. Firestore 직렬화/모델 수정 전 반드시 본 문서를 읽으십시오.
> 상위 지침: `AGENTS.md`. 관련: `docs/architecture/architecture_spec.md`, `docs/conventions/convention.md`.
> 기준 커밋시점의 실제 코드: `lib/features/quote.dart`, `lib/features/home/domain/quote.dart`,
> `lib/features/quote_detail/domain/comment.dart`, `lib/core/constants/collection_names.dart`,
> `lib/features/*/data/*_repository.dart`.

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
}
```

> 주의: `lib/core/services/firestore_refs.dart`는 현재 `package:firebase/firebase.dart`를
> import 하며 문자열 리터럴(`'quotes'` 등)을 직접 사용하고 있습니다.
> 추후 리팩터링 시 `CollectionNames` 상수로 교체해야 합니다 (아키텍처 이슈로 분리).

## 3. 직렬화 공통 규칙

1. `fromMap(Map<String, dynamic> map)` — Firestore 문서 → 객체.
   누락 필드는 `??` 기본값으로 방어 (`''`, `0`, `false`).
2. `toMap()` — 객체 → Firestore 문서 Map. 키는 필드명과 동일.
3. `copyWith({...})` — 불변 업데이트. `null`이면 기존 값 유지.
4. `createdAt` Timestamp 변환 규칙 (전 모델 공통):
   ```dart
   createdAt: (map['createdAt'] as dynamic).toDate() ?? DateTime.now(),
   ```
   Firestore `Timestamp` 객체의 `.toDate()`를 호출합니다.
   `toMap()`에서는 현재 코드가 `DateTime`을 그대로 넣으므로, Firestore SDK가
   자동으로 Timestamp로 변환합니다.

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
| tags | `List<String>` | `tags` | `[]` (MVP, `#협력` 등 해시태그) |

- **직렬화**: `fromMap` 팩토리, `toMap()`, `copyWith({id, text, author, likes, createdAt})` 제공.
  `Quote._internal` 클래스가 `implements Quote`로 실제 저장소 역할을 합니다.

### 4.2 `HomeQuote` — `Quote` 확장 (홈 피드용)

- **위치**: `lib/features/home/domain/quote.dart`
- **상속**: `extends Quote`
- **추가 필드**:

| 필드       | 타입     | Firestore 키 | 기본값  |
| ---------- | -------- | ------------ | ------- |
| category   | `String` | `category`   | `''`    |
| isFeatured | `bool`   | `isFeatured` | `false` |

- **직렬화**: `fromMap` 팩토리, `toMap()` 오버라이드(`category`/`isFeatured` 포함),
  `copyWith` 제공. `const` 생성자 (MVP에서 `super.tags` 기본값 포함).
- **용도**: 홈 화면 피드/추천 명언. `QuoteRepository.getRandomQuote()`,
  `getQuotesStream()`의 요소 타입.

### 4.3 `Comment` — 명언 댓글

- **위치**: `lib/features/quote_detail/domain/comment.dart`
- **성격**: 추상 클래스 + `Comment._internal` 구현체 (`Quote`와 동일 패턴).
- **필드**:

| 필드      | 타입       | Firestore 키 | 기본값              |
| --------- | ---------- | ------------ | ------------------- |
| id        | `String`   | `id`         | `''`                |
| quoteId   | `String`   | `quoteId`    | `''` (부모 명언 FK) |
| author    | `String`   | `author`     | `''`                |
| text      | `String`   | `text`       | `''`                |
| likes     | `int`      | `likes`      | `0`                 |
| createdAt | `DateTime` | `createdAt`  | `DateTime.now()`    |

- **직렬화**: `fromMap` / `toMap()` / `copyWith` 전부 제공.
- **컬렉션**: `comments` (`CollectionNames.comments`).
  `quoteId`로 부모 명언을 참조합니다 (서브컬렉션이 아닌 최상위 컬렉션 방식).

### 4.4 `User` — 사용자 프로필 (Map 기반, 모델 클래스 미정의)

- **위치**: `lib/features/mypage/data/user_repository.dart` (`UserRepository` 추상 클래스)
- **현황**: 전용 Dart 모델 클래스는 없고 `Map<String, dynamic>` 프로필을 직접 사용합니다.
- **공식 필드** (presentation 사용처 `mypage_screen.dart` 기준):

| 필드            | 타입      | 설명                                              |
| --------------- | --------- | ------------------------------------------------- |
| displayName     | `String?` | 표시 이름 (`profile['displayName'] ?? '내 이름'`) |
| email           | `String?` | 이메일 (`profile['email'] ?? '이메일 없음'`)      |
| profileImageUrl | `String?` | `updateUserProfile` 파라미터에 존재               |

- **Repository API**:
  ```dart
  Future<Map<String, dynamic>> getUserProfile();
  Stream<Map<String, dynamic>> getUserProfileStream();
  Future<void> updateUserProfile({required String displayName, required String? profileImageUrl});
  Future<void> deleteAccount();
  ```
- **컬렉션**: `users` (`CollectionNames.users`).
- **향후 과제**: `User` 모델 클래스(`fromMap`/`toMap`/`copyWith`) 신설을 권장합니다.

### 4.5 `Hashtag` / `Category` — 해시태그·카테고리

- **위치**: `lib/features/category/data/hashtag_repository.dart` (`HashtagRepository`)
- **현황**: 전용 모델 클래스 없이 `String` 리스트로 다룹니다.
- **API**:
  ```dart
  Stream<List<String>> getHashtagsStream();
  Future<void> addHashtag(String hashtag);
  Future<void> removeHashtag(String hashtag);
  ```
- **컬렉션**: `categories` (`CollectionNames.categories`).

### 4.6 `Submission` — 명언 제보/제출

- **위치**: `lib/features/my_quote/data/submission_repository.dart` (`SubmissionRepository`)
- **현황**: 전용 모델 클래스 없이 `Map<String, dynamic>`으로 다룹니다.
- **공식 필드** (`submitQuote` 파라미터 기준): `text` (`String`), `author` (`String`), `category` (`String`).
  상태 변경은 `updateSubmissionStatus({submissionId, status})`의 `status` (`String`)로 관리합니다.
- **API**:
  ```dart
  Future<void> submitQuote({required String text, required String author, required String category});
  Stream<List<Map<String, dynamic>>> getSubmissionsStream();
  Future<void> updateSubmissionStatus({required String submissionId, required String status});
  ```
- **컬렉션**: `submissions` (`CollectionNames.submissions`).
- **향후 과제**: `status` 값의 enum/상수화 및 `Submission` 모델 클래스 신설을 권장합니다.

### 4.7 `Auth` — 인증

- **위치**: `lib/features/auth/data/dummy_auth_service.dart` (`DummyAuthService`)
- **현황**: 실제 Firebase Auth가 아닌 더미 구현 (`signInAnonymously`, `signInWithGoogle`, `signOut`,
  `currentUserId => 'anonymous_user'`).
- **컬렉션**: `auth` (`CollectionNames.auth`) — 실제 Auth 연동 시 스키마 확정 필요.

## 5. Repository 추상 스펙 (참고)

| Repository             | 위치                                                    | 핵심 메서드                                                                    |
| ---------------------- | ------------------------------------------------------- | ------------------------------------------------------------------------------ |
| `QuoteRepository`      | `lib/features/home/data/quote_repository.dart`          | `getRandomQuote`, `getQuotesStream`, `addQuote`, `updateLike`, `deleteQuote`   |
| `UserRepository`       | `lib/features/mypage/data/user_repository.dart`         | `getUserProfile`, `getUserProfileStream`, `updateUserProfile`, `deleteAccount` |
| `HashtagRepository`    | `lib/features/category/data/hashtag_repository.dart`    | `getHashtagsStream`, `addHashtag`, `removeHashtag`                             |
| `SubmissionRepository` | `lib/features/my_quote/data/submission_repository.dart` | `submitQuote`, `getSubmissionsStream`, `updateSubmissionStatus`                |

> `home_providers.dart`는 `QuoteRepositoryImpl()`을 참조하지만 해당 구현체가
> 아직 존재하지 않습니다. 구현체 추가 시 본 스펙의 `fromMap`/`toMap` 규칙을 따르십시오.
