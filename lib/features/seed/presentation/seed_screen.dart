import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:malssi/core/theme/app_theme.dart';
import 'package:malssi/core/theme/theme_assets.dart';
import 'package:malssi/core/widgets/bottom_nav.dart';
import 'package:malssi/features/archive/domain/fruit.dart';
import 'package:malssi/features/archive/presentation/fruit_review_sheet.dart';
import 'package:malssi/features/quote.dart';
import 'package:malssi/features/seed/domain/seed.dart';
import 'package:malssi/features/seed/providers/seed_providers.dart';

/// 씨앗 탭 (메인). 매일 씨앗 1개 → 탭 1회 → 명언 공개.
class SeedScreen extends StatelessWidget {
  const SeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SeedProvider>();

    return Scaffold(
      // 씨앗 탭(메인)은 모드와 무관하게 항상 다크 고정.
      backgroundColor: AppTheme.ink900,
      body: SafeArea(child: _buildBody(context, state)),
      bottomNavigationBar: const MainBottomNav(currentIndex: 0),
    );
  }

  void _openReview(
      BuildContext context, SeedProvider state, Fruit fruit) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => FruitReviewSheet(
        quoteText: fruit.text,
        author: fruit.author,
        dateLabel: fruit.harvestDateKey.replaceAll('-', '.'),
        imagePath: ThemeAssets.fruitImage(fruit.theme),
        initialMemo: fruit.memo,
        initialScore: fruit.fidelityScore,
        onSave: ({required memo, required fidelityScore}) =>
            state.saveReview(memo: memo, fidelityScore: fidelityScore),
      ),
    );
  }

  Widget _buildBody(BuildContext context, SeedProvider state) {
    if (state.isLoading && state.todaySeed == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final seed = state.todaySeed;
    if (state.errorMessage != null && seed == null) {
      return Center(child: Text('Error: ${state.errorMessage}'));
    }
    if (seed == null) {
      return const Center(child: Text('오늘의 씨앗을 준비할 수 없습니다.'));
    }
    final quote = state.revealedQuote;
    final fruit = state.completedFruit;
    if (seed.isComplete && quote != null) {
      return _OpenedQuote(
        quote: quote,
        fruit: fruit,
        onTapReview: fruit == null
            ? null
            : () => _openReview(context, state, fruit),
      );
    }
    if (seed.isGrowing) {
      // #46: 심자마자 명언을 먼저 보여주고, 그 아래에 성장 에셋을 그린다.
      return _GrowingSeed(
        seed: seed,
        quote: quote,
        isBusy: state.isLoading,
      );
    }
    // 구 `opened` 씨앗 호환: 명언이 있으면 공개 화면.
    if (seed.isOpened && quote != null) {
      return _OpenedQuote(
        quote: quote,
        fruit: fruit,
        onTapReview: fruit == null
            ? null
            : () => _openReview(context, state, fruit),
      );
    }
    return _LockedSeed(
      seedDateKey: seed.dateKey,
      theme: seed.theme,
      isBusy: state.isLoading,
    );
  }
}

class _LockedSeed extends StatelessWidget {
  const _LockedSeed({
    required this.seedDateKey,
    required this.theme,
    required this.isBusy,
  });

  final String seedDateKey;
  final String theme;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                color: AppTheme.ink800,
                border: Border.all(color: AppTheme.line),
                borderRadius: BorderRadius.circular(56),
              ),
              child: Center(
                child: _ThemeImage(
                  path: ThemeAssets.seedImage(theme),
                  size: 64,
                  fallbackFontSize: 48,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              seedDateKey,
              style:
                  const TextStyle(fontSize: 12, color: AppTheme.muted),
            ),
            const SizedBox(height: 6),
            Text(
              '${ThemeAssets.labelOf(theme)} 씨앗이 도착했어요',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.paper,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isBusy
                    ? null
                    : () => context.read<SeedProvider>().plantSeed(),
                child: isBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('씨앗 심기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 성장 중 화면. 명언을 먼저 보여주고 (#46) 그 아래 단계 이미지 + 진행 표시.
/// 디버그에서만 빨리감기 버튼.
class _GrowingSeed extends StatelessWidget {
  const _GrowingSeed({
    required this.seed,
    required this.quote,
    required this.isBusy,
  });

  final Seed seed;

  /// 심을 때 확정한 명언. 없으면(구 데이터) 성장 표시만 보여준다.
  final Quote? quote;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final quote = this.quote;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 40, 32, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (quote != null) ...[
              Text(
                '"${quote.text}"',
                textAlign: TextAlign.center,
                style: AppTheme.quoteTextStyle(fontSize: 26),
              ),
              const SizedBox(height: 12),
              Text(
                '— ${quote.author}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.paper,
                ),
              ),
              const SizedBox(height: 32),
            ],
            Center(
              child: _ThemeImage(
                path: ThemeAssets.growthImage(seed.theme, seed.growthStage),
                size: 120,
                fallbackFontSize: 72,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '${seed.growthStage}단계 성장 중',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.paper,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < Seed.totalStages; i++)
                  Container(
                    width: 10,
                    height: 10,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i <= seed.growthStage
                          ? AppTheme.gold
                          : AppTheme.line,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              '2시간마다 한 단계씩 자라요',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppTheme.muted),
            ),
            if (kDebugMode) ...[
              const SizedBox(height: 24),
              Center(
                child: OutlinedButton(
                  onPressed: isBusy
                      ? null
                      : () =>
                          context.read<SeedProvider>().debugAdvanceGrowth(),
                  child: const Text('디버그: +2시간'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
class _OpenedQuote extends StatelessWidget {
  const _OpenedQuote({
    required this.quote,
    required this.fruit,
    required this.onTapReview,
  });

  final Quote quote;
  final Fruit? fruit;
  final VoidCallback? onTapReview;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTapReview,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(32, 48, 32, 48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '"${quote.text}"',
                textAlign: TextAlign.center,
                style: AppTheme.quoteTextStyle(fontSize: 26),
              ),
              const SizedBox(height: 16),
              Text(
                '— ${quote.author}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.paper,
                ),
              ),
              if (onTapReview != null) ...[
                const SizedBox(height: 24),
                const Text(
                  '눌러서 오늘의 리뷰 남기기',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: AppTheme.muted),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 테마 이미지. 에셋이 없거나 로드에 실패하면 [fallbackFontSize] 크기의 🌱를 보여준다.
class _ThemeImage extends StatelessWidget {
  const _ThemeImage({
    required this.path,
    required this.size,
    required this.fallbackFontSize,
  });

  final String path;
  final double size;
  final double fallbackFontSize;

  @override
  Widget build(BuildContext context) {
    if (path.isEmpty) {
      return Text('🌱', style: TextStyle(fontSize: fallbackFontSize));
    }
    return Image.asset(
      path,
      width: size,
      height: size,
      errorBuilder: (_, __, ___) =>
          Text('🌱', style: TextStyle(fontSize: fallbackFontSize)),
    );
  }
}
