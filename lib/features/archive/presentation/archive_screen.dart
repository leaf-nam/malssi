import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:malssi/core/theme/theme_assets.dart';
import 'package:malssi/features/archive/domain/fruit.dart';
import 'package:malssi/features/archive/presentation/fruit_review_sheet.dart';
import 'package:malssi/features/archive/providers/archive_providers.dart';

/// 보관 탭. 1년 단위 잔디 그리드로 수확 현황을 보여준다.
/// 각 칸은 해당 날짜 열매의 테마 색상이며, 터치하면 상세 카드가 열린다.
/// 탭 진입 시마다 보관 목록을 다시 불러온다 (#62).
class ArchiveScreen extends StatefulWidget {
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
  State<ArchiveScreen> createState() => _ArchiveScreenState();
}

class _ArchiveScreenState extends State<ArchiveScreen> {
  @override
  void initState() {
    super.initState();
    // 진입 시 reload: 세션 중 수확된 열매를 바로 반영한다.
    // 빌드 중 notify 방지를 위해 첫 프레임 이후에 호출한다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ArchiveProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ArchiveProvider>();

    return Scaffold(
      // 하단 바는 셸(`AppShellView`)이 상주로 들고 있다 (#79).
      body: SafeArea(child: _buildBody(context, state)),
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
    final today = ArchiveScreen.debugToday ?? DateTime.now();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            // #65: 후기를 남긴 열매만 잔디로 심어진다.
            '최근 1년 · ${state.plantedFruits.length}개의 열매',
            style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          _GrassGrid(
            today: DateTime(today.year, today.month, today.day),
            fruitsByDateKey: state.plantedByDateKey,
            onTapFruit: (fruit) => _openDetail(context, fruit),
          ),
          if (state.plantedFruits.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                '말씨 탭에서 씨앗을 키우고 후기를 남기면 잔디가 심어져요',
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
        dateLabel: ArchiveScreen.formatDate(fruit.harvestedAt),
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        if (ThemeAssets.grassFitsAll(maxWidth)) {
          // 와이드: 53주 전체 맞춤, 스크롤 없음 (#72).
          final cell = ThemeAssets.grassFitCell(maxWidth);
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var week = 0; week < ThemeAssets.grassWeeks; week++)
                _weekColumn(context, week, cell),
            ],
          );
        }
        // 좁음: 기존 가로 스크롤 (최신 주가 우측).
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          reverse: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var week = 0; week < ThemeAssets.grassWeeks; week++)
                _weekColumn(
                    context, week, ThemeAssets.grassMinCell),
            ],
          ),
        );
      },
    );
  }

  /// [week]번째 주(월~일) 열 칸.
  Widget _weekColumn(BuildContext context, int week, double cell) {
    // 오늘이 포함된 주 월요일 기준, 52주 전 월요일부터 53개 주.
    final thisMonday =
        today.subtract(Duration(days: today.weekday - 1));
    final startMonday = thisMonday.subtract(const Duration(days: 7 * 52));
    final divider = Theme.of(context).dividerColor;

    return Padding(
      padding: EdgeInsets.only(
          right: week == ThemeAssets.grassWeeks - 1
              ? 0
              : ThemeAssets.grassGap),
      child: Column(
        children: [
          for (var day = 0; day < 7; day++)
            Padding(
              padding: EdgeInsets.only(
                  bottom:
                      day == 6 ? 0 : ThemeAssets.grassGap),
              child: _cell(
                context,
                startMonday.add(Duration(days: week * 7 + day)),
                divider,
                cell,
              ),
            ),
        ],
      ),
    );
  }

  Widget _cell(
      BuildContext context, DateTime date, Color divider, double cell) {
    if (date.isAfter(today)) {
      return SizedBox(width: cell, height: cell);
    }
    final fruit = fruitsByDateKey[ArchiveScreen.dateKeyOf(date)];
    if (fruit == null) {
      return Container(
        width: cell,
        height: cell,
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
        width: cell,
        height: cell,
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
