import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:malssi/core/services/debug_clock.dart';
import 'package:malssi/core/theme/theme_assets.dart';
import 'package:malssi/features/archive/domain/fruit.dart';
import 'package:malssi/features/archive/presentation/fruit_rain.dart';
import 'package:malssi/features/archive/presentation/fruit_review_sheet.dart';
import 'package:malssi/features/archive/providers/archive_providers.dart';
import 'package:malssi/features/settings/providers/settings_providers.dart';

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

  /// 선택 연도. null이면 올해 (#99).
  int? _selectedYear;

  /// 오늘 중앙 이동 요청 횟수. 바뀔 때마다 그리드가 오늘로 이동한다 (#126).
  int _centerTick = 0;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<ArchiveProvider>();
    // #108: 설정에서 끄면 비를 내리지 않는다 (로딩 전 기본값 on).
    final rainEnabled =
        context.watch<SettingsProvider>().settings?.fruitRainEnabled ??
            true;

    return Scaffold(
      // 하단 바는 셸(`AppShellView`)이 상주로 들고 있다 (#79).
      // #89: 최다 색깔 열매 비를 배경에 깔고 본문을 올린다.
      // #107: Stack이 본문 높이에 맞춰 shrink되므로 비 영역을 화면 크기로 명시한다.
      body: Stack(
        children: [
          if (state.topTheme.isNotEmpty && rainEnabled)
            SizedBox.fromSize(
              size: MediaQuery.sizeOf(context),
              child: FruitRain(
                imagePath: ThemeAssets.fruitImage(state.topTheme),
                // #101: 비가 내용을 가리지 않게 낮게 유지한다.
                opacity:
                    Theme.of(context).brightness == Brightness.light
                        ? 0.14
                        : 0.20,
              ),
            ),
          SafeArea(child: _buildBody(context, state)),
        ],
      ),
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
    // #115: 정원 오늘이 디버그 시간 이동을 따라간다 (테스트 고정 우선).
    final today = ArchiveScreen.debugToday ?? DebugClock.now();
    final viewYear = _selectedYear ?? today.year;
    final firstYear = state.firstPlantedYear;
    final yearCount = state.plantedInYear(viewYear).length;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                // #65: 후기를 남긴 열매만 잔디로 심어진다.
                // #97: 선택 연도 기준 개수.
                '$viewYear · $yearCount개의 열매',
                style:
                    TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
              ),
              // #99: 처음 심어진 년도까지 돌아갈 수 있다.
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    key: const ValueKey('year-prev'),
                    icon: const Icon(Icons.chevron_left),
                    visualDensity: VisualDensity.compact,
                    onPressed: firstYear != null && viewYear > firstYear
                        ? () => setState(
                            () => _selectedYear = viewYear - 1)
                        : null,
                  ),
                  IconButton(
                    key: const ValueKey('year-next'),
                    icon: const Icon(Icons.chevron_right),
                    visualDensity: VisualDensity.compact,
                    onPressed: viewYear < today.year
                        ? () => setState(
                            () => _selectedYear = viewYear + 1)
                        : null,
                  ),
                  // #126: 오늘로 이동. 올해 보기에서도 중앙으로 이동한다.
                  IconButton(
                    key: const ValueKey('today-button'),
                    tooltip: '오늘로 이동',
                    icon: const Icon(Icons.today),
                    visualDensity: VisualDensity.compact,
                    onPressed: () => setState(() {
                      _selectedYear = null;
                      _centerTick++;
                    }),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _GrassGrid(
            today: DateTime(today.year, today.month, today.day),
            year: viewYear,
            fruitsByDateKey: state.plantedByDateKey,
            centerTick: _centerTick,
            onTapFruit: (fruit) => _openDetail(context, fruit),
          ),
          // 오늘 수확이 없으면 씨앗 성장 중 안내를 보여준다.
          // 열매 자체가 하나도 없을 때(#151)는 물론, 과거 열매만 있고
          // 오늘 열매가 아직 맺히지 않았을 때도 해당한다 (#174).
          // 오늘 수확은 됐는데 후기 전이면 후기 안내를 보여준다 (#84).
          if (!state.fruitsByDateKey
              .containsKey(ArchiveScreen.dateKeyOf(today)))
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                '오늘의 씨앗이 자라는 중이에요',
                style: TextStyle(
                    fontSize: 12, color: colors.onSurfaceVariant),
              ),
            )
          else if (state.plantedFruits.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                '완성된 열매에 후기를 남기면 잔디가 심어져요',
                style: TextStyle(
                    fontSize: 12, color: colors.onSurfaceVariant),
              ),
            ),
          if (state.plantedFruits.isNotEmpty) ...[
            const SizedBox(height: 20),
            _ThemeStats(counts: state.themeCounts),
          ],
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
        // #123: 날짜별 명언 조회에서도 출처를 볼 수 있다.
        source: fruit.source,
      ),
    );
  }
}

/// 모은 색깔·색깔별 개수 통계 (#88). 심어진(후기 완료) 기준, 보유 테마만 내림차순.
class _ThemeStats extends StatelessWidget {
  const _ThemeStats({required this.counts});

  final Map<String, int> counts;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final divider = Theme.of(context).dividerColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '모은 색깔',
          style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in counts.entries)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: divider),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: ThemeAssets.cellColor(
                            entry.key, brightness),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${ThemeAssets.labelOf(entry.key)} ${entry.value}개',
                      style: TextStyle(
                          fontSize: 12, color: colors.onSurface),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// GitHub 잔디 스타일 그리드. 열 = 주, 행 = 월~일.
