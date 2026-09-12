import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:malssi/core/constants/seed_themes.dart';
import 'package:malssi/core/theme/app_theme.dart';
import 'package:malssi/core/theme/theme_assets.dart';
import 'package:malssi/features/onboarding/providers/onboarding_providers.dart';

/// 매 실행 짧게 보여주는 랜딩 화면 (#162).
/// 셸 밖에 두는 전체 화면 라우트 (`/landing`, 앱 시작점).
/// [displayDuration]이 지나거나 탭하면 이동한다.
/// 첫 실행(`autoShowOnFirstLaunch` + 미완료)에는 도움말(`/onboarding`)로,
/// 그 외에는 말씨 탭(`/`)으로 보낸다.
class LandingScreen extends StatefulWidget {
  const LandingScreen({
    super.key,
    this.onDone,
    this.displayDuration = const Duration(milliseconds: 1500),
  });

  /// 테스트 주입용. `null`이면 라우터로 이동한다.
  final VoidCallback? onDone;

  /// 자동 이동까지 대기 시간.
  final Duration displayDuration;

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
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
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                ThemeAssets.seedImage(SeedTheme.vitality),
                width: 96,
                height: 96,
                // 도트 씨앗은 보간 없이 또렷하게 (#160).
                filterQuality: FilterQuality.none,
                errorBuilder: (_, __, ___) =>
                    const Text('🌱', style: TextStyle(fontSize: 64)),
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
            ],
          ),
        ),
      ),
    );
  }
}
