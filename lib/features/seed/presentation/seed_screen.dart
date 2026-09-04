import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:malssi/core/theme/app_theme.dart';
import 'package:malssi/core/theme/theme_assets.dart';
import 'package:malssi/core/widgets/bottom_nav.dart';
import 'package:malssi/features/quote.dart';
import 'package:malssi/features/seed/providers/seed_providers.dart';

/// 씨앗 탭 (메인). 매일 씨앗 1개 → 탭 1회 → 명언 공개.
class SeedScreen extends StatelessWidget {
  const SeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SeedProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('오늘의 씨앗'),
      ),
      body: _buildBody(context, state),
      bottomNavigationBar: const MainBottomNav(currentIndex: 0),
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
    if (seed.isOpened && quote != null) {
      return SingleChildScrollView(child: _OpenedQuote(quote: quote));
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
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: AppTheme.ink800,
                border: Border.all(color: AppTheme.line),
                borderRadius: BorderRadius.circular(80),
              ),
              child: Center(
                child: _ThemeImage(
                  path: ThemeAssets.seedImage(theme),
                  size: 96,
                  fallbackFontSize: 72,
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
            const SizedBox(height: 6),
            const Text(
              '씨앗을 깨면 오늘의 명언이 열립니다',
              style: TextStyle(fontSize: 12, color: AppTheme.muted),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isBusy
                    ? null
                    : () => context.read<SeedProvider>().openSeed(),
                child: isBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('씨앗 깨기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpenedQuote extends StatelessWidget {
  const _OpenedQuote({required this.quote});

  final Quote quote;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
          child: Row(
            children: [
              _ThemeImage(
                path: ThemeAssets.fruitImage(quote.theme),
                size: 32,
                fallbackFontSize: 24,
              ),
              const SizedBox(width: 8),
              Text(
                '${ThemeAssets.labelOf(quote.theme)} 열매',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        Container(
          margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          padding: const EdgeInsets.fromLTRB(22, 30, 22, 24),
          decoration: BoxDecoration(
            color: AppTheme.ink800,
            border: Border.all(color: AppTheme.line),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('"${quote.text}"', style: AppTheme.quoteTextStyle()),
              const SizedBox(height: 18),
              Text(
                '— ${quote.author}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.gold,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (quote.tags.isNotEmpty) ...[
                const SizedBox(height: 14),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final tag in quote.tags)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          border: Border.all(
                              color: const Color(0xFF3A4A40)),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          '#$tag',
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.sage),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 16, bottom: 24),
          child: Text(
            '🌱 오늘의 열매를 수확했어요 · 보관 탭에서 확인하세요',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: AppTheme.muted),
          ),
        ),
      ],
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
