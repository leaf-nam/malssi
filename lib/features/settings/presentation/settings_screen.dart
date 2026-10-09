import 'package:app_settings/app_settings.dart' as sys_settings;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:malssi/core/services/debug_ui.dart';
import 'package:malssi/core/services/notification_service.dart';
import 'package:malssi/core/theme/app_theme.dart';
import 'package:malssi/features/settings/domain/app_settings.dart';
import 'package:malssi/features/settings/providers/settings_providers.dart';

/// 설정 탭. 씨앗 생성시간 + 매일 알림 on/off.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<SettingsProvider>();

    return Scaffold(
      // 하단 바는 셸(`AppShellView`)이 상주로 들고 있다 (#79).
      body: SafeArea(child: _buildBody(context, state)),
    );
  }

  Widget _buildBody(BuildContext context, SettingsProvider state) {
    if (state.isLoading && state.settings == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final settings = state.settings;
    if (settings == null) {
      return Center(
          child: Text(state.errorMessage ?? '설정을 불러올 수 없습니다.'));
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        _Row(
          label: '씨앗 생성 시간',
          trailing: '${settings.seedTime} ›',
          onTap: () => _pickSeedTime(context, state, settings),
        ),
        _Row(
          label: '매일 알림',
          trailingWidget: Switch(
            value: settings.notifyEnabled,
            onChanged: (value) => _toggleDaily(context, state, value),
          ),
        ),
        _Row(
          label: '성장 알림',
          trailingWidget: Switch(
            value: settings.growthNotifyEnabled,
            onChanged: state.setGrowthNotifyEnabled,
          ),
        ),
        _Row(
          label: '화면 모드',
          trailingWidget: SegmentedButton<String>(
            // #218: 라이트/다크에서 버튼 크기가 달라진다는 피드백.
            // 테마 기본값에 맡기면 모드별 텍스트 스타일로 크기가 흔들릴 수 있어
            // 크기 요소(textStyle·minimumSize·padding)를 명시적으로 고정한다
            // (색상은 각 모드 테마를 따른다).
            // #218 후속: 선택된 세그먼트에만 체크 아이콘이 붙어
            // 선택 변경 시 전체 너비가 흔들리므로(270→234 실측) 아이콘을 숨긴다.
            // 선택 상태는 배경색으로 구분된다.
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              textStyle: const TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              minimumSize: const Size(64, 36),
              padding: const EdgeInsets.symmetric(horizontal: 12),
            ),
            segments: const [
              ButtonSegment(value: 'light', label: Text('라이트')),
              ButtonSegment(value: 'dark', label: Text('다크')),
              ButtonSegment(value: 'system', label: Text('시스템')),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (selected) =>
                state.setThemeMode(selected.single),
          ),
        ),
        _Row(
          label: '열매 비 효과',
          trailingWidget: Switch(
            value: settings.fruitRainEnabled,
            onChanged: state.setFruitRainEnabled,
          ),
        ),
        // #253: 잠금 해제 시 먼저 보기 (Android full-screen intent, opt-in).
        // iOS는 잠금화면 위젯(#242)·Live Activity(#248)로 커버하므로 숨긴다.
        if (defaultTargetPlatform == TargetPlatform.android)
          _Row(
            label: '잠금화면에서 먼저 보기',
            trailingWidget: Switch(
              value: settings.lockscreenFirstEnabled,
              onChanged: state.setLockscreenFirstEnabled,
            ),
          ),
        _Row(
          label: '도움말 다시 보기',
          trailing: '›',
          onTap: () => context.go('/onboarding'),
        ),
        // 디버그 모드에서만 보이는 스크린샷용 스위치. 켜면 씨앗 탭의
        // 디버그 버튼들이 가려지고, 끄면 다시 수확 플로우를 검증할 수 있다.
        if (kDebugMode)
          _Row(
            label: '디버그 버튼 숨기기',
            trailingWidget: Switch(
              value: context.watch<DebugUiProvider>().hideButtons,
              onChanged: (value) =>
                  context.read<DebugUiProvider>().setHideButtons(value),
            ),
          ),
        // #244: 디버그용 알림 테스트 (10초 후 1회). inexact 모드라
        // 수분 지연될 수 있다. 릴리스 빌드에는 포함되지 않는다.
        if (kDebugMode)
          _Row(
            label: '알림 테스트',
            trailingWidget: TextButton(
              onPressed: () => NotificationService.instance
                  .scheduleSeedCompleteNotification(
                id: 9999,
                title: '테스트 알림이에요',
                body: '예약 알림이 정상 동작해요',
                completeAt:
                    DateTime.now().add(const Duration(seconds: 10)),
              ),
              child: const Text('10초 후 울리기'),
            ),
          ),
        if (state.errorMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Text(
              state.errorMessage!,
              style: const TextStyle(fontSize: 12, color: Colors.redAccent),
            ),
          ),
        const Padding(
          padding: EdgeInsets.only(top: 16),
          child: Text(
            '설정한 시간에 오늘의 씨앗이 도착하고 알림을 보내드려요',
            style: TextStyle(fontSize: 11.5, color: AppTheme.muted),
          ),
        ),
      ],
    );
  }

  /// 매일 알림 스위치. 켤 때 OS 권한을 확인하고 (#244 후속),
  /// 거부 상태면 OS 팝업이 다시 뜨지 않으므로 설정 유도를 보여준다.
  /// (처음 허용 여부를 묻는 팝업 자체는 `requestPermissions`가 띄운다.)
  Future<void> _toggleDaily(
      BuildContext context, SettingsProvider state, bool value) async {
    await state.setNotifyEnabled(value);
    if (!value || !context.mounted) return;
    final granted = await NotificationService.instance.requestPermissions();
    if (granted || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('알림이 거부되어 있어요. 설정에서 허용해주세요.'),
        action: SnackBarAction(
          label: '설정으로 이동',
          onPressed: () => sys_settings.AppSettings.openAppSettings(
            type: sys_settings.AppSettingsType.notification,
          ),
        ),
      ),
    );
  }

  Future<void> _pickSeedTime(BuildContext context, SettingsProvider state,
      AppSettings settings) async {
    final picked = await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay(hour: settings.seedHour, minute: settings.seedMinute),
    );
    if (picked == null || !context.mounted) return;
    final formatted =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    // #159: 마감 14시 이후는 저장 전에 막고 이유를 알린다.
    if (!AppSettings.isAllowedSeedTime(formatted)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('씨앗 생성 시간은 14시 이후로 설정할 수 없어요')),
      );
      return;
    }
    await state.updateSeedTime(formatted);
  }
}

class _Row extends StatelessWidget {
  const _Row(
      {required this.label, this.trailing, this.trailingWidget, this.onTap});

  final String label;
  final String? trailing;
  final Widget? trailingWidget;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border:
              Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(fontSize: 13, color: colors.onSurface)),
            trailingWidget ??
                Text(trailing ?? '',
                    style: TextStyle(
                        fontSize: 11.5, color: colors.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}
