import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/device_id_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/auth_notifier.dart';
import '../../application/clipboard_sync_service.dart';
import '../notifiers/clipboard_history_notifier.dart';

/// Settings page for ClipQ.
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
    final syncStatus = ref.watch(clipboardSyncServiceProvider);
    final isPaused = syncStatus.valueOrNull == SyncStatus.paused;

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        backgroundColor: AppTheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textSecondary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Settings',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: AppTheme.border),
        ),
      ),
      body: ListView(
        children: [
          _sectionHeader('DEVICE'),
          _buildDeviceNameTile(),
          const Divider(height: 1),
          _buildDeviceIdTile(),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _sectionHeader('SYNC'),
          _buildSyncToggle(isPaused),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _sectionHeader('SHORTCUT'),
          _buildShortcutTile(),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _sectionHeader('HISTORY'),
          _buildClearHistoryTile(),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _sectionHeader('ACCOUNT'),
          _buildSignOutTile(),
          const Divider(height: 1),
          const SizedBox(height: 32),
          Center(
            child: Text(
              'ClipQ v1.0.0',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textMuted,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDeviceNameTile() {
    return Container(
      color: AppTheme.surfaceCard,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.computer, color: AppTheme.textMuted, size: 16),
              SizedBox(width: 10),
              Text(
                'Device Name',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _nameController,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
            decoration: const InputDecoration(
              hintText: 'e.g. My Windows PC',
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            ),
            onSubmitted: (v) => DeviceIdService.setDeviceName(v.trim()),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceIdTile() {
    return Container(
      color: AppTheme.surfaceCard,
      child: ListTile(
        leading: const Icon(Icons.fingerprint, color: AppTheme.textMuted, size: 18),
        title: const Text(
          'Device ID',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
        ),
        subtitle: Text(
          _deviceId.isEmpty ? '…' : _deviceId,
          style: const TextStyle(
            color: AppTheme.textMuted,
            fontSize: 11,
            fontFamily: 'monospace',
          ),
        ),
      ),
    );
  }

  Widget _buildSyncToggle(bool isPaused) {
    return Container(
      color: AppTheme.surfaceCard,
      child: SwitchListTile(
        value: !isPaused,
        onChanged: (_) =>
            ref.read(clipboardSyncServiceProvider.notifier).togglePause(),
        title: const Text(
          'Clipboard Sync',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
        ),
        subtitle: Text(
          isPaused ? 'Sync is paused' : 'Syncing in real-time',
          style: TextStyle(
            color: isPaused ? AppTheme.warning : AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
        secondary: Icon(
          isPaused ? Icons.sync_disabled : Icons.sync,
          color: isPaused ? AppTheme.warning : AppTheme.accent,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildSignOutTile() {
    return Container(
      color: AppTheme.surfaceCard,
      child: ListTile(
        leading: const Icon(Icons.logout, color: AppTheme.error, size: 18),
        title: const Text(
          'Sign Out',
          style: TextStyle(color: AppTheme.error, fontSize: 14),
        ),
        onTap: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppTheme.surfaceCard,
              shape: const RoundedRectangleBorder(),
              title: const Text(
                'Sign Out?',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
              ),
              content: const Text(
                'Your clipboard history will remain stored on Supabase.',
                style: TextStyle(
                    color: AppTheme.textSecondary, fontSize: 13),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text(
                    'Sign Out',
                    style: TextStyle(color: AppTheme.error),
                  ),
                ),
              ],
            ),
          );
          if (confirmed == true && mounted) {
            await ref.read(authNotifierProvider.notifier).signOut();
          }
        },
      ),
    );
  }

  Widget _buildClearHistoryTile() {
    return Container(
      color: AppTheme.surfaceCard,
      child: ListTile(
        leading: const Icon(Icons.delete_sweep, color: AppTheme.error, size: 20),
        title: const Text(
          'Clear Clipboard History',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
        ),
        subtitle: const Text(
          'Permanently deletes all text and image clips.',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
        ),
        onTap: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppTheme.surfaceCard,
              shape: const RoundedRectangleBorder(),
              title: const Text(
                'Delete all history?',
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
              ),
              content: const Text(
                'This will permanently remove all your synced clipboard items and image files. This action cannot be undone.',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text(
                    'Clear All',
                    style: TextStyle(color: AppTheme.error),
                  ),
                ),
              ],
            ),
          );
          if (confirmed == true && mounted) {
            await ref.read(clipboardHistoryProvider.notifier).clearAll();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Clipboard history cleared')),
              );
            }
          }
        },
      ),
    );
  }

  Widget _buildShortcutTile() {
    final isMac = !kIsWeb && Platform.isMacOS;
    final shortcutText = isMac ? '⌥ + ⌘ + V' : 'Alt + Ctrl + V';

    return Container(
      color: AppTheme.surfaceCard,
      child: ListTile(
        leading: const Icon(Icons.keyboard, color: AppTheme.textMuted, size: 20),
        title: const Text(
          'Toggle Window Shortcut',
          style: TextStyle(color: AppTheme.textPrimary, fontSize: 14),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: AppTheme.border),
          ),
          child: Text(
            shortcutText,
            style: const TextStyle(
              color: AppTheme.accent,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ),
        subtitle: const Text(
          'Global shortcut to show or hide ClipQ from anywhere.',
          style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
        ),
      ),
    );
  }
}
