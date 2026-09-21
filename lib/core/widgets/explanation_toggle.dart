import 'package:flutter/material.dart';
import 'package:malssi/core/widgets/word_wrap.dart';

/// 명언 해설 접기/펼치기 (#216 후속).
/// 해설은 무조건 보여주지 않고 `해설 보기` 버튼을 눌러야 보인다.
class ExplanationToggle extends StatefulWidget {
  const ExplanationToggle({
    super.key,
    required this.explanation,
    this.textStyle,
    this.buttonColor,
    this.textAlign = TextAlign.center,
  });

  final String explanation;
  final TextStyle? textStyle;
  final Color? buttonColor;
  final TextAlign textAlign;

  @override
  State<ExplanationToggle> createState() => _ExplanationToggleState();
}

class _ExplanationToggleState extends State<ExplanationToggle> {
  var _shown = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextButton(
          onPressed: () => setState(() => _shown = !_shown),
          child: Text(
            _shown ? '해설 닫기' : '해설 보기',
            style: TextStyle(fontSize: 12, color: widget.buttonColor),
          ),
        ),
        if (_shown)
          Text(
            // #177: 단어 중간 줄바꿈 방지 (원문은 저장소에서 그대로 둔다).
            keepWordsTogether(widget.explanation),
            textAlign: widget.textAlign,
            style: widget.textStyle,
          ),
      ],
    );
  }
}
