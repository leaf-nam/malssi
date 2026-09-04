import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:malssi/core/theme/app_theme.dart';
import 'package:malssi/core/theme/theme_assets.dart';
import 'package:malssi/core/widgets/bottom_nav.dart';
import 'package:malssi/features/archive/domain/fruit.dart';
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
                '씨앗 탭에서 오늘의 씨앗을 깨면 잔디가 채워져요',
                style: TextStyle(
                    fontSize: 12, color: colors.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }

  void _openDetail(BuildContext context, Fruit fruit) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<ArchiveProvider>(),
        child: _FruitDetailSheet(fruit: fruit),
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
          color: ThemeAssets.cellColor(fruit.theme),
          borderRadius: BorderRadius.circular(5),
        ),
      ),
    );
  }
}

/// 칸 터치 시 열리는 상세 카드: 열매 + 명언 + 후기 + 점수 + 작성 진입점.
class _FruitDetailSheet extends StatefulWidget {
  const _FruitDetailSheet({required this.fruit});

  final Fruit fruit;

  @override
  State<_FruitDetailSheet> createState() => _FruitDetailSheetState();
}

class _FruitDetailSheetState extends State<_FruitDetailSheet> {
  late final TextEditingController _memoController;
  late int _score;

  @override
  void initState() {
    super.initState();
    _memoController = TextEditingController(text: widget.fruit.memo);
    _score = widget.fruit.fidelityScore;
  }

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final fruit = widget.fruit;
    final imagePath = ThemeAssets.fruitImage(fruit.theme);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: imagePath.isEmpty
                  ? const Text('🌱', style: TextStyle(fontSize: 64))
                  : Image.asset(
                      imagePath,
                      width: 72,
                      height: 72,
                      errorBuilder: (_, __, ___) => const Text('🌱',
                          style: TextStyle(fontSize: 64)),
                    ),
            ),
            const SizedBox(height: 12),
            Text(
              ArchiveScreen.formatDate(fruit.harvestedAt),
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12, color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Text(
              '"${fruit.text}"',
              textAlign: TextAlign.center,
              style: AppTheme.quoteTextStyle(fontSize: 17)
                  .copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: 6),
            Text(
              '— ${fruit.author}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            const Text('오늘의 점수', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 1; i <= 5; i++)
                  IconButton(
                    key: ValueKey('score-$i'),
                    icon: Icon(
                      i <= _score ? Icons.star : Icons.star_border,
                      color: colors.primary,
                    ),
                    onPressed: () => setState(() => _score = i),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            const Text('오늘의 후기', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _memoController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: '명언에 얼마나 충실히 살았는지 적어보세요',
              ),
            ),
            const SizedBox(height: 16),
            Consumer<ArchiveProvider>(
              builder: (context, archive, __) => ElevatedButton(
                onPressed: () async {
                  await archive.updateReview(
                    fruitId: fruit.id,
                    memo: _memoController.text,
                    fidelityScore: _score,
                  );
                  if (context.mounted) Navigator.of(context).pop();
                },
                child: const Text('후기 저장하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