/// [year]년 범위(1월 1일이 속한 주~다음 해 시작 주)를 보여준다 (#97, #99).
/// 좁으면 가로 스크롤(항상 보이는 스크롤바, #86),
/// 넓으면 전체 맞춤으로 스크롤 없이 보여준다 (#72).
class _GrassGrid extends StatefulWidget {
  const _GrassGrid({
    required this.today,
    required this.year,
    required this.fruitsByDateKey,
    required this.centerTick,
    required this.onTapFruit,
  });

  final DateTime today;

  /// 표시 연도.
  final int year;
  final Map<String, Fruit> fruitsByDateKey;

  /// 오늘 중앙 이동 요청 횟수. 바뀔 때마다 오늘로 이동한다 (#126).
  final int centerTick;
  final ValueChanged<Fruit> onTapFruit;

  @override
  State<_GrassGrid> createState() => _GrassGridState();
}

class _GrassGridState extends State<_GrassGrid> {
  final _scrollController = ScrollController();

  /// 반영済 중앙 이동 요청. 첫 진입 1회 이동과 오늘로 이동에 함께 쓴다.
  int _appliedTick = -1;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// 표시 연도 범위의 시작 월요일과 주 수.
  DateTime get _rangeStart => ThemeAssets.grassYearStart(widget.year);
  int get _columnCount => ThemeAssets.grassYearWeeks(widget.year);

  /// 오늘 칸이 화면 가운데 오도록 초기 스크롤을 이동한다 (#98).
  /// 스크롤 모드 + 당해 연도에서 첫 진입 1회만 호출한다.
  /// `reverse: true`라 뒤집어서 이동한다.
  void _centerOnToday(double viewportWidth, double cell) {
    if (!mounted || !_scrollController.hasClients) return;
    final weekIdx =
        widget.today.difference(_rangeStart).inDays ~/ 7;
    final unit = cell + ThemeAssets.grassGap;
    final weekCenter = weekIdx * unit + cell / 2;
    final maxExtent = _scrollController.position.maxScrollExtent;
    final target =
        (maxExtent - (weekCenter - viewportWidth / 2)).clamp(0.0, maxExtent);
    _scrollController.jumpTo(target);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final totalWeeks = _columnCount;
        if (ThemeAssets.grassFitsAll(maxWidth, weeks: totalWeeks)) {
          // 와이드: 전체 맞춤, 스크롤 없음 (#72).
          final cell =
              ThemeAssets.grassFitCell(maxWidth, weeks: totalWeeks);
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var week = 0; week < totalWeeks; week++)
                _weekColumn(
                    context, week, cell, totalWeeks),
            ],
          );
        }
        // 좁음: 가로 스크롤 (최신 주가 우측, 항상 보이는 스크롤바).
        // 칸을 뷰포트에 맞춰 정지 시 가장자리에 반칸이 없게 한다 (#83).
        // 스크롤바가 칸과 겹치지 않게 아래 간격을 둔다 (#91).
        // 첫 진입(#98)과 오늘로 이동(#126)에는 오늘이 가운데 오도록 이동한다
        // (당해 연도만).
        final scrollCell = ThemeAssets.grassScrollCell(maxWidth);
        if (widget.centerTick != _appliedTick &&
            widget.year == widget.today.year) {
          _appliedTick = widget.centerTick;
          WidgetsBinding.instance.addPostFrameCallback(
              (_) => _centerOnToday(maxWidth, scrollCell));
        }
        return Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            reverse: true,
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var week = 0; week < totalWeeks; week++)
                  _weekColumn(context, week, scrollCell, totalWeeks),
              ],
            ),
          ),
        );
      },
    );
  }

  /// [week]번째 주(월~일) 열 칸. [totalWeeks]는 마지막 주 패딩 판단용.
  Widget _weekColumn(
      BuildContext context, int week, double cell, int totalWeeks) {
    final startMonday = _rangeStart;
    final divider = Theme.of(context).dividerColor;

    return Padding(
      padding: EdgeInsets.only(
          right: week == totalWeeks - 1 ? 0 : ThemeAssets.grassGap),
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
    final todayKey = ArchiveScreen.dateKeyOf(widget.today);
    final isToday = ArchiveScreen.dateKeyOf(date) == todayKey;
    // #125: 오늘 테두리는 테마색과 무관한 전용 청록색이다.
    final outline =
        ThemeAssets.todayOutline(Theme.of(context).brightness);
    // 연도 밖 가장자리는 빈 공간으로 둔다.
    if (date.year != widget.year) {
      return SizedBox(width: cell, height: cell);
    }
    // 미래 날짜는 빈칸으로 보여주되 탭은 불가하다 (#97).
    if (date.isAfter(widget.today)) {
      return Container(
        width: cell,
        height: cell,
        decoration: BoxDecoration(
          border: Border.all(color: divider),
          borderRadius: BorderRadius.circular(5),
        ),
      );
    }
    final fruit = widget.fruitsByDateKey[ArchiveScreen.dateKeyOf(date)];
    if (fruit == null) {
      return Container(
        width: cell,
        height: cell,
        decoration: BoxDecoration(
          border: Border.all(
              color: isToday ? outline : divider,
              width: isToday ? 2 : 1),
          borderRadius: BorderRadius.circular(5),
        ),
      );
    }
    return GestureDetector(
      key: ValueKey('grass-${fruit.harvestDateKey}'),
      onTap: () => widget.onTapFruit(fruit),
      child: Container(
        width: cell,
        height: cell,
        decoration: BoxDecoration(
          // #56: 라이트 테마에서는 밝은 열매색, 다크에서는 다크톤.
          color: ThemeAssets.cellColor(
              fruit.theme, Theme.of(context).brightness),
          border: isToday
              ? Border.all(color: outline, width: 2)
              : null,
          borderRadius: BorderRadius.circular(5),
        ),
      ),
    );
  }
}
