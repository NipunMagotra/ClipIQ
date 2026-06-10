import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/auth_notifier.dart';
import '../../application/clipboard_sync_service.dart';
import '../notifiers/clipboard_history_notifier.dart';
import '../widgets/clip_card.dart';

/// Main home screen of ClipQ.
///
/// Layout:
///  - AppBar with sync status + pause button + user menu
///  - Search field
///  - Clipboard history list (paginated)
///  - Empty / loading / error states
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          const Divider(height: 1),
          Expanded(child: _buildHistoryList()),
        ],
      ),
    );
  }

  // ── AppBar ──────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    final syncStatus = ref.watch(clipboardSyncServiceProvider);
    final status = syncStatus.valueOrNull ?? SyncStatus.idle;
    final isPaused = status == SyncStatus.paused;

    return AppBar(
      backgroundColor: AppTheme.surface,
      elevation: 0,
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: AppTheme.border),
      ),
      title: Row(
        children: [
          Icon(
            Icons.content_paste,
            color: AppTheme.primary,
            size: 20,
          ),
          const SizedBox(width: 8),
          const Text(
            'ClipQ',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      actions: [
        // Sync status indicator
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: _SyncBadge(status: status),
        ),
        const SizedBox(width: 8),

        // Pause / Resume
        Tooltip(
          message: isPaused ? 'Resume sync' : 'Pause sync',
          child: IconButton(
            onPressed: () =>
                ref.read(clipboardSyncServiceProvider.notifier).togglePause(),
            icon: Icon(
              isPaused ? Icons.play_arrow : Icons.pause,
              color: AppTheme.textSecondary,
              size: 20,
            ),
          ),
        ),

        // User menu
        PopupMenuButton<String>(
          color: AppTheme.surfaceCard,
          shape: const RoundedRectangleBorder(),
          icon: const Icon(Icons.person_outline,
              color: AppTheme.textSecondary, size: 20),
          itemBuilder: (_) => [
            _menuItem('settings', Icons.settings_outlined, 'Settings'),
            const PopupMenuDivider(),
            _menuItem('signout', Icons.logout, 'Sign Out',
                color: AppTheme.error),
          ],
          onSelected: (value) async {
            if (value == 'settings') {
              context.go('/settings');
            } else if (value == 'signout') {
              await ref.read(authNotifierProvider.notifier).signOut();
            }
          },
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label,
      {Color? color}) {
    final c = color ?? AppTheme.textPrimary;
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, color: c, size: 16),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                  color: c, fontSize: 14, fontWeight: FontWeight.w400)),
        ],
      ),
    );
  }

  // ── Search bar ──────────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(
            color: AppTheme.textPrimary, fontSize: 14),
        onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
        decoration: InputDecoration(
          hintText: 'Search clipboard history…',
          prefixIcon:
              const Icon(Icons.search, color: AppTheme.textMuted, size: 18),
          suffixIcon: _searchQuery.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  child: const Icon(Icons.close,
                      color: AppTheme.textMuted, size: 16),
                )
              : null,
        ),
      ),
    );
  }

  // ── History list ────────────────────────────────────────────────────────────

  Widget _buildHistoryList() {
    final historyAsync = ref.watch(clipboardHistoryProvider);

    return historyAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
            color: AppTheme.primary, strokeWidth: 2),
      ),
      error: (e, _) => _buildError(e.toString()),
      data: (items) {
        final filtered = _searchQuery.isEmpty
            ? items
            : items
                .where(
                    (i) => i.preview.toLowerCase().contains(_searchQuery))
                .toList();

        if (filtered.isEmpty) return _buildEmpty();

        return RefreshIndicator(
          color: AppTheme.primary,
          backgroundColor: AppTheme.surfaceCard,
          onRefresh: () =>
              ref.read(clipboardHistoryProvider.notifier).refresh(),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: filtered.length + 1,
            itemBuilder: (ctx, i) {
              if (i == filtered.length) {
                return _buildLoadMore();
              }
              return ClipCard(item: filtered[i], index: i);
            },
          ),
        );
      },
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.content_paste_off,
              color: AppTheme.textMuted, size: 40),
          const SizedBox(height: 16),
          const Text(
            'No clips yet',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _searchQuery.isNotEmpty
                ? 'No clips match "$_searchQuery"'
                : 'Copy anything on this device and it will appear here.',
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.cloud_off, color: AppTheme.error, size: 36),
          const SizedBox(height: 16),
          const Text(
            'Connection error',
            style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(
                color: AppTheme.textSecondary, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () =>
                ref.read(clipboardHistoryProvider.notifier).refresh(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMore() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: TextButton.icon(
          onPressed: () =>
              ref.read(clipboardHistoryProvider.notifier).loadMore(),
          icon: const Icon(Icons.expand_more, size: 16),
          label: const Text('Load more'),
          style: TextButton.styleFrom(
              foregroundColor: AppTheme.textSecondary),
        ),
      ),
    );
  }
}

// ── Sync Status Badge ──────────────────────────────────────────────────────────

class _SyncBadge extends StatelessWidget {
  const _SyncBadge({required this.status});
  final SyncStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      SyncStatus.syncing => ('Syncing', AppTheme.accent),
      SyncStatus.paused  => ('Paused',  AppTheme.warning),
      SyncStatus.error   => ('Error',   AppTheme.error),
      _                  => ('Live',    AppTheme.success),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: color.withAlpha(150)),
        color: color.withAlpha(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
