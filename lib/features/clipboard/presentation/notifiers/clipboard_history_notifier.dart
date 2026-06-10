import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../application/clipboard_sync_service.dart';
import '../../data/models/clipboard_item.dart';

// ── Provider ────────────────────────────────────────────────────────────────────

final clipboardHistoryProvider =
    AsyncNotifierProvider<ClipboardHistoryNotifier, List<ClipboardItem>>(
  () => ClipboardHistoryNotifier(),
);

// ── Notifier ────────────────────────────────────────────────────────────────────

class ClipboardHistoryNotifier extends AsyncNotifier<List<ClipboardItem>> {
  @override
  Future<List<ClipboardItem>> build() async {
    // Reload history whenever the sync service changes (e.g. new item uploaded).
    ref.watch(clipboardSyncServiceProvider);

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return [];

    final repo = ref.read(clipboardRepositoryProvider);
    return repo.fetchHistory();
  }

  // ── Public actions ─────────────────────────────────────────────────────────

  /// Prepends a newly received remote item to the list without a full reload.
  void prependItem(ClipboardItem item) {
    final current = state.valueOrNull ?? [];
    // Avoid duplicates.
    if (current.any((e) => e.id == item.id)) return;
    state = AsyncData([item, ...current]);
  }

  /// Removes an item optimistically and deletes from Supabase.
  Future<void> deleteItem(String id) async {
    final current = state.valueOrNull ?? [];
    state = AsyncData(current.where((e) => e.id != id).toList());

    final repo = ref.read(clipboardRepositoryProvider);
    await repo.deleteItem(id);
  }

  /// Load older items (pagination).
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.isEmpty) return;

    final oldest = current.last.copiedAt;
    final repo = ref.read(clipboardRepositoryProvider);
    final more = await repo.fetchHistory(before: oldest);

    state = AsyncData([...current, ...more]);
  }

  /// Force-refresh the full history list.
  Future<void> refresh() async {
    state = const AsyncLoading();
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      state = const AsyncData([]);
      return;
    }
    final repo = ref.read(clipboardRepositoryProvider);
    state = AsyncData(await repo.fetchHistory());
  }

  /// Clears the entire clipboard history.
  Future<void> clearAll() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    state = const AsyncData([]); // Clear UI list immediately (optimistic update)

    final repo = ref.read(clipboardRepositoryProvider);
    await repo.clearHistory(user.id);
  }
}
