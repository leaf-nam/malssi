import 'package:flutter_test/flutter_test.dart';
import 'package:malssi/core/services/home_widget_service.dart';

class FakeHomeWidgetStore implements HomeWidgetStore {
  final saved = <String, String>{};
  final savedInts = <String, int>{};
  var updateRequests = 0;
  var shouldThrow = false;

  @override
  Future<void> saveText(String key, String value) async {
    if (shouldThrow) throw StateError('store unavailable');
    saved[key] = value;
  }

  @override
  Future<void> saveInt(String key, int value) async {
    if (shouldThrow) throw StateError('store unavailable');
    savedInts[key] = value;
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

  group('HomeWidgetService growth snapshot (#242)', () {
    Future<void> push(
      HomeWidgetService service, {
      String quoteId = 'q1',
      String status = 'growing',
      int stage = 2,
      String seedDate = '2030-01-01',
      String theme = 'peace',
    }) =>
        service.updateSeed(
          quoteId: quoteId,
          text: 't',
          author: 'a',
          status: status,
          stage: stage,
          totalStages: 6,
          seedDate: seedDate,
          theme: theme,
          nextStageAtIso: '2030-01-01T00:00:00.000',
          completeAtIso: '2030-01-01T08:00:00.000',
        );

    test('updateSeed saves growth keys', () async {
      final store = FakeHomeWidgetStore();
      final service = HomeWidgetService(store: store);

      await push(service);

      expect(store.saved[HomeWidgetService.statusKey], 'growing');
      expect(store.savedInts[HomeWidgetService.stageKey], 2);
      expect(store.savedInts[HomeWidgetService.totalStagesKey], 6);
      expect(store.saved[HomeWidgetService.dateKey], '2030-01-01');
      // #253: 잠금 오버레이가 단계 에셋을 고를 때 쓴다.
      expect(store.saved[HomeWidgetService.themeKey], 'peace');
      expect(store.saved[HomeWidgetService.nextStageAtKey],
          '2030-01-01T00:00:00.000');
      expect(store.saved[HomeWidgetService.completeAtKey],
          '2030-01-01T08:00:00.000');
      expect(store.updateRequests, 1);
    });

    test('same snapshot is not pushed twice', () async {
      final store = FakeHomeWidgetStore();
      final service = HomeWidgetService(store: store);

      await push(service);
      await push(service);

      expect(store.updateRequests, 1);
    });

    test('stage advance pushes again', () async {
      final store = FakeHomeWidgetStore();
      final service = HomeWidgetService(store: store);

      await push(service, stage: 2);
      await push(service, stage: 3);

      expect(store.updateRequests, 2);
      expect(store.savedInts[HomeWidgetService.stageKey], 3);
    });

    test('status change pushes again', () async {
      final store = FakeHomeWidgetStore();
      final service = HomeWidgetService(store: store);

      await push(service, status: 'growing');
      await push(service, status: 'complete');

      expect(store.updateRequests, 2);
    });

    test('placeholder resets growth keys', () async {
      final store = FakeHomeWidgetStore();
      final service = HomeWidgetService(store: store);

      await push(service);
      await service.updatePlaceholder();

      expect(store.saved[HomeWidgetService.statusKey], 'locked');
      expect(store.savedInts[HomeWidgetService.stageKey], 0);
      expect(store.saved[HomeWidgetService.dateKey], '');
      expect(store.saved[HomeWidgetService.completeAtKey], '');
      expect(store.updateRequests, 2);
    });

    test('date change pushes again', () async {
      final store = FakeHomeWidgetStore();
      final service = HomeWidgetService(store: store);

      await push(service, seedDate: '2030-01-01');
      await push(service, seedDate: '2030-01-02');

      expect(store.updateRequests, 2);
      expect(store.saved[HomeWidgetService.dateKey], '2030-01-02');
    });
  });
}
