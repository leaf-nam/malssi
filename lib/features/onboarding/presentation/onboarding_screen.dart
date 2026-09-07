import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:malssi/features/onboarding/providers/onboarding_providers.dart';

/// 도움말 한 페이지를 표현하는 정적 데이터.
class OnboardingPageData {
  const OnboardingPageData({
    required this.icon,
    required this.title,
    required this.body,
    this.images = const [],
  });

  final IconData icon;
  final String title;
  final String body;

  /// 실제 앱 스크린샷(`assets/images/screenshots/`).
  /// 비어 있으면 아이콘만 보여준다.
  final List<String> images;
}

/// 탭별 순서와 일치하는 페이지 목록 (#130).
///
/// 문구는 실제 동작과 일치해야 한다: 말씨(심는 즉시 공개 #46,
/// 후기 마감 #113), 정원(후기 있는 열매만 #65, 읽기 전용 #48),
/// 설정(씨앗 시간·알림 #47, 열매 비 #108).
const List<OnboardingPageData> onboardingPages = [
  OnboardingPageData(
    icon: Icons.eco_outlined,
    title: '말씨에 오신 것을 환영해요',
    body: '말씨는 하루에 한 개의 씨앗을 키우며\n오늘의 명언을 만나는 앱입니다.\n각 탭의 사용법을 순서대로 알려드릴게요.',
  ),
  OnboardingPageData(
    icon: Icons.spa_outlined,
    title: '말씨 탭 — 씨앗을 심어보세요',
    body: '매일 아침 씨앗이 한 개 도착해요.\n씨앗을 한 번 탭하면 오늘의 명언이 바로 공개되고,\n2시간마다 한 단계씩 자라 5단계에서 열매가 맺혀요.\n완성된 열매를 탭해 별점과 한 줄 후기를 남겨보세요.\n다음 씨앗이 오기 전까지 후기를 남기지 않으면\n열매는 사라지니 잊지 마세요.',
    images: [
      'assets/images/screenshots/seed_locked.png',
      'assets/images/screenshots/seed_growing.png',
      'assets/images/screenshots/fruit_complete.png',
      'assets/images/screenshots/review_empty.png',
      'assets/images/screenshots/review_filled.png',
    ],
  ),
  OnboardingPageData(
    icon: Icons.grass_outlined,
    title: '정원 탭 — 모은 열매를 돌아보세요',
    body: '후기를 남긴 열매만 정원의 잔디에 심어져요.\n1년치 기록이 색깔 칸으로 보이고,\n칸을 터치하면 열매와 저장된 후기를 볼 수 있어요.\n정원에서는 후기를 새로 쓰거나 고칠 수 없어요.',
    images: [
      'assets/images/screenshots/archive_garden.png',
    ],
  ),
  OnboardingPageData(
    icon: Icons.settings_outlined,
    title: '설정 탭 — 내 리듬에 맞추세요',
    body: '씨앗이 도착하는 시간과 매일 알림을 정할 수 있어요.\n화면 모드(라이트·다크·시스템)와\n정원에 내리는 열매 비 효과도 바꿀 수 있고,\n이 도움말은 언제든 여기서 다시 볼 수 있어요.',
    images: [
      'assets/images/screenshots/settings.png',
      'assets/images/screenshots/settings_seed_time.png',
    ],
  ),
  OnboardingPageData(
    icon: Icons.local_florist_outlined,
    title: '오늘의 씨앗을 만나보세요',
    body: '준비가 끝났어요.\n시작하기를 누르면 오늘의 씨앗이 기다리고 있어요.\n매일 하나의 명언과 함께 자라보세요.',
  ),
];

/// 첫 실행 도움말 화면. 셸 밖에 두는 전체 화면 라우트 (`/onboarding`).
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.onFinished});

  /// 테스트 주입용. `null`이면 완료 후 `context.go('/')`로 이동한다.
  final VoidCallback? onFinished;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish(BuildContext context) async {
    await context.read<OnboardingProvider>().complete();
    if (!context.mounted) return;
    final onFinished = widget.onFinished;
    if (onFinished != null) {
      onFinished();
    } else {
      context.go('/');
    }
  }

  void _goTo(int page) {
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final last = _index == onboardingPages.length - 1;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          if (!last)
            TextButton(
              onPressed: () => _finish(context),
              child: const Text('건너뛰기'),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: onboardingPages.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (context, i) =>
                    _PageBody(data: onboardingPages[i]),
              ),
            ),
            _Dots(index: _index, count: onboardingPages.length),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    if (last) {
                      _finish(context);
                    } else {
                      _goTo(_index + 1);
                    }
                  },
                  child: Text(last ? '시작하기' : '다음'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageBody extends StatelessWidget {
  const _PageBody({required this.data});

  final OnboardingPageData data;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final hasImages = data.images.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (hasImages) ...[
            Flexible(child: _ScreenshotStrip(images: data.images)),
            const SizedBox(height: 20),
          ] else ...[
            Icon(data.icon, size: 72, color: colors.primary),
            const SizedBox(height: 24),
          ],
          // 좁은 화면(iPhone 390pt 등)에서도 제목이 두 줄로
          // 끊기지 않게 한 줄로 축소한다.
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              data.title,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            data.body,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.7,
                  color: colors.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

/// 온보딩용 앱 스크린샷 묶음. 폰 프레임 비율로 보여준다.
///
/// 1장이면 가운데에, 여러 장이면 가로로 넘겨 볼 수 있다.
/// 긴 문구와 함께 들어가도 넘치지 않게 남은 공간에만 펼쳐진다.
class _ScreenshotStrip extends StatelessWidget {
  const _ScreenshotStrip({required this.images});

  final List<String> images;

  @override
  Widget build(BuildContext context) {
    if (images.length == 1) {
      return Center(child: _PhoneFrame(path: images.single));
    }
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      itemCount: images.length,
      separatorBuilder: (_, __) => const SizedBox(width: 12),
      itemBuilder: (context, i) => _PhoneFrame(path: images[i]),
    );
  }
}

/// 둥근 테두리의 세로 폰 프레임. 스크린샷 비율(1170:2532)에 맞춘다.
class _PhoneFrame extends StatelessWidget {
  const _PhoneFrame({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 1170 / 2532,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Image.asset(
            path,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Icon(
              Icons.image_not_supported_outlined,
              size: 48,
              color: colors.outline,
            ),
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.index, required this.count});

  final int index;
  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (int i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == index ? 20 : 8,
            height: 8,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: i == index ? colors.primary : colors.surfaceContainerHighest,
            ),
          ),
      ],
    );
  }
}
