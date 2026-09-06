import 'package:flutter/material.dart';

/// 명언 출처 보기 다이얼로그 (#123).
/// 명언이 표시되는 위치(말씨 탭·후기 카드)에서 출처 버튼으로 연다.
/// 출처가 비어 있으면 호출하지 않는다 (호출 측에서 버튼을 숨긴다).
Future<void> showQuoteSourceDialog(
    BuildContext context, String source) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('명언 출처', style: TextStyle(fontSize: 15)),
      content: Text(source, style: const TextStyle(fontSize: 13)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('닫기'),
        ),
      ],
    ),
  );
}

/// 작고 눈에 띄지 않는 출처 버튼 (#123).
/// 저자 줄 오른쪽 구석에 둔다. 탭하면 출처 다이얼로그를 연다.
class QuoteSourceButton extends StatelessWidget {
  const QuoteSourceButton({
    super.key,
    required this.source,
    this.color,
    this.fontSize = 10,
  });

  final String source;
  final Color? color;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        style: TextButton.styleFrom(
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        onPressed: () => showQuoteSourceDialog(context, source),
        child: Text(
          '출처',
          style: TextStyle(fontSize: fontSize, color: color),
        ),
      ),
    );
  }
}
