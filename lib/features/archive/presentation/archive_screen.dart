import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:malssi/core/theme/app_theme.dart';
import 'package:malssi/core/theme/theme_assets.dart';
import 'package:malssi/core/widgets/bottom_nav.dart';
import 'package:malssi/features/archive/domain/fruit.dart';
import 'package:malssi/features/archive/providers/archive_providers.dart';

/// 보관 탭. 지금까지 수확한 열매들을 수확일 내림차순으로 보여준다.
class ArchiveScreen extends StatelessWidget {
  const ArchiveScreen({super.key});

  static String formatDate(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}.$m.$d';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ArchiveProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('보관')),
      body: _buildBody(context, state),
      bottomNavigationBar: const MainBottomNav(currentIndex: 1),
    );
  }

  Widget _buildBody(BuildContext context, ArchiveProvider state) {
    final colors = Theme.of(context).colorScheme;
    if (state.isLoading && state.fruits.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.errorMessage != null && state.fruits.isEmpty) {
      return Center(child: Text('Error: ${state.errorMessage}'));
    }
    if (state.fruits.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🧺', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              Text(
                '아직 수확한 열매가 없어요',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '씨앗 탭에서 오늘의 씨앗을 깨보세요',
                style: TextStyle(
                    fontSize: 12, color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      itemCount: state.fruits.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) =>
          _FruitCard(fruit: state.fruits[index]),
    );
  }
}

class _FruitCard extends StatelessWidget {
  const _FruitCard({required this.fruit});

  final Fruit fruit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _FruitIcon(theme: fruit.theme),
              const SizedBox(width: 6),
              Text(
                ArchiveScreen.formatDate(fruit.harvestedAt),
                style: TextStyle(
                    fontSize: 11.5, color: colors.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '"${fruit.text}"',
            style: AppTheme.quoteTextStyle(fontSize: 16)
                .copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            '— ${fruit.author}',
            style: TextStyle(
              fontSize: 12,
              color: colors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// 열매 테마 아이콘. 에셋이 없거나 로드에 실패하면 🌱를 보여준다.
class _FruitIcon extends StatelessWidget {
  const _FruitIcon({required this.theme});

  final String theme;

  @override
  Widget build(BuildContext context) {
    final path = ThemeAssets.fruitImage(theme);
    if (path.isEmpty) {
      return const Text('🌱', style: TextStyle(fontSize: 14));
    }
    return Image.asset(
      path,
      width: 20,
      height: 20,
      errorBuilder: (_, __, ___) =>
          const Text('🌱', style: TextStyle(fontSize: 14)),
    );
  }
}
