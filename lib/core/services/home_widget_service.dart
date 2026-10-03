import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

/// 홈 위젯 데이터 저장소 추상화 (#139).
/// 실제 구현은 `home_widget` 플러그인, 테스트에서는 인메모리 fake을 주입한다.
abstract class HomeWidgetStore {
  Future<void> saveText(String key, String value);
  Future<void> requestUpdate();
}

/// `home_widget` 플러그인 기반 저장소 (실기기용).
class HomeWidgetPluginStore implements HomeWidgetStore {
  @override
  Future<void> saveText(String key, String value) =>
      HomeWidget.saveWidgetData<String>(
        key,
        value,
        // 호출마다 명시해 init 순서 의존을 없앤다 (#139).
        appGroupId: HomeWidgetService.appGroupId,
      );

  @override
  Future<void> requestUpdate() => HomeWidget.updateWidget(
        androidName: HomeWidgetService.androidProviderName,
        iOSName: HomeWidgetService.iOSWidgetKind,
        qualifiedAndroidName:
            HomeWidgetService.qualifiedAndroidProvider,
      );
}

/// 홈 위젯(오늘의 명언 + 저자) 동기화 서비스 (#139).
/// 명언은 `SeedProvider.revealedQuote`가 바뀔 때 `app.dart` 리스너가
/// 여기로 전달한다. 실패해도 앱 동작에 영향주지 않는다.
class HomeWidgetService {
  HomeWidgetService({HomeWidgetStore? store})
      : _store = store ?? HomeWidgetPluginStore();

  static HomeWidgetService _instance = HomeWidgetService();
  static HomeWidgetService get instance => _instance;

  @visibleForTesting
  static set instance(HomeWidgetService service) => _instance = service;

  /// iOS App Group (Xcode 위젯 타깃과 공유, #139).
  static const appGroupId = 'group.com.leaf.malssi';

  /// Android 위젯 프로바이더 (`MalssiWidgetProvider`, #139).
  static const androidProviderName = 'MalssiWidgetProvider';
  static const qualifiedAndroidProvider =
      'com.leaf.malssi.MalssiWidgetProvider';

  /// iOS 위젯 kind (`MalssiWidget`, #139).
  static const iOSWidgetKind = 'MalssiWidget';

  /// 위젯 탭 시 열리는 딥링크 (말씨 탭 `/`으로 이동, #139).
  static const clickUri = 'malssi://widget?target=seed';

  static const quoteKey = 'quote_text';
  static const authorKey = 'quote_author';

  /// 미공개 상태(심기 전) 플레이스홀더 (#139).
  static const placeholderText = '씨앗을 심으면 오늘의 명언이 보여요';
  static const placeholderAuthor = 'malssi';

  final HomeWidgetStore _store;

  /// 마지막으로 반영한 명언 id (중복 갱신 방지용).
  String? _lastPushedId;

  /// iOS App Group 등록. `main()`에서 1회 호출한다.
  Future<void> init() async {
    try {
      await HomeWidget.setAppGroupId(appGroupId);
    } catch (e) {
      debugPrint('HomeWidget init failed: $e');
    }
  }

  /// 공개된 명언을 위젯에 반영한다. 같은 id면 요청하지 않는다.
  Future<void> updateQuote({
    required String quoteId,
    required String text,
    required String author,
  }) async {
    if (quoteId == _lastPushedId) return;
    try {
      await _store.saveText(quoteKey, text);
      await _store.saveText(authorKey, author);
      await _store.requestUpdate();
      _lastPushedId = quoteId;
    } catch (e) {
      debugPrint('HomeWidget update failed: $e');
    }
  }

  /// 미공개 상태 플레이스홀더를 보여준다.
  Future<void> updatePlaceholder() => updateQuote(
        quoteId: 'placeholder',
        text: placeholderText,
        author: placeholderAuthor,
      );

  /// 위젯 탭으로 실행됐을 때의 URI (`null`이면 일반 실행).
  static Future<Uri?> initialLaunchUri() async {
    try {
      return await HomeWidget.initiallyLaunchedFromHomeWidget();
    } catch (_) {
      return null;
    }
  }

  /// 실행 중 위젯 탭 스트림 (탭 → 말씨 탭 이동, #139).
  static Stream<Uri?> get clicks => HomeWidget.widgetClicked;
}
