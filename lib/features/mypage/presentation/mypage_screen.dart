import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:malssi/core/theme/app_theme.dart';
import 'package:malssi/core/widgets/bottom_nav.dart';
import 'package:malssi/features/home/providers/home_providers.dart';
import 'package:malssi/features/mypage/providers/user_providers.dart';

class MyPageScreen extends StatelessWidget {
  const MyPageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userState = context.watch<UserProfileProvider>();
    final quoteState = context.watch<QuoteProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('마이페이지'),
        actions: const [Padding(
          padding: EdgeInsets.only(right: 16),
          child: Icon(Icons.settings_outlined, size: 20),
        )],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProfileHead(userState),
            _buildStats(quoteState),
            _buildMenus(context, userState),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: const MvpBottomNav(currentIndex: 4),
    );
  }

  Widget _buildProfileHead(UserProfileProvider userState) {
    final profile = userState.profile ?? {};
    if (userState.isLoading && profile.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppTheme.gold, AppTheme.goldDim],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${profile['displayName'] ?? '내 이름'} 님',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.paper,
                  )),
              const SizedBox(height: 2),
              Text(profile['email'] ?? '이메일 없음',
                  style: const TextStyle(fontSize: 11.5, color: AppTheme.muted)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStats(QuoteProvider quoteState) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      decoration: BoxDecoration(
        color: AppTheme.ink800,
        border: Border.all(color: AppTheme.line),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _Stat(value: '${quoteState.streakDays}', label: '연속 읽음'),
          _Stat(value: '${quoteState.likedQuoteIds.length}', label: '좋아요'),
          _Stat(value: '2', label: '등록한 명언'),
        ],
      ),
    );
  }

  Widget _buildMenus(BuildContext context, UserProfileProvider userState) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Column(
        children: [
          _MenuRow(
            label: '좋아요한 명언',
            trailing: '${userState.profile == null ? 0 : context.read<QuoteProvider>().likedQuoteIds.length}개 ›',
            onTap: () {},
          ),
          const _MenuRow(label: '내가 쓴 명언', trailing: '3개 ›'),
          const _MenuRow(label: '댓글 단 명언', trailing: '12개 ›'),
          _MenuRow(
            label: '하루 1회 알림',
            trailingWidget: Switch(
              value: userState.dailyNotification,
              activeThumbColor: AppTheme.gold,
              onChanged: userState.setDailyNotification,
            ),
          ),
          _MenuRow(
            label: '알림 시간 설정',
            trailing: '${userState.notificationTimeLabel} ›',
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: userState.notificationTime,
              );
              if (picked != null) {
                userState.setNotificationTime(picked);
              }
            },
          ),
          const _MenuRow(label: '공지 · 문의', trailing: '›'),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          border: Border(right: BorderSide(color: AppTheme.line)),
        ),
        child: Column(
          children: [
            Text(value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.paper,
                )),
            const SizedBox(height: 3),
            Text(label,
                style: const TextStyle(fontSize: 10.5, color: AppTheme.muted)),
          ],
        ),
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({required this.label, this.trailing, this.trailingWidget, this.onTap});

  final String label;
  final String? trailing;
  final Widget? trailingWidget;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppTheme.line)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(fontSize: 13, color: AppTheme.paper)),
            trailingWidget ??
                Text(trailing ?? '',
                    style: const TextStyle(fontSize: 11.5, color: AppTheme.muted)),
          ],
        ),
      ),
    );
  }
}
