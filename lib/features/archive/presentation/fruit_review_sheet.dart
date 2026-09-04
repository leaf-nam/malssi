import 'package:flutter/material.dart';
import 'package:malssi/core/theme/app_theme.dart';

/// 열매 리뷰 카드 (별점 + 한줄 후기).
/// 메인(완성 열매 탭)에서는 작성용으로, 보관(잔디 상세)에서는 읽기 전용으로 쓴다.
/// 저장은 호출 측이 [onSave]로 주입한다 (작성 모드에서 필수).
/// 보관에서는 이미 저장된 후기만 보여주고 새로 쓸 수 없다 (#48).
class FruitReviewSheet extends StatefulWidget {
  const FruitReviewSheet({
    super.key,
    required this.quoteText,
    required this.author,
    required this.dateLabel,
    required this.imagePath,
    required this.initialMemo,
    required this.initialScore,
    this.readOnly = false,
    this.onSave,
  }) : assert(readOnly || onSave != null,
            '작성 모드에서는 onSave가 필요합니다.');

  final String quoteText;
  final String author;
  final String dateLabel;
  final String imagePath;
  final String initialMemo;
  final int initialScore;

  /// `true`면 별점·후기를 표시만 하고 입력 UI를 숨긴다.
  final bool readOnly;
  final Future<void> Function(
      {required String memo, required int fidelityScore})? onSave;

  @override
  State<FruitReviewSheet> createState() => _FruitReviewSheetState();
}

class _FruitReviewSheetState extends State<FruitReviewSheet> {
  late final TextEditingController _memoController;
  late int _score;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _memoController = TextEditingController(text: widget.initialMemo);
    _score = widget.initialScore;
  }

  @override
  void dispose() {
    _memoController.dispose();
    super.dispose();
  }

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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: widget.imagePath.isEmpty
                  ? const Text('🌱', style: TextStyle(fontSize: 64))
                  : Image.asset(
                      widget.imagePath,
                      width: 72,
                      height: 72,
                      errorBuilder: (_, __, ___) => const Text('🌱',
                          style: TextStyle(fontSize: 64)),
                    ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.dateLabel,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12, color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Text(
              '"${widget.quoteText}"',
              textAlign: TextAlign.center,
              style: AppTheme.quoteTextStyle(fontSize: 17)
                  .copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: 6),
            Text(
              '— ${widget.author}',
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
            if (widget.readOnly)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 1; i <= 5; i++)
                    Icon(
                      i <= _score ? Icons.star : Icons.star_border,
                      color: colors.primary,
                    ),
                ],
              )
            else
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
                      onPressed: _saving
                          ? null
                          : () => setState(() => _score = i),
                    ),
                ],
              ),
            const SizedBox(height: 8),
            const Text('오늘의 후기', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 8),
            if (widget.readOnly)
              Text(
                _memoController.text.isEmpty
                    ? '작성된 후기가 없어요'
                    : _memoController.text,
                style: TextStyle(
                  fontSize: 13,
                  color: _memoController.text.isEmpty
                      ? colors.onSurfaceVariant
                      : colors.onSurface,
                ),
              )
            else ...[
              TextField(
                controller: _memoController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: '명언에 얼마나 충실히 살았는지 적어보세요',
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saving
                    ? null
                    : () async {
                        setState(() => _saving = true);
                        try {
                          await widget.onSave!(
                            memo: _memoController.text,
                            fidelityScore: _score,
                          );
                        } finally {
                          if (mounted) setState(() => _saving = false);
                        }
                        if (context.mounted) Navigator.of(context).pop();
                      },
                child: const Text('후기 저장하기'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
