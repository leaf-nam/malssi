import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:malssi/core/theme/theme_assets.dart';
import 'package:malssi/core/widgets/bottom_nav.dart';
import 'package:malssi/features/archive/domain/fruit.dart';
import 'package:malssi/features/archive/presentation/fruit_review_sheet.dart';
import 'package:malssi/features/archive/providers/archive_providers.dart';

/// 보관 탭. 1년 단위 잔디 그리드로 수확 현황을 보여준다.
/// 각 칸은 해당 날짜 열매의 테마 색상이며, 터치하면 상세 카드가 열린다.
class ArchiveScreen extends StatelessWidget {
  const ArchiveScreen({super.key});

  /// 테스트용 오늘 날짜 고정. `null`이면 실제 오늘.
  static DateTime? debugToday;

  static String formatDate(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}.$m.$d';
  }

  static String dateKeyOf(DateTime date) {
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ArchiveProvider>();

    return Scaffold(
      body: SafeArea(child: _buildBody(context, state)),
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
    final today = debugToday ?? DateTime.now();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '최근 1년 · ${state.fruits.length}개의 열매',
            style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          _GrassGrid(
            today: DateTime(today.year, today.month, today.day),
            fruitsByDateKey: state.fruitsByDateKey,
            onTapFruit: (fruit) => _openDetail(context, fruit),
          ),
          if (state.fruits.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                '말씨 탭에서 오늘의 씨앗을 깨면 잔디가 채워져요',
                style: TextStyle(
                    fontSize: 12, color: colors.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }

  /// 보관 상세는 읽기 전용: 저장된 별점·후기만 보여준다.
  /// 후기 작성은 말씨 탭의 완성 열매 흐름에서만 가능하다 (#48).
  void _openDetail(BuildContext context, Fruit fruit) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => FruitReviewSheet(
        quoteText: fruit.text,
        author: fruit.author,
        dateLabel: formatDate(fruit.harvestedAt),
        imagePath: ThemeAssets.fruitImage(fruit.theme),
        initialMemo: fruit.memo,
        initialScore: fruit.fidelityScore,
        readOnly: true,
      ),
    );
  }
}

/// GitHub 잔디 스타일 그리드. 열 = 주(최근 53주), 행 = 월~일.
class _GrassGrid extends StatelessWidget {
  const _GrassGrid({
    required this.today,
    required this.fruitsByDateKey,
    required this.onTapFruit,
  });

  final DateTime today;
  final Map<String, Fruit> fruitsByDateKey;
  final ValueChanged<Fruit> onTapFruit;

  static const _cellSize = 22.0;
  static const _cellGap = 4.0;

  @override
  Widget build(BuildContext context) {
    // 오늘이 포함된 주 월요일 기준, 52주 전 월요일부터 53개 주.
    final thisMonday =
        today.subtract(Duration(days: today.weekday - 1));
    final startMonday = thisMonday.subtract(const Duration(days: 7 * 52));
    final divider = Theme.of(context).dividerColor;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      reverse: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var week = 0; week < 53; week++)
            Padding(
              padding: EdgeInsets.only(
                  right: week == 52 ? 0 : _cellGap),
              child: Column(
                children: [
                  for (var day = 0; day < 7; day++)
                    Padding(
                      padding: EdgeInsets.only(
                          bottom: day == 6 ? 0 : _cellGap),
                      child: _cell(
                        context,
                        startMonday.add(
                            Duration(days: week * 7 + day)),
                        divider,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _cell(
      BuildContext context, DateTime date, Color divider) {
    if (date.isAfter(today)) {
      return const SizedBox(width: _cellSize, height: _cellSize);
    }
    final fruit = fruitsByDateKey[ArchiveScreen.dateKeyOf(date)];
    if (fruit == null) {
      return Container(
        width: _cellSize,
        height: _cellSize,
        decoration: BoxDecoration(
          border: Border.all(color: divider),
          borderRadius: BorderRadius.circular(5),
        ),
      );
    }
    return GestureDetector(
      key: ValueKey('grass-${fruit.harvestDateKey}'),
      onTap: () => onTapFruit(fruit),
      child: Container(
        width: _cellSize,
        height: _cellSize,
        decoration: BoxDecoration(
          // #56: 라이트 테마에서는 밝은 열매색, 다크에서는 다크톤.
          color: ThemeAssets.cellColor(
              fruit.theme, Theme.of(context).brightness),
          borderRadius: BorderRadius.circular(5),
        ),
      ),
    );
  }
}
