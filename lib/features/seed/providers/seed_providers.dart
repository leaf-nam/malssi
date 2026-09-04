import 'package:flutter/foundation.dart';
import 'package:malssi/features/archive/data/fruit_repository.dart';
import 'package:malssi/features/home/data/quote_repository.dart';
import 'package:malssi/features/quote.dart';
import 'package:malssi/features/seed/data/seed_repository.dart';
import 'package:malssi/features/seed/domain/seed.dart';

/// 씨앗 탭 상태. `provider` + [ChangeNotifier] 패턴 (컨벤션 §3).
class SeedProvider extends ChangeNotifier {
  SeedProvider({
    required this._seedRepository,
    required this._quoteRepository,
    required this._fruitRepository,
  });

  final SeedRepository _seedRepository;
  final QuoteRepository _quoteRepository;
  final FruitRepository _fruitRepository;

  Seed? _todaySeed;
  Seed? get todaySeed => _todaySeed;

  Quote? _revealedQuote;
  Quote? get revealedQuote => _revealedQuote;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// 오늘의 씨앗을 준비한다 (없으면 생성). 앱 시작 시 1회 호출.
  Future<void> ensureTodaySeed() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _todaySeed = await _seedRepository.getTodaySeed();
      if (_todaySeed!.isOpened && _todaySeed!.quoteId.isNotEmpty) {
        // 재시작 후 복원: 이미 개봉된 씨앗이면 명언은 보관 기록에서 찾는다.
        final fruits = await _fruitRepository.getFruits();
        for (final fruit in fruits) {
          if (fruit.seedId == _todaySeed!.id) {
            _revealedQuote = Quote(
              id: fruit.quoteId,
              text: fruit.text,
              author: fruit.author,
              likes: 0,
              createdAt: fruit.harvestedAt,
            );
            break;
          }
        }
      }
    } catch (e) {
      _errorMessage = '$e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 씨앗을 탭 1회로 깨고 명언을 공개 + 열매를 수확한다. 광고 게이트 없음.
  Future<void> openSeed() async {
    final seed = _todaySeed;
    if (seed == null || !seed.isLocked) return;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final quote = await _quoteRepository.getRandomQuote();
      _todaySeed =
          await _seedRepository.openSeed(seedId: seed.id, quote: quote);
      await _fruitRepository.harvestFromSeed(seed: _todaySeed!, quote: quote);
      _revealedQuote = quote;
    } catch (e) {
      _errorMessage = '$e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
