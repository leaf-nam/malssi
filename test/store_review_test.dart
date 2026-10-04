import 'package:flutter_test/flutter_test.dart';
import 'package:malssi/core/services/store_review_service.dart';

class FakeReviewRequestStore implements ReviewRequestStore {
  var count = 0;

  @override
  Future<int> loadCount() async => count;

  @override
  Future<void> saveCount(int value) async {
    count = value;
  }
}

class FakeReviewGateway implements ReviewGateway {
  var available = true;
  var requests = 0;
  var shouldThrow = false;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<void> request() async {
    if (shouldThrow) throw StateError('review unavailable');
    requests++;
  }
}

StoreReviewService buildService({
  FakeReviewRequestStore? store,
  FakeReviewGateway? gateway,
}) =>
    StoreReviewService(
      store: store ?? FakeReviewRequestStore(),
      gateway: gateway ?? FakeReviewGateway(),
    );

void main() {
  group('StoreReviewService (#153)', () {
    test('requests on high scores', () async {
      final store = FakeReviewRequestStore();
      final gateway = FakeReviewGateway();
      final service = buildService(store: store, gateway: gateway);

      expect(await service.maybeRequestReview(score: 5), isTrue);
      expect(gateway.requests, 1);
      expect(store.count, 1);
    });

    test('skips low scores without counting', () async {
      final store = FakeReviewRequestStore();
      final gateway = FakeReviewGateway();
      final service = buildService(store: store, gateway: gateway);

      expect(await service.maybeRequestReview(score: 3), isFalse);
      expect(gateway.requests, 0);
      expect(store.count, 0);
    });

    test('stops after max requests', () async {
      final store = FakeReviewRequestStore()..count = 3;
      final gateway = FakeReviewGateway();
      final service = buildService(store: store, gateway: gateway);

      expect(await service.maybeRequestReview(score: 5), isFalse);
      expect(gateway.requests, 0);
    });

    test('skips when the platform is unavailable', () async {
      final store = FakeReviewRequestStore();
      final gateway = FakeReviewGateway()..available = false;
      final service = buildService(store: store, gateway: gateway);

      expect(await service.maybeRequestReview(score: 5), isFalse);
      expect(store.count, 0);
    });

    test('gateway failure does not throw', () async {
      final store = FakeReviewRequestStore();
      final gateway = FakeReviewGateway()..shouldThrow = true;
      final service = buildService(store: store, gateway: gateway);

      expect(await service.maybeRequestReview(score: 5), isFalse);
      expect(store.count, 0);
    });
  });
}
