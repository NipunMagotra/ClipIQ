import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/clipboard_monitor_service.dart';
import '../../../core/services/clipboard_service.dart';
import '../../../core/services/device_id_service.dart';
import '../data/clipboard_repository.dart';
import '../data/models/clipboard_item.dart';
import '../presentation/notifiers/clipboard_history_notifier.dart';

// ── Providers ──────────────────────────────────────────────────────────────────

final clipboardRepositoryProvider = Provider<ClipboardRepository>((ref) {
  return ClipboardRepository(Supabase.instance.client);
});

final clipboardServiceProvider = Provider<ClipboardService>((ref) {
  return const ClipboardService();
});

final clipboardSyncServiceProvider =
    AsyncNotifierProvider<ClipboardSyncService, SyncStatus>(
  () => ClipboardSyncService(),
);

// ── Sync status ────────────────────────────────────────────────────────────────

enum SyncStatus { idle, syncing, paused, error }

// ── Service ────────────────────────────────────────────────────────────────────

/// Orchestrates the full clipboard sync pipeline:
///
/// 1. Listens to [ClipboardMonitorService] for local copy events
/// 2. Reads clipboard via [ClipboardService]
/// 3. Deduplicates against last synced content
/// 4. Uploads to Supabase via [ClipboardRepository]
/// 5. Subscribes to Supabase Realtime for remote inserts
/// 6. Filters out own-device echoes via [device_id]
/// 7. Writes remote content back to local clipboard
class ClipboardSyncService extends AsyncNotifier<SyncStatus> {
  StreamSubscription<void>? _monitorSub;
  Timer? _debounce;
  ClipboardPayload? _lastUploadedPayload;
  String? _deviceId;
  String? _userId;

  @override
  Future<SyncStatus> build() async {
    ref.onDispose(_dispose);

    // Boot up the sync pipeline if user is authenticated.
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      await _startSync(user);
    }

    // Watch for auth changes (login / logout).
    Supabase.instance.client.auth.onAuthStateChange.listen((authState) async {
      final user = authState.session?.user;
      if (user != null) {
        await _startSync(user);
      } else {
        await _stopSync();
      }
    });

    return SyncStatus.idle;
  }

  // ── Public actions ──────────────────────────────────────────────────────────

  Future<void> togglePause() async {
    final current = state.valueOrNull;
    if (current == SyncStatus.paused) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) await _startSync(user);
    } else {
      await _stopSync();
      state = const AsyncData(SyncStatus.paused);
    }
  }

  // ── Start / stop ────────────────────────────────────────────────────────────

  Future<void> _startSync(User user) async {
    await _stopSync();

    _userId = user.id;
    _deviceId = await DeviceIdService.getDeviceId();

    // ── 1. Subscribe to remote inserts ──────────────────────────────────────
    final repo = ref.read(clipboardRepositoryProvider);
    repo.subscribeToInserts(
      userId: user.id,
      onInsert: _onRemoteInsert,
    );

    // ── 2. Start local clipboard monitor ────────────────────────────────────
    await ClipboardMonitorService.instance.start();
    _monitorSub = ClipboardMonitorService.instance.clipboardChanges
        .listen(_onLocalClipboardChanged);

    state = const AsyncData(SyncStatus.idle);
    debugPrint('[SyncService] started for user ${user.id}, device: $_deviceId');

    // Initial check when sync starts (app launch / resume sync)
    _uploadCurrentClipboard();
  }

  Future<void> _stopSync() async {
    _debounce?.cancel();
    await _monitorSub?.cancel();
    _monitorSub = null;
    await ClipboardMonitorService.instance.stop();
    debugPrint('[SyncService] stopped');
  }

  void _dispose() {
    _debounce?.cancel();
    _monitorSub?.cancel();
  }

  // ── Local clipboard changed ─────────────────────────────────────────────────

  void _onLocalClipboardChanged(void _) {
    // Debounce rapid changes (e.g. password managers copying multiple formats).
    _debounce?.cancel();
    _debounce = Timer(AppConstants.uploadDebounce, _uploadCurrentClipboard);
  }

  Future<void> _uploadCurrentClipboard() async {
    if (_userId == null || _deviceId == null) return;

    try {
      final clipService = ref.read(clipboardServiceProvider);
      final payload = await clipService.readClipboard();
      if (payload == null) return;

      // Deduplicate: skip if this is the same as the last thing we uploaded
      // OR the same as the last thing we wrote from a remote event.
      if (clipService.isSameContent(payload, _lastUploadedPayload)) return;

      // Length constraint for text content
      if (payload.contentType != 'image' && 
          payload.storageContent.length > AppConstants.maxTextLength) {
        return;
      }

      state = const AsyncData(SyncStatus.syncing);
      final repo = ref.read(clipboardRepositoryProvider);

      String? storagePath;
      if (payload.contentType == 'image' && payload.imageBytes != null) {
        final fileName = '${const Uuid().v4()}.png';
        final path = '$_userId/$fileName';
        storagePath = await repo.uploadImage(path, payload.imageBytes!);
        if (storagePath == null) {
          state = const AsyncData(SyncStatus.error);
          return;
        }
      }

      final inserted = await repo.insertItem(
        userId: _userId!,
        contentType: payload.contentType,
        textContent: payload.contentType == 'image' ? '[Image]' : payload.storageContent,
        storagePath: storagePath,
        deviceId: _deviceId!,
      );

      if (inserted == null) {
        state = const AsyncData(SyncStatus.error);
        // Do not update _lastUploadedPayload so the upload can be retried later
        return;
      }

      _lastUploadedPayload = payload;
      state = const AsyncData(SyncStatus.idle);
      
      final displayTxt = payload.contentType == 'image' ? '[Image]' : payload.storageContent;
      debugPrint('[SyncService] uploaded: "${displayTxt.substring(0, displayTxt.length.clamp(0, 40))}..."');
    } catch (e, stack) {
      state = const AsyncData(SyncStatus.error);
      debugPrint('[SyncService] Error uploading clipboard content: $e\n$stack');
    }
  }

  // ── Remote insert received ──────────────────────────────────────────────────

  Future<void> _onRemoteInsert(ClipboardItem item) async {
    // ── Echo prevention: skip items we originated ──
    if (item.deviceId == _deviceId) {
      debugPrint('[SyncService] skipping echo from own device');
      return;
    }

    debugPrint('[SyncService] received remote item: ${item.id}');

    // Write to local system clipboard.
    final clipService = ref.read(clipboardServiceProvider);
    final payload = await _itemToPayload(item);
    if (payload != null) {
      _lastUploadedPayload = payload; // prevent re-upload
      try {
        await clipService.writeClipboard(payload);
      } catch (e) {
        debugPrint('[SyncService] Error writing remote clipboard content: $e');
      }
    }

    // Notify history notifier to prepend the new item.
    ref.read(clipboardHistoryProvider.notifier).prependItem(item);
  }

  // ── Helper ──────────────────────────────────────────────────────────────────

  Future<ClipboardPayload?> _itemToPayload(ClipboardItem item) async {
    if (item.contentType == 'image') {
      if (item.storagePath == null) return null;
      final repo = ref.read(clipboardRepositoryProvider);
      final bytes = await repo.downloadImage(item.storagePath!);
      if (bytes == null) return null;
      return ClipboardPayload(
        contentType: 'image',
        imageBytes: bytes,
      );
    }

    if (item.textContent == null) return null;
    return ClipboardPayload(
      contentType: item.contentType,
      textContent: item.textContent,
    );
  }
}
