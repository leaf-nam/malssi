import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 스토어 리뷰 요청 횟수 저장소 추상화 (#153).
/// 실제 구현은 `SharedPreferences`, 테스트에서는 인메모리 fake을 주입한다.
abstract class ReviewRequestStore {
  Future<int> loadCount();
  Future<void> saveCount(int count);
}

/// `SharedPreferences` 기반 저장소 (실기기용).
class PrefsReviewRequestStore implements ReviewRequestStore {
  @visibleForTesting
  static const key = 'store_review_requests';

  @override
  Future<int> loadCount() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key) ?? 0;
  }

  @override
  Future<void> saveCount(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, count);
  }
}

/// 네이티브 스토어 리뷰 호출 추상화 (#153).
abstract class ReviewGateway {
  Future<bool> isAvailable();
  Future<void> request();
}

/// `in_app_review` 플러그인 기반 호출 (실기기용).
class InAppReviewGateway implements ReviewGateway {
  @override
  Future<bool> isAvailable() => InAppReview.instance.isAvailable();

  @override
  Future<void> request() => InAppReview.instance.requestReview();
}

/// 스토어 별점 유도 (#153).
/// 열매 리뷰 저장 직후(별점 4~5)에만 요청하고, 통산 3회로 상한을 둔다.
/// 실제 노출 여부는 OS 쿼터가 정한다. 실패해도 앱 동작에 영향없다.
class StoreReviewService {
  StoreReviewService({ReviewRequestStore? store, ReviewGateway? gateway})
      : _store = store ?? PrefsReviewRequestStore(),
        _gateway = gateway ?? InAppReviewGateway();

  static StoreReviewService _instance = StoreReviewService();
  static StoreReviewService get instance => _instance;

  @visibleForTesting
  static set instance(StoreReviewService service) => _instance = service;

  /// 앱 차원 요청 상한.
  static const maxRequests = 3;

  /// 요청 최소 별점 (열매 리뷰 0~5 기준).
  static const minScore = 4;

  final ReviewRequestStore _store;
  final ReviewGateway _gateway;

  /// 조건 충족 시 스토어 리뷰를 요청하고 `true`를 반환한다.
  Future<bool> maybeRequestReview({required int score}) async {
    try {
      if (score < minScore) return false;
      final count = await _store.loadCount();
      if (count >= maxRequests) return false;
      if (!await _gateway.isAvailable()) return false;
      await _gateway.request();
      await _store.saveCount(count + 1);
      return true;
    } catch (e) {
      debugPrint('StoreReview request failed: $e');
      return false;
    }
  }
}
