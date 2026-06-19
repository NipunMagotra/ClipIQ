import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/design_components.dart';
import '../../application/clipboard_sync_service.dart';
import '../../data/models/clipboard_item.dart';
import '../notifiers/clipboard_history_notifier.dart';
import '../widgets/clip_card.dart';

/// Main home screen of ClipQ — redesigned with premium Linear/Raycast aesthetics.
///
/// Layout:
///   AppHeader
///   SearchField
///   FilterChips
///   Divider
///   ClipboardList  or  EmptyState
///   FooterStatusBar
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _searchController = TextEditingController();
  final _searchFieldKey = GlobalKey<SearchFieldState>();
  String _searchQuery = '';
  ClipFilter _selectedFilter = ClipFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Keyboard shortcut: Ctrl+Alt+V / Ctrl+K → focus search ────────────────
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.keyK &&
        HardwareKeyboard.instance.isControlPressed) {
      _searchFieldKey.currentState?.focusNode.requestFocus();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      onKeyEvent: _handleKeyEvent,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: Column(
          children: [
            const AppHeader(),
            SearchField(
              key: _searchFieldKey,
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            ),
            FilterChips(
              selected: _selectedFilter,
              onChanged: (f) => setState(() => _selectedFilter = f),
            ),
            const Divider(height: 1, color: AppTheme.divider),
            Expanded(child: _buildHistoryList()),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // ── History List ────────────────────────────────────────────────────────────

  Widget _buildHistoryList() {
    final historyAsync = ref.watch(clipboardHistoryProvider);

    return historyAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: AppTheme.accent,
          strokeWidth: 2,
        ),
      ),
      error: (e, _) => _buildError(e.toString()),
      data: (items) {
        var filtered = items.where((i) {
          // Content type filter
          if (_selectedFilter != ClipFilter.all) {
            final matchesType = switch (_selectedFilter) {
              ClipFilter.text   => i.contentType == 'text',
              ClipFilter.code   => i.contentType == 'text' &&
                  _looksLikeCode(i.textContent ?? ''),
              ClipFilter.links  => i.contentType == 'text' &&
                  _looksLikeUrl(i.textContent ?? ''),
              ClipFilter.images => i.contentType == 'image',
              ClipFilter.html   => i.contentType == 'html',
              ClipFilter.all    => true,
            };
            if (!matchesType) return false;
          }
          // Search filter
          if (_searchQuery.isNotEmpty) {
            return i.preview.toLowerCase().contains(_searchQuery);
          }
          return true;
        }).toList();

        if (filtered.isEmpty) return _buildEmpty();

        // Group items by date
        final sections = _groupByDate(filtered);

        return RefreshIndicator(
          color: AppTheme.accent,
          backgroundColor: AppTheme.surfaceCard,
          onRefresh: () =>
              ref.read(clipboardHistoryProvider.notifier).refresh(),
          child: ListView.builder(
            padding: EdgeInsets.zero,
            itemCount: sections.length,
            itemBuilder: (ctx, i) {
              final section = sections[i];
              if (section is _DateHeader) {
                return _buildDateHeader(section.label);
              }
              return ClipCard(
                item: (section as _ClipEntry).item,
                index: (section).index,
              );
            },
          ),
        );
      },
    );
  }

  // ── Date Grouping ──────────────────────────────────────────────────────────

  List<Object> _groupByDate(List<ClipboardItem> items) {
    final result = <Object>[];
    String? lastLabel;

    for (var i = 0; i < items.length; i++) {
      final label = _dateLabel(items[i].copiedAt);
      if (label != lastLabel) {
        result.add(_DateHeader(label));
        lastLabel = label;
      }
      result.add(_ClipEntry(items[i], i));
    }
    return result;
  }

  String _dateLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDay = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(itemDay).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff <= 7) return 'This Week';
    return 'Older';
  }

  Widget _buildDateHeader(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Text(
        label.toUpperCase(),
        style: AppTheme.headingSection,
      ),
    );
  }

  // ── Heuristics ─────────────────────────────────────────────────────────────

  bool _looksLikeCode(String text) {
    final codeIndicators = ['{', '}', '=>', 'function', 'class ', 'import ',
        'const ', 'var ', 'let ', 'def ', 'return ', ';', '()', '[]'];
    final lower = text.toLowerCase();
    return codeIndicators.any((ind) => lower.contains(ind));
  }

  bool _looksLikeUrl(String text) {
    final t = text.trim();
    return t.startsWith('http://') ||
        t.startsWith('https://') ||
        t.startsWith('www.') ||
        RegExp(r'^[\w.-]+\.\w{2,}(/|$)').hasMatch(t);
  }

  // ── Empty State ────────────────────────────────────────────────────────────

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const ClipTextIcon(size: 24, color: AppTheme.textMuted),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No matching clips'
                  : 'Clipboard is empty',
              style: AppTheme.uiStrong.copyWith(fontSize: 14),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No clips match "$_searchQuery"'
                  : 'Copy anything to sync across devices',
              style: AppTheme.uiBody.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Error State ────────────────────────────────────────────────────────────

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppTheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.cloud_off_rounded,
                  color: AppTheme.error, size: 20),
            ),
            const SizedBox(height: 16),
            Text('Connection error', style: AppTheme.uiStrong),
            const SizedBox(height: 6),
            Text(
              message,
              style: AppTheme.uiBody.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () =>
                  ref.read(clipboardHistoryProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Footer Status Bar ──────────────────────────────────────────────────────

  Widget _buildFooter() {
    final historyAsync = ref.watch(clipboardHistoryProvider);
    final itemCount = historyAsync.valueOrNull?.length ?? 0;
    final syncState = ref.watch(clipboardSyncServiceProvider).valueOrNull;
    final statusText = syncState?.status == SyncStatus.paused
        ? 'Sync paused'
        : 'Synced';

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppTheme.background,
        border: Border(
          top: BorderSide(color: AppTheme.divider, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Text(
            '$itemCount clip${itemCount == 1 ? '' : 's'} · $statusText',
            style: AppTheme.uiLabel.copyWith(
              fontSize: 11,
              color: AppTheme.textMuted,
            ),
          ),
          const Spacer(),
          Text(
            'v2.0.0',
            style: AppTheme.uiLabel.copyWith(
              fontSize: 10,
              color: AppTheme.textMuted.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helper classes for date grouping ──────────────────────────────────────────

class _DateHeader {
  final String label;
  const _DateHeader(this.label);
}

class _ClipEntry {
  final ClipboardItem item;
  final int index;
  const _ClipEntry(this.item, this.index);
}
