import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:malssi/core/services/debug_clock.dart';
import 'package:malssi/core/services/debug_ui.dart';
import 'package:malssi/core/theme/app_theme.dart';
import 'package:malssi/core/theme/theme_assets.dart';
import 'package:malssi/core/widgets/source_dialog.dart';
import 'package:malssi/features/archive/domain/fruit.dart';
import 'package:malssi/features/archive/presentation/fruit_review_sheet.dart';
import 'package:malssi/features/quote.dart';
import 'package:malssi/features/seed/domain/seed.dart';
import 'package:malssi/features/seed/providers/seed_providers.dart';

/// 씨앗 탭 (메인). 매일 씨앗 1개 → 탭 1회 → 명언 공개.
/// 탭 진입 시마다 성장 상태를 갱신한다 (#62).
class SeedScreen extends StatefulWidget {
  const SeedScreen({super.key});

  @override
  State<SeedScreen> createState() => _SeedScreenState();
}

class _SeedScreenState extends State<SeedScreen> {
  @override
  void initState() {
    super.initState();
    // 진입 시 갱신: 앱 사용 중에도 단계 상승·완성 수확을 반영한다.
    // 빌드 중 notify 방지를 위해 첫 프레임 이후에 호출한다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<SeedProvider>().refreshGrowth();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SeedProvider>();

    return Scaffold(
      // 씨앗 탭(메인)은 모드와 무관하게 항상 니어블랙 고정 (#59).
      // 하단 바는 셸(`AppShellView`)이 상주로 들고 있다 (#79).
      backgroundColor: AppTheme.abyss,
      body: SafeArea(child: _buildBody(context, state)),
    );
  }

  void _openReview(
      BuildContext context, SeedProvider state, Fruit fruit) {
    // #71: 후기를 저장한 뒤에는 읽기만 가능하다.
    final readOnly = fruit.isReviewed;
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
        readOnly: readOnly,
        // #123: 명언별 출처를 후기 카드에서도 볼 수 있다.
        source: fruit.source,
        onSave: readOnly
            ? null
            : ({required memo, required fidelityScore}) =>
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
        isBusy: state.isLoading,
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
        isBusy: state.isLoading,
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
    // 설정 탭의 런타임 스위치로 스크린샷용으로 가릴 수 있다.
    final showDebug = context.watch<DebugUiProvider>().showButtons;
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
            if (showDebug) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: isBusy
                      ? null
                      : () => context
                          .read<SeedProvider>()
                          .debugAdvanceHours(1),
                  child: const Text('디버그: +1시간'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: isBusy
                      ? null
                      : () => context
                          .read<SeedProvider>()
                          .debugAdvanceDay(),
                  child: const Text('디버그: +1일'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 명언 + 저자 블록. 성장/완성 화면에서 재사용한다.
/// 잠금 상태 명언 노출(후속)에도 그대로 얹을 수 있도록 분리했다 (#51).
/// 출처가 비어 있지 않으면 저자 오른쪽 구석에 작게 출처 버튼을 보여준다 (#123).
class _QuoteBlock extends StatelessWidget {
  const _QuoteBlock({required this.quote});

  final Quote quote;

  @override
  Widget build(BuildContext context) {
    return Column(
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
        if (quote.source.isNotEmpty)
          QuoteSourceButton(
            source: quote.source,
            color: AppTheme.muted,
          ),
      ],
    );
  }
}

/// 타이머 표기 (#138). `1시간 23분` → `01:23` (`HH:MM`, 2자리 고정).
/// 1분 미만은 올림해서 `00:01`로 보여준다 (0으로 떨어지는 순간은
/// 완성 단계라 호출자가 완성 문구를 보여준다).
/// 0 이하면 `''` (호출자가 숨긴다).
String formatGrowthTimer(Duration remaining) {
  if (remaining <= Duration.zero) return '';
  final minutes = (remaining.inSeconds + 59) ~/ 60;
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  return '${hours.toString().padLeft(2, '0')}:'
      '${rest.toString().padLeft(2, '0')}';
}

/// 다음 성장까지 남은시간 표시 (#138). 30초마다 다시 계산한다.
/// 성장 에셋 아래에 두며 (에셋 영역 자체에는 문구를 두지 않는다, #57),
/// `다음 성장까지` 라벨(기존 폰트 유지) + 씨앗 UI 수준의 큰 타이머로 보여준다.
/// 최종 단계(완성 임박)에서는 타이머 대신 `열매가 완성되었어요` 문구만 남긴다.
class _GrowthCountdown extends StatefulWidget {
  const _GrowthCountdown({required this.seed});

  final Seed seed;

  @override
  State<_GrowthCountdown> createState() => _GrowthCountdownState();
}

class _GrowthCountdownState extends State<_GrowthCountdown> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        if (mounted) setState(() {});
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.seed.isGrowing) return const SizedBox.shrink();
    // 공용 시계 기준이라 디버그 시간 이동(+1시간/+1일)에도 함께 당겨진다 (#115).
    final timer = formatGrowthTimer(
      widget.seed.timeUntilNextStage(DebugClock.now()),
    );
    // 완성 임박: 문구만 남긴다.
    if (timer.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 8),
        child: Text(
          '열매가 완성되었어요',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 11, color: AppTheme.muted),
        ),
      );
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: Text(
            '다음 성장까지',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppTheme.muted),
          ),
        ),
        Text(
          timer,
          textAlign: TextAlign.center,
          style: AppTheme.quoteTextStyle(fontSize: 48),
        ),
      ],
    );
  }
}

