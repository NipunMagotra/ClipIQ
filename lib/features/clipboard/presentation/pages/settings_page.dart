import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/device_id_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/auth_notifier.dart';
import '../../application/clipboard_sync_service.dart';

/// Flat settings page for ClipQ v2.
///
/// Removes grouped cards, uses section headers with trailing hairline dividers,
/// custom built tiny toggles, inline borderless editing, and zero icons.
class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  final _nameController = TextEditingController();
  String _deviceId = '';

  @override
  void initState() {
    super.initState();
    _loadDeviceInfo();
  }

  Future<void> _loadDeviceInfo() async {
    final id = await DeviceIdService.getDeviceId();
    final name = await DeviceIdService.getDeviceName();
    if (mounted) {
      setState(() {
        _deviceId = id;
        _nameController.text = name;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final syncState = ref.watch(clipboardSyncServiceProvider).valueOrNull;
    final isPaused = syncState?.status == SyncStatus.paused;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              children: [
                _sectionHeader('DEVICE'),
                _buildDeviceNameRow(),
                const Divider(height: 1, thickness: 0.5, color: AppTheme.border),
                _buildDeviceIdRow(),
                const Divider(height: 1, thickness: 0.5, color: AppTheme.border),

                _sectionHeader('SYNC'),
                _buildSyncRow(isPaused),
                const Divider(height: 1, thickness: 0.5, color: AppTheme.border),

                _sectionHeader('SHORTCUT'),
                _buildShortcutRow(),
                const Divider(height: 1, thickness: 0.5, color: AppTheme.border),

                _sectionHeader('ACCOUNT'),
                _buildSignOutRow(),
                const Divider(height: 1, thickness: 0.5, color: AppTheme.border),

                const SizedBox(height: 48),
                _buildAboutSection(),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppTheme.background,
        border: Border(
          bottom: BorderSide(color: AppTheme.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            behavior: HitTestBehavior.opaque,
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: Text(
                '← Settings',
                style: AppTheme.uiLabel.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section Header ──────────────────────────────────────────────────────────

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Row(
        children: [
          Text(
            title,
            style: AppTheme.uiLabel.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMuted,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Divider(
              color: AppTheme.border,
              thickness: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Device Name Row ─────────────────────────────────────────────────────────

  Widget _buildDeviceNameRow() {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          Text(
            'Device Name',
            style: AppTheme.uiBody.copyWith(color: AppTheme.textPrimary),
          ),
          const Spacer(),
          SizedBox(
            width: 180,
            child: TextField(
              controller: _nameController,
              textAlign: TextAlign.end,
              style: AppTheme.uiBody.copyWith(color: AppTheme.textSecondary),
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              cursorColor: AppTheme.accent,
              onSubmitted: (v) => DeviceIdService.setDeviceName(v.trim()),
            ),
          ),
        ],
      ),
    );
  }

  // ── Device ID Row ───────────────────────────────────────────────────────────

  Widget _buildDeviceIdRow() {
    final displayId = _deviceId.isEmpty
        ? '…'
        : _deviceId.substring(0, _deviceId.length.clamp(0, 8)) + '...';

    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: _deviceId));
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Device ID copied to clipboard')),
        );
      },
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            Text(
              'Device ID',
              style: AppTheme.uiBody.copyWith(color: AppTheme.textPrimary),
            ),
            const Spacer(),
            Text(
              displayId,
              style: AppTheme.contentMono.copyWith(
                color: AppTheme.textMuted,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Sync Row ────────────────────────────────────────────────────────────────

  Widget _buildSyncRow(bool isPaused) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          Text(
            'Clipboard Sync',
            style: AppTheme.uiBody.copyWith(color: AppTheme.textPrimary),
          ),
          const Spacer(),
          CustomToggle(
            value: !isPaused,
            onChanged: (_) =>
                ref.read(clipboardSyncServiceProvider.notifier).togglePause(),
          ),
        ],
      ),
    );
  }

  // ── Shortcut Row ────────────────────────────────────────────────────────────

  Widget _buildShortcutRow() {
    final isMac = !kIsWeb && Platform.isMacOS;
    final keys = isMac
        ? ['⌥', '⌘', 'V']
        : ['Alt', 'Ctrl', 'V'];

    return SizedBox(
      height: 44,
      child: Row(
        children: [
          Text(
            'Toggle Window',
            style: AppTheme.uiBody.copyWith(color: AppTheme.textPrimary),
          ),
          const Spacer(),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < keys.length; i++) ...[
                if (i > 0)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text('+', style: AppTheme.uiLabel.copyWith(color: AppTheme.textMuted, fontSize: 10)),
                  ),
                _KbdPill(label: keys[i]),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ── Sign Out Row ────────────────────────────────────────────────────────────

  Widget _buildSignOutRow() {
    return InkWell(
      onTap: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Sign Out?', style: AppTheme.uiStrong),
            content: Text(
              'Your clipboard history will remain stored in the cloud.',
              style: AppTheme.uiBody.copyWith(color: AppTheme.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text('Sign Out', style: TextStyle(color: AppTheme.error)),
              ),
            ],
          ),
        );
        if (confirmed == true && mounted) {
          await ref.read(authNotifierProvider.notifier).signOut();
        }
      },
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            Text(
              'Sign Out',
              style: AppTheme.uiBody.copyWith(color: AppTheme.error, fontWeight: FontWeight.w500),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }

  // ── About Section ───────────────────────────────────────────────────────────

  Widget _buildAboutSection() {
    return Column(
      children: [
        Text(
          'ClipQ v2.0.0',
          style: AppTheme.uiLabel.copyWith(color: AppTheme.textMuted, fontSize: 11),
        ),
        const SizedBox(height: 2),
        Text(
          'Universal Clipboard Sync',
          style: AppTheme.uiLabel.copyWith(color: AppTheme.textMuted.withOpacity(0.5), fontSize: 10),
        ),
      ],
    );
  }
}

// ── Custom Toggle Switch ──────────────────────────────────────────────────────

class CustomToggle extends StatelessWidget {
  const CustomToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Container(
          width: 32,
          height: 18,
          padding: const EdgeInsets.all(2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            color: value ? AppTheme.success.withOpacity(0.15) : AppTheme.border,
            border: Border.all(
              color: value ? AppTheme.success.withOpacity(0.3) : AppTheme.borderStrong,
              width: 0.5,
            ),
          ),
          child: AnimatedAlign(
            duration: AppConstants.animQuick,
            curve: Curves.easeOut,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: value ? AppTheme.success : AppTheme.textMuted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Keyboard Pill ────────────────────────────────────────────────────────────

class _KbdPill extends StatelessWidget {
  const _KbdPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppTheme.border, width: 0.5),
      ),
      child: Text(
        label,
        style: AppTheme.uiLabel.copyWith(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: AppTheme.textSecondary,
        ),
      ),
    );
  }
}
