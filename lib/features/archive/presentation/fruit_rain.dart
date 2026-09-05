import 'dart:math';

import 'package:flutter/material.dart';

/// 최다 색깔 열매 비 배경 (#89).
/// [imagePath]의 열매 이미지가 대각선으로 비처럼 내린다.
/// 개수는 [dropCount]로 상한한다 (저전력). 가독성을 위해 호출 측에서
/// 낮은 불투명도로 쓴다. 열매가 없으면 표시하지 않는다.
class FruitRain extends StatefulWidget {
  const FruitRain({
    super.key,
    required this.imagePath,
    required this.opacity,
  });

  final String imagePath;
  final double opacity;

  static const dropCount = 12;
  static const cycle = Duration(seconds: 14);

  /// 전체 낙하 대비 가로 이동 비율 (대각선 기울기).
  static const slant = 0.35;

  @override
  State<FruitRain> createState() => _FruitRainState();
}

class _Drop {
  _Drop({
    required this.x,
    required this.speed,
    required this.size,
    required this.phase,
  });

  /// 시작 가로 위치 (0~1).
  final double x;

  /// 낙하 속도 배율.
  final double speed;

  /// 이미지 크기.
  final double size;

  /// 위상 (0~1).
  final double phase;
}

class _FruitRainState extends State<FruitRain>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_Drop> _drops;

  @override
  void initState() {
    super.initState();
    final random = Random();
    _drops = List.generate(
      FruitRain.dropCount,
      (_) => _Drop(
        x: random.nextDouble(),
        speed: 0.7 + random.nextDouble() * 0.6,
        size: 22 + random.nextDouble() * 26,
        phase: random.nextDouble(),
      ),
    );
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
        return AnimatedBuilder(
          animation: _controller,
          builder: (_, __) {
            final t = _controller.value;
            return Stack(
              children: [
                for (var i = 0; i < _drops.length; i++)
                  _positionedDrop(_drops[i], i, t, width, height),
              ],
            );
          },
        );
      },
    );
  }

  Widget _positionedDrop(
      _Drop drop, int index, double t, double width, double height) {
    // 0~1 진행률. 화면 위에서 시작해 아래로 빠져나간다.
    final progress = (t * drop.speed + drop.phase) % 1.0;
    final top = -drop.size + progress * (height + drop.size * 2);
    final left = drop.x * width -
        progress * height * FruitRain.slant -
        drop.size / 2;

    return Positioned(
      key: ValueKey('rain-drop-$index'),
      left: left,
      top: top,
      child: Opacity(
        opacity: widget.opacity,
        child: Image.asset(
          widget.imagePath,
          width: drop.size,
          height: drop.size,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}
