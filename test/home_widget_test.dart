import 'package:flutter_test/flutter_test.dart';
import 'package:malssi/core/services/home_widget_service.dart';

class FakeHomeWidgetStore implements HomeWidgetStore {
  final saved = <String, String>{};
  var updateRequests = 0;
  var shouldThrow = false;

  @override
  Future<void> saveText(String key, String value) async {
    if (shouldThrow) throw StateError('store unavailable');
    saved[key] = value;
  }

  @override
  Future<void> requestUpdate() async {
    if (shouldThrow) throw StateError('store unavailable');
    updateRequests++;
  }
}

void main() {
  group('HomeWidgetService (#139)', () {
    test('updateQuote saves text and author then requests update', () async {
      final store = FakeHomeWidgetStore();
      final service = HomeWidgetService(store: store);

      await service.updateQuote(
          quoteId: 'q1', text: '아는 것이 힘이다.', author: '베이컨');

      expect(store.saved[HomeWidgetService.quoteKey], '아는 것이 힘이다.');
      expect(store.saved[HomeWidgetService.authorKey], '베이컨');
      expect(store.updateRequests, 1);
    });

    test('same quote id is not pushed twice', () async {
      final store = FakeHomeWidgetStore();
      final service = HomeWidgetService(store: store);

      await service.updateQuote(quoteId: 'q1', text: 't', author: 'a');
      await service.updateQuote(quoteId: 'q1', text: 't', author: 'a');

      expect(store.updateRequests, 1);
    });

    test('new quote id pushes again', () async {
      final store = FakeHomeWidgetStore();
      final service = HomeWidgetService(store: store);

      await service.updateQuote(quoteId: 'q1', text: 't1', author: 'a1');
      await service.updateQuote(quoteId: 'q2', text: 't2', author: 'a2');

      expect(store.updateRequests, 2);
      expect(store.saved[HomeWidgetService.quoteKey], 't2');
    });

    test('store failure does not throw and retries later', () async {
      final store = FakeHomeWidgetStore()..shouldThrow = true;
      final service = HomeWidgetService(store: store);

      await service.updateQuote(quoteId: 'q1', text: 't', author: 'a');
      expect(store.updateRequests, 0);

      store.shouldThrow = false;
      await service.updateQuote(quoteId: 'q1', text: 't', author: 'a');
      expect(store.updateRequests, 1);
    });

    test('updatePlaceholder shows the locked-seed copy', () async {
      final store = FakeHomeWidgetStore();
      final service = HomeWidgetService(store: store);

      await service.updatePlaceholder();

      expect(store.saved[HomeWidgetService.quoteKey],
          HomeWidgetService.placeholderText);
      expect(store.saved[HomeWidgetService.authorKey],
          HomeWidgetService.placeholderAuthor);
      expect(store.updateRequests, 1);
    });
  });
}
