import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';

/// 홈 위젯 데이터 저장소 추상화 (#139).
/// 실제 구현은 `home_widget` 플러그인, 테스트에서는 인메모리 fake을 주입한다.
abstract class HomeWidgetStore {
  Future<void> saveText(String key, String value);
  Future<void> saveInt(String key, int value);
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
  Future<void> saveInt(String key, int value) =>
      HomeWidget.saveWidgetData<int>(
        key,
        value,
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

  /// 성장 상태 키 (#242). `seed_status`는 `Seed.status` 원문
  /// (`locked`/`growing`/`complete`/…), 단계는 0~5 (`Seed.maxGrowthStage`),
  /// 시각은 ISO8601 문자열 (`null` 대신 빈 문자열 저장).
  /// `seed_date`는 씨앗 날짜키 (`YYYY-MM-DD`, #242 후속).
  /// 네이티브가 오늘과 다르면 오래된 데이터로 보고 플레이스홀더를 보여준다
  /// (날짜가 바뀌고 앱이 아직 안 열린 경우).
  static const statusKey = 'seed_status';
  static const stageKey = 'growth_stage';
  static const totalStagesKey = 'growth_total';
  static const nextStageAtKey = 'next_stage_at';
  static const completeAtKey = 'complete_at';
  static const dateKey = 'seed_date';

  /// 씨앗 테마 키 (#253). 잠금 오버레이가 단계 에셋을 고를 때 쓴다.
  static const themeKey = 'seed_theme';

  /// 미공개 상태(심기 전) 플레이스홀더 (#139).
  static const placeholderText = '씨앗을 심으면 오늘의 명언이 보여요';
  static const placeholderAuthor = 'malssi';

  final HomeWidgetStore _store;

  /// 마지막으로 반영한 스냅샷 키 (중복 갱신 방지용, #242).
  /// 명언 id + 상태 + 단계가 같으면 다시 요청하지 않는다
  /// (남은시간은 네이티브가 시각 기준으로 계산한다).
  String? _lastPushedKey;

  /// iOS App Group 등록. `main()`에서 1회 호출한다.
  Future<void> init() async {
    try {
      await HomeWidget.setAppGroupId(appGroupId);
    } catch (e) {
      debugPrint('HomeWidget init failed: $e');
    }
  }

  /// 씨앗 스냅샷을 위젯에 반영한다 (#242).
  /// [status]는 `Seed.status` 원문, [stage]는 0~5, 시각 2종은 ISO8601
  /// (`growing`이 아니면 빈 문자열), [seedDate]는 씨앗 날짜키.
  /// 같은 명언·상태·단계·날짜면 요청하지 않는다.
  Future<void> updateSeed({
    required String quoteId,
    required String text,
    required String author,
    required String status,
    required int stage,
    required int totalStages,
    required String seedDate,
    String nextStageAtIso = '',
    String completeAtIso = '',
    String theme = '',
  }) async {
    final key = '$quoteId|$status|$stage|$seedDate';
    if (key == _lastPushedKey) return;
    try {
      await _store.saveText(quoteKey, text);
      await _store.saveText(authorKey, author);
      await _store.saveText(statusKey, status);
      await _store.saveText(themeKey, theme);
      await _store.saveInt(stageKey, stage);
      await _store.saveInt(totalStagesKey, totalStages);
      await _store.saveText(dateKey, seedDate);
      await _store.saveText(nextStageAtKey, nextStageAtIso);
      await _store.saveText(completeAtKey, completeAtIso);
      await _store.requestUpdate();
      _lastPushedKey = key;
    } catch (e) {
      debugPrint('HomeWidget update failed: $e');
    }
  }

  /// 공개된 명언을 위젯에 반영한다. 같은 id면 요청하지 않는다.
  /// 성장 정보 없는 구 경로 (#139 호환, 신규 코드는 `updateSeed` 사용).
  Future<void> updateQuote({
    required String quoteId,
    required String text,
    required String author,
  }) =>
      updateSeed(
        quoteId: quoteId,
        text: text,
        author: author,
        status: 'growing',
        stage: 0,
        totalStages: 0,
        seedDate: '',
      );

  /// 미공개 상태 플레이스홀더를 보여준다 (성장 정보 초기화 포함, #242).
  Future<void> updatePlaceholder() => updateSeed(
        quoteId: 'placeholder',
        text: placeholderText,
        author: placeholderAuthor,
        status: 'locked',
        stage: 0,
        totalStages: 0,
        seedDate: '',
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
