import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:malssi/features/archive/data/fruit_repository.dart';
import 'package:malssi/features/archive/domain/fruit.dart';
import 'package:malssi/features/home/data/quote_repository.dart';
import 'package:malssi/features/quote.dart';
import 'package:malssi/features/seed/data/seed_repository.dart';
import 'package:malssi/features/seed/domain/seed.dart';

/// 씨앗 탭 상태. `provider` + [ChangeNotifier] 패턴 (컨벤션 §3).
///
/// 성장 플로우 (#40, #46): 심기(명언 즉시 공개) → 단계 간격 성장(0~5단계) →
/// 완성 시 열매 수확. 명언 아래에 성장 에셋을 함께 보여준다.
/// `enableAutoRefresh`가 켜지면 주기적으로 성장을 갱신한다.
/// 간격은 디버그 5초 / 릴리즈 15분 (#64).
/// 테스트에서는 꺼둔다 (보류 타이머 방지).
class SeedProvider extends ChangeNotifier {
  SeedProvider({
    required this._seedRepository,
    required this._quoteRepository,
    required this._fruitRepository,
    bool enableAutoRefresh = false,
  }) {
    if (enableAutoRefresh) {
      _timer = Timer.periodic(
        refreshInterval,
        (_) => refreshGrowth(),
      );
    }
  }

  /// 자동 갱신 간격. 디버그 5초 / 릴리즈 15분 (#64).
  static Duration get refreshInterval => kDebugMode
      ? const Duration(seconds: 5)
      : const Duration(minutes: 15);

  final SeedRepository _seedRepository;
  final QuoteRepository _quoteRepository;
  final FruitRepository _fruitRepository;
  Timer? _timer;

  Seed? _todaySeed;

  /// 현재 보여줄 씨앗 (이월된 성장 중 씨앗 우선).
  Seed? get todaySeed => _todaySeed;

  Quote? _revealedQuote;
  Quote? get revealedQuote => _revealedQuote;

  /// 심을 때 확정한 명언. 수확 시 스냅샷 원본으로 사용한다.
  Quote? _plantedQuote;

