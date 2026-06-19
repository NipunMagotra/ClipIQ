import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/clipboard/application/clipboard_sync_service.dart';
import '../theme/app_theme.dart';

/// Minimalist sync status dot for ClipQ v2.
/// Hovering displays sync status. Red dot can be clicked for error details.
class SyncBadge extends ConsumerWidget {
  const SyncBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(clipboardSyncServiceProvider).valueOrNull;
    final status = syncState?.status ?? SyncStatus.idle;

    final (label, color) = switch (status) {
      SyncStatus.syncing => ('Syncing…', AppTheme.accent),
      SyncStatus.paused  => ('Sync Paused', AppTheme.warning),
      SyncStatus.error   => ('Sync Error (Click for info)', AppTheme.error),
      _                  => ('Synced', AppTheme.success),
    };

    final dot = Container(
      width: 7,
      height: 7,
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );

    if (status == SyncStatus.error) {
      return GestureDetector(
        onTap: () => _showErrorDialog(context, syncState),
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Tooltip(
            message: label,
            child: dot,
          ),
        ),
      );
    }

    return Tooltip(
      message: label,
      child: dot,
    );
  }

  void _showErrorDialog(BuildContext context, SyncState? syncState) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: AppTheme.error, size: 20),
            const SizedBox(width: 8),
            Text('Sync Error Details', style: AppTheme.uiStrong),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          constraints: const BoxConstraints(maxHeight: 300),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Error Message:', style: AppTheme.uiLabel.copyWith(
                  fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                const SizedBox(height: 4),
                Text(
                  syncState?.errorMessage ?? 'An unknown error occurred.',
                  style: AppTheme.uiBody.copyWith(color: AppTheme.textSecondary),
                ),
                if (syncState?.errorDetails != null) ...[
                  const SizedBox(height: 16),
                  Text('Details:', style: AppTheme.uiLabel.copyWith(
                    fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  const SizedBox(height: 6),
                  Container(
                    width: double.maxFinite,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: SelectableText(
                      syncState!.errorDetails!,
                      style: AppTheme.contentMono.copyWith(
                        color: AppTheme.textMuted,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
