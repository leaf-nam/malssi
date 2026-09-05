import 'dart:math';

import 'package:flutter/material.dart';

/// 최다 색깔 열매 비 배경 (#89).
/// [imagePath]의 열매 이미지가 대각선으로 비처럼 내린다.
/// 3×4 격자에 1개씩 배치하고 모두 같은 속도로 움직여 겹치지 않는다 (#100).
/// 개수는 12개로 상한한다 (저전력). 가독성을 위해 호출 측에서
/// 낮은 불투명도로 쓴다. 열매가 없으면 표시하지 않는다.
class FruitRain extends StatefulWidget {
  const FruitRain({
    super.key,
    required this.imagePath,
    required this.opacity,
  });

  final String imagePath;
  final double opacity;

  static const cols = 3;
  static const rows = 4;
  static int get dropCount => cols * rows;
  static const cycle = Duration(seconds: 14);

  /// 전체 낙하 대비 가로 이동 비율 (대각선 기울기).
  static const slant = 0.35;

  /// 방울 크기 범위 (#102).
  static const minSize = 32.0;
  static const maxSize = 64.0;

  /// 이웃 간 최소 여유.
  static const margin = 8.0;

  /// 격자 배치 계산 (순수 함수, 테스트 가능, #100).
  /// 셀당 1개씩, 이웃 중심 간격이 최소 `maxSize + margin` 이상이다.
  /// 위상은 고르게 분산해 어느 순간에도 전 높이에 퍼져 있다 (#103).
  static List<RainDropSpec> layoutDrops({
    required double width,
    required double height,
    Random? random,
  }) {
    final rand = random ?? Random();
    final cellW = width / cols;
    final cellH = height / rows;
    final jitterX =
        max(0.0, (cellW - maxSize - margin) / 2);
    final jitterY =
        max(0.0, (cellH - maxSize - margin) / 2);
    final specs = <RainDropSpec>[];
    var index = 0;
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++, index++) {
        final cx = (col + 0.5) * cellW +
            (rand.nextDouble() * 2 - 1) * jitterX;
        final cy = (row + 0.5) * cellH +
            (rand.nextDouble() * 2 - 1) * jitterY;
        specs.add(RainDropSpec(
          center: Offset(cx, cy),
          size: minSize + rand.nextDouble() * (maxSize - minSize),
          phase: index / dropCount,
        ));
      }
    }
    return specs;
  }

  @override
  State<FruitRain> createState() => _FruitRainState();
}

/// 방울 배치 스펙. 중심·크기·위상.
class RainDropSpec {
  const RainDropSpec({
    required this.center,
    required this.size,
    required this.phase,
  });

  final Offset center;
  final double size;
  final double phase;
}

class _FruitRainState extends State<FruitRain>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Size? _specSize;
  List<RainDropSpec>? _specs;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: FruitRain.cycle,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// 크기별 배치. 크기가 바뀔 때만 다시 계산한다.
  List<RainDropSpec> _specsFor(Size size) {
    if (_specs == null || _specSize != size) {
      _specSize = size;
      _specs = FruitRain.layoutDrops(
        width: size.width,
        height: size.height,
      );
    }
    return _specs!;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        if (width <= 0 ||
            height <= 0 ||
            widget.imagePath.isEmpty) {
          return const SizedBox.shrink();
        }
        final specs = _specsFor(Size(width, height));
        return AnimatedBuilder(
          animation: _controller,
          builder: (_, __) {
            final t = _controller.value;
            return Stack(
              children: [
                for (var i = 0; i < specs.length; i++)
                  _positionedDrop(specs[i], i, t, width, height),
              ],
            );
          },
        );
      },
    );
  }

  Widget _positionedDrop(
      RainDropSpec spec, int index, double t, double width, double height) {
    // 모두 같은 속도로 움직여 상대 위치가 유지된다 (#100).
    // 0~1 진행률. 화면 위에서 시작해 아래로 빠져나간다.
    final progress = (t + spec.phase) % 1.0;
    final top =
        -spec.size + progress * (height + spec.size * 2);
    // 가로 이동은 순환시킨다. 순환 경계(p=0/1)에서는 방울이 화면 밖에 있어
    // 보이지 않으므로 끊김이 보이지 않는다 (#94).
    final spanX = width + spec.size;
    final left = (spec.center.dx -
                progress * (height * FruitRain.slant + spec.size)) %
            spanX -
        spec.size;

    return Positioned(
      key: ValueKey('rain-drop-$index'),
      left: left,
      top: top,
      // 방울별 리페인트 격리로 끊김을 줄인다.
      child: RepaintBoundary(
        child: Opacity(
          opacity: widget.opacity,
          child: Image.asset(
            widget.imagePath,
            width: spec.size,
            height: spec.size,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}