  /// 완성된 씨앗의 열매. 리뷰 진입에 사용한다.
  Fruit? _completedFruit;
  Fruit? get completedFruit => _completedFruit;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// 오늘의 씨앗을 준비한다 (없으면 생성, 성장 중이면 이월).
  /// 완성된 씨앗은 열매를 수확하고 명언을 복원한다. 앱 시작 시 1회 호출.
  Future<void> ensureTodaySeed() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _todaySeed = await _seedRepository.getActiveSeed();
      await _maybeHarvest();
    } catch (e) {
      _errorMessage = '$e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 씨앗을 심는다 (`locked` → `growing`). 명언은 심는 즉시 공개된다 (#46).
  Future<void> plantSeed() async {
    final seed = _todaySeed;
    if (seed == null || !seed.isLocked) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      // 씨앗과 같은 테마의 명언을 미리 확정한다.
      // 해당 테마 명언이 없으면 전체에서 랜덤 (저장소 폴백).
      final quote =
          await _quoteRepository.getRandomQuoteByTheme(seed.theme);
      _todaySeed =
          await _seedRepository.plantSeed(seedId: seed.id, quote: quote);
      _plantedQuote = quote;
      _revealedQuote = quote;
    } catch (e) {
      _errorMessage = '$e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 성장 단계를 갱신하고, 완성됐으면 수확한다 (타이머·재개 시 호출).
  Future<void> refreshGrowth() async {
    try {
      _todaySeed = await _seedRepository.getActiveSeed();
      await _maybeHarvest();
    } catch (e) {
      _errorMessage = '$e';
    } finally {
      notifyListeners();
    }
  }

  /// 디버그용: 2시간 빨리감기. 릴리즈 UI에서 호출하지 않는다.
  Future<void> debugAdvanceGrowth() async {
    final seed = _todaySeed;
    if (seed == null || !seed.isGrowing) return;
    await _debugShift(const Duration(hours: Seed.stageHours));
  }

  /// 디버그용: 1단계만 진행 (#69). 릴리즈 UI에서 호출하지 않는다.
  Future<void> debugAdvanceOneStage() async {
    final seed = _todaySeed;
    if (seed == null || !seed.isGrowing) return;
    await _debugShift(Seed.stageInterval);
  }

  /// 디버그용: 즉시 완성·수확 (#69). 릴리즈 UI에서 호출하지 않는다.
  Future<void> debugCompleteNow() async {
    final seed = _todaySeed;
    if (seed == null || !seed.isGrowing) return;
    await _debugShift(Seed.stageInterval * Seed.totalStages);
  }

  Future<void> _debugShift(Duration by) async {
    final seed = _todaySeed;
    if (seed == null) return;
    try {
      await _seedRepository.debugFastForward(seedId: seed.id, by: by);
      _todaySeed = await _seedRepository.getActiveSeed();
      await _maybeHarvest();
    } catch (e) {
      _errorMessage = '$e';
    } finally {
      notifyListeners();
    }
  }

  /// 완성된 씨앗의 열매가 없으면 수확하고 명언을 공개한다.
  Future<void> _maybeHarvest() async {
    final seed = _todaySeed;
    if (seed == null || !seed.isComplete || seed.quoteId.isEmpty) {
      // 완성 전이면 기존 복원(구 opened 호환)만 시도한다.
      await _restoreRevealedQuote();
      return;
    }
    final fruits = await _fruitRepository.getFruits();
    for (final fruit in fruits) {
      if (fruit.seedId == seed.id) {
        _completedFruit = fruit;
        _revealedQuote = Quote(
          id: fruit.quoteId,
          text: fruit.text,
          author: fruit.author,
          likes: 0,
          createdAt: fruit.harvestedAt,
          theme: fruit.theme,
        );
        return;
      }
    }
    // 미수확 완성 씨앗 → 열매 수확 + 명언 공개.
    // 심을 때 확정한 명언을 우선 사용하고, 없으면 원천에서 조회한다.
    final planted = _plantedQuote;
    late final Quote harvestQuote;
    if (planted != null && planted.id == seed.quoteId) {
      harvestQuote = planted;
    } else {
      harvestQuote = await _findPlantedQuote(seed);
    }
    await _fruitRepository.harvestFromSeed(seed: seed, quote: harvestQuote);
    final refreshed = await _fruitRepository.getFruits();
    for (final fruit in refreshed) {
      if (fruit.seedId == seed.id) {
        _completedFruit = fruit;
        break;
      }
    }
    _revealedQuote = harvestQuote;
  }

  /// 완성 열매의 후기·점수를 저장한다 (그날의 리뷰, 덮어쓰기 허용).
  Future<void> saveReview({
    required String memo,
    required int fidelityScore,
  }) async {
    final fruit = _completedFruit;
    if (fruit == null) return;
    _errorMessage = null;
    notifyListeners();
    try {
      _completedFruit = await _fruitRepository.updateReview(
        fruitId: fruit.id,
        memo: memo,
        fidelityScore: fidelityScore,
      );
    } catch (e) {
      _errorMessage = '$e';
    } finally {
      notifyListeners();
    }
  }

  /// 수확 원본 명언 조회: 원천 스트림에서 `quoteId` 일치 → 없으면 테마 랜덤.
  Future<Quote> _findPlantedQuote(Seed seed) async {
    final quotes = await _quoteRepository.getQuotesStream().first;
    for (final q in quotes) {
      if (q.id == seed.quoteId) return q;
    }
    return _quoteRepository.getRandomQuoteByTheme(seed.theme);
  }

  /// 재시작 후 복원: 성장 중 씨앗이면 확정한 명언을, 수확된 씨앗이면
  /// 보관 기록에서 명언을 찾는다.
  Future<void> _restoreRevealedQuote() async {
    final seed = _todaySeed;
    if (seed == null || seed.quoteId.isEmpty) return;
    if (_revealedQuote != null && _revealedQuote!.id == seed.quoteId) return;
    final fruits = await _fruitRepository.getFruits();
    for (final fruit in fruits) {
      if (fruit.seedId == seed.id) {
        _completedFruit = fruit;
        _revealedQuote = Quote(
          id: fruit.quoteId,
          text: fruit.text,
          author: fruit.author,
          likes: 0,
          createdAt: fruit.harvestedAt,
          theme: fruit.theme,
        );
        return;
      }
    }
    // 미수확 성장 중 씨앗: 심을 때 확정한 명언을 다시 보여준다 (#46).
    if (seed.isGrowing) {
      _revealedQuote = await _findPlantedQuote(seed);
    }
  }
}
