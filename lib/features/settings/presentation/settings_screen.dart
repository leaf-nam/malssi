import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
            onChanged: state.setNotifyEnabled,
          ),
        ),
        _Row(
          label: '화면 모드',
          trailingWidget: SegmentedButton<String>(
            style: SegmentedButton.styleFrom(
              visualDensity: VisualDensity.compact,
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
