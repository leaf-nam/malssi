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
      // 씨앗 탭(메인)은 모드와 무관하게 항상 다크 고정.
      backgroundColor: AppTheme.ink900,
      appBar: AppBar(
        backgroundColor: AppTheme.ink900,
        foregroundColor: AppTheme.paper,
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
    return Center(
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
          ],
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
