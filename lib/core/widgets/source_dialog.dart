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
