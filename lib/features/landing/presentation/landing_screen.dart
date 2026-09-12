import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:malssi/core/constants/seed_themes.dart';
import 'package:malssi/core/theme/app_theme.dart';
import 'package:malssi/core/theme/theme_assets.dart';
import 'package:malssi/features/archive/presentation/fruit_rain.dart';
import 'package:malssi/features/onboarding/providers/onboarding_providers.dart';

/// 매 실행 짧게 보여주는 랜딩 화면 (#162).
/// 셸 밖에 두는 전체 화면 라우트 (`/landing`, 앱 시작점).
/// 배경에 랜덤 열매 비 + 전방에 랜덤 열매 + 앱 팁 1건을 보여준다.
/// [displayDuration]이 지나거나 탭하면 이동한다.
/// 첫 실행(`autoShowOnFirstLaunch` + 미완료)에는 도움말(`/onboarding`)로,
/// 그 외에는 말씨 탭(`/`)으로 보낸다.
class LandingScreen extends StatefulWidget {
  const LandingScreen({
    super.key,
    this.onDone,
    this.displayDuration = const Duration(milliseconds: 1500),
    this.random,
    this.fruitTheme,
    this.tip,
  });

  /// 테스트 주입용. `null`이면 라우터로 이동한다.
  final VoidCallback? onDone;

  /// 자동 이동까지 대기 시간.
  final Duration displayDuration;

  /// 테스트 주입용 랜덤·테마·팁. `null`이면 실행마다 랜덤 선택한다.
  final Random? random;
  final String? fruitTheme;
  final String? tip;

  /// 실행마다 1개씩 보여주는 앱 팁.
  static const tips = [
    '씨앗은 2시까지만 받을 수 있어요!',
    '심자마자 오늘의 명언이 공개돼요',
    '완성 열매에 후기를 남기면 정원에 심어져요',
    '매일 하나의 씨앗이 도착해요',
    '열매를 눌러 오늘의 리뷰를 남겨보세요',
  ];

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  Timer? _timer;
  late final String _fruitTheme;
  late final String _tip;

  @override
  void initState() {
    super.initState();
    final random = widget.random ?? Random();
    final themes = SeedTheme.values;
    _fruitTheme =
        widget.fruitTheme ?? themes[random.nextInt(themes.length)];
    _tip = widget.tip ??
        LandingScreen.tips[random.nextInt(LandingScreen.tips.length)];
    _timer = Timer(widget.displayDuration, _done);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _done() async {
    _timer?.cancel();
    if (!mounted) return;
    final onDone = widget.onDone;
    if (onDone != null) {
      onDone();
      return;
    }
    final onboarding = context.read<OnboardingProvider>();
    if (onboarding.completed == null) {
      await onboarding.load();
    }
    if (!mounted) return;
    if (onboarding.autoShowOnFirstLaunch && onboarding.completed != true) {
      context.go('/onboarding');
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    // 말씨 탭과 같은 다크 톤으로 시작한다 (#59).
    return Scaffold(
      backgroundColor: AppTheme.abyss,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _done,
        // #89 패턴: 열매 비를 배경에 깔고 본문을 올린다.
        // 다크라 0.20 불투명도로 쓴다.
        child: Stack(
          children: [
            SizedBox.fromSize(
              size: MediaQuery.sizeOf(context),
              child: FruitRain(
                imagePath: ThemeAssets.fruitImage(_fruitTheme),
                opacity: 0.20,
              ),
            ),
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      ThemeAssets.fruitImage(_fruitTheme),
                      // #160: 150px 소스의 정수배(0.5x = 75)로 표시.
                      width: 75,
                      height: 75,
                      // 도트 열매는 보간 없이 또렷하게 (#160).
                      filterQuality: FilterQuality.none,
                      errorBuilder: (_, __, ___) => const Text('🌱',
                          style: TextStyle(fontSize: 64)),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      '말씨',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.paper,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '오늘의 명언을 심어보세요',
                      style: TextStyle(fontSize: 13, color: AppTheme.muted),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '💡 $_tip',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 12, color: AppTheme.gold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