/// 영역에 맞춰 들어가는 테마 이미지. 에셋이 없거나 로드에 실패하면 🌱를 보여준다.
class _ContainImage extends StatelessWidget {
  const _ContainImage({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    if (path.isEmpty) {
      return const Text('🌱', style: TextStyle(fontSize: 64));
    }
    return Image.asset(
      path,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) =>
          const Text('🌱', style: TextStyle(fontSize: 64)),
    );
  }
}

/// 성장 중 화면 (#51). 명언 + 저자가 2/3, 성장 에셋이 1/3을 차지한다.
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
    final showDebug = context.watch<DebugUiProvider>().showButtons;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 명언 + 저자: 나머지 2/3.
        Expanded(
          flex: 2,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: quote == null
                  ? const SizedBox.shrink()
                  : _QuoteBlock(quote: quote),
            ),
          ),
        ),
        // 성장 에셋: 화면의 1/3. 형태만 보여주고 문구·도트는 두지 않는다 (#57).
        Expanded(
          flex: 1,
          child: Center(
            child: _ContainImage(
              path: ThemeAssets.growthImage(
                  seed.theme, seed.growthStage),
            ),
          ),
        ),
        // 남은시간: 씨앗 아래. 라벨 + 큰 타이머, 완성 임박 시 문구만 (#138).
        _GrowthCountdown(seed: seed),
        if (showDebug) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Center(
              // #95: 날짜 이동까지 들어가므로 줄바꿈 가능하게 Wrap.
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: isBusy
                        ? null
                        : () => context
                            .read<SeedProvider>()
                            .debugAdvanceOneStage(),
                    child: const Text('디버그: +1단계'),
                  ),
                  OutlinedButton(
                    onPressed: isBusy
                        ? null
                        : () => context
                            .read<SeedProvider>()
                            .debugCompleteNow(),
                    child: const Text('디버그: 열매 만들기'),
                  ),
                  // #115: 공용 시계를 미뤄 전체 플로우를 검증한다.
                  OutlinedButton(
                    onPressed: isBusy
                        ? null
                        : () => context
                            .read<SeedProvider>()
                            .debugAdvanceHours(1),
                    child: const Text('디버그: +1시간'),
                  ),
                  OutlinedButton(
                    onPressed: isBusy
                        ? null
                        : () => context
                            .read<SeedProvider>()
                            .debugAdvanceDay(),
                    child: const Text('디버그: +1일'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
class _OpenedQuote extends StatelessWidget {
  const _OpenedQuote({
    required this.quote,
    required this.fruit,
    required this.onTapReview,
    required this.isBusy,
  });

  final Quote quote;
  final Fruit? fruit;
  final VoidCallback? onTapReview;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    final fruit = this.fruit;
    final showDebug = context.watch<DebugUiProvider>().showButtons;
    return GestureDetector(
      onTap: onTapReview,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 명언 + 저자: 나머지 2/3.
          Expanded(
            flex: 2,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: _QuoteBlock(quote: quote),
              ),
            ),
          ),
          // 완성 열매: 화면의 1/3 (#51).
          if (fruit != null)
            Expanded(
              flex: 1,
              child: Center(
                child: _ContainImage(
                  path: ThemeAssets.fruitImage(fruit.theme),
                ),
              ),
            ),
          if (onTapReview != null) ...[
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 20),
              child: Text(
                // #71: 저장 후에는 읽기 안내로 바뀐다.
                fruit?.isReviewed == true
                    ? '눌러서 오늘의 리뷰 보기'
                    : '눌러서 오늘의 리뷰 남기기',
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 11, color: AppTheme.muted),
              ),
            ),
          ],
          // #109: 완성 상태에서도 날짜를 옮길 수 있어야 다음 날 씨앗을 볼 수 있다.
          // #115: 공용 시계를 미뤄 전체 플로우를 검증한다.
          if (showDebug) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      onPressed: isBusy
                          ? null
                          : () => context
                              .read<SeedProvider>()
                              .debugAdvanceHours(1),
                      child: const Text('디버그: +1시간'),
                    ),
                    OutlinedButton(
                      onPressed: isBusy
                          ? null
                          : () => context
                              .read<SeedProvider>()
                              .debugAdvanceDay(),
                      child: const Text('디버그: +1일'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
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
