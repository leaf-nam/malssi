import 'package:flutter/material.dart';
import 'package:malssi/core/constants/seed_themes.dart';
import 'package:malssi/core/theme/theme_assets.dart';

/// 자작 명언 작성 시트 (#129). 심기 전 1회 진입, 테마 직접 선택,
/// 심은 뒤에는 수정 불가(번들과 동일)다.
class CustomQuoteSheet extends StatefulWidget {
  const CustomQuoteSheet({
    super.key,
    required this.initialTheme,
    required this.onPlant,
  });

  /// 씨앗 테마 (테마 선택 초기값).
  final String initialTheme;
  final Future<void> Function({
    required String text,
    required String author,
    required String theme,
  }) onPlant;

  /// 번들 표시 상한과 같은 본문 길이 제한 (#180).
  static const maxTextLength = 82;

  @override
  State<CustomQuoteSheet> createState() => _CustomQuoteSheetState();
}

class _CustomQuoteSheetState extends State<CustomQuoteSheet> {
  late final TextEditingController _textController;
  late final TextEditingController _authorController;
  late String _theme;
  bool _planting = false;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _authorController = TextEditingController();
    _theme = SeedTheme.isValid(widget.initialTheme)
        ? widget.initialTheme
        : SeedTheme.growth;
  }

  @override
  void dispose() {
    _textController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  bool get _valid =>
      _textController.text.trim().isNotEmpty &&
      _textController.text.trim().length <=
          CustomQuoteSheet.maxTextLength &&
      _authorController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      // #234: 빈 공간 터치 시 키보드를 내린다.
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        behavior: HitTestBehavior.translucent,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                '직접 쓰기',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                '오늘의 명언을 직접 쓰고 심어보세요',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _textController,
                maxLines: 3,
                maxLength: CustomQuoteSheet.maxTextLength,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: '마음에 새길 한 줄을 적어보세요',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _authorController,
                maxLines: 1,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  hintText: '지은이 (예: 나)',
                ),
              ),
              const SizedBox(height: 16),
              const Text('테마 고르기', style: TextStyle(fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final theme in SeedTheme.values)
                    ChoiceChip(
                      key: ValueKey('theme-$theme'),
                      label: Text(ThemeAssets.labelOf(theme)),
                      selected: _theme == theme,
                      onSelected: (_) => setState(() => _theme = theme),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: (!_valid || _planting)
                    ? null
                    : () async {
                        setState(() => _planting = true);
                        try {
                          await widget.onPlant(
                            text: _textController.text.trim(),
                            author: _authorController.text.trim(),
                            theme: _theme,
                          );
                        } finally {
                          if (mounted) setState(() => _planting = false);
                        }
                        if (context.mounted) Navigator.of(context).pop();
                      },
                child: const Text('이 명언으로 심기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
