import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_constants.dart';
import 'models/clipboard_item.dart';

/// Data layer for clipboard history — read, insert, delete, and realtime stream.
class ClipboardRepository {
  ClipboardRepository(this._client);

  final SupabaseClient _client;

  // ── Fetch history ─────────────────────────────────────────────────────────

  /// Returns [limit] most-recent clipboard items for the current user,
  /// ordered newest-first.
  Future<List<ClipboardItem>> fetchHistory({
    int limit = AppConstants.historyPageSize,
    DateTime? before,
  }) async {
    try {
      var query = _client
          .from(AppConstants.clipboardsTable)
          .select()
          .order('copied_at', ascending: false)
          .limit(limit);

      if (before != null) {
        query = _client
            .from(AppConstants.clipboardsTable)
            .select()
            .lt('copied_at', before.toIso8601String())
            .order('copied_at', ascending: false)
            .limit(limit);
      }

      final data = await query;
      return data
          .map((row) => ClipboardItem.fromMap(row))
          .toList();
    } catch (e) {
      debugPrint('[ClipboardRepository] fetchHistory error: $e');
      return [];
    }
  }

  // ── Insert ────────────────────────────────────────────────────────────────

  /// Inserts a new clipboard item for the authenticated user.
  Future<ClipboardItem?> insertItem({
    required String userId,
    required String contentType,
    String? textContent,
    String? storagePath,
    required String deviceId,
  }) async {
    try {
      final payload = <String, dynamic>{
        'user_id': userId,
        'content_type': contentType,
        'device_id': deviceId,
        if (textContent != null) 'text_content': textContent,
        if (storagePath != null) 'storage_path': storagePath,
      };

      final data = await _client
          .from(AppConstants.clipboardsTable)
          .insert(payload)
          .select()
          .single();

      return ClipboardItem.fromMap(data);
    } catch (e) {
      debugPrint('[ClipboardRepository] insertItem error: $e');
      return null;
    }
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> deleteItem(String id) async {
    try {
      await _client
          .from(AppConstants.clipboardsTable)
          .delete()
          .eq('id', id);
    } catch (e) {
      debugPrint('[ClipboardRepository] deleteItem error: $e');
    }
  }

  // ── Realtime subscription ─────────────────────────────────────────────────

  /// Returns a stream of new [ClipboardItem]s inserted by OTHER devices for
  /// the current user. Echo-loop prevention (filtering own deviceId) is done
  /// in [ClipboardSyncService] rather than here so the repository stays generic.
  RealtimeChannel subscribeToInserts({
    required String userId,
    required void Function(ClipboardItem item) onInsert,
  }) {
    return _client
        .channel(AppConstants.realtimeChannel)
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: AppConstants.clipboardsTable,
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            try {
              final item = ClipboardItem.fromMap(
                  Map<String, dynamic>.from(payload.newRecord));
              onInsert(item);
            } catch (e) {
              debugPrint('[ClipboardRepository] realtime parse error: $e');
            }
          },
        )
        .subscribe();
  }

  // ── Image Storage ──────────────────────────────────────────────────────────

  /// Uploads image bytes to Supabase Storage and returns the storage path.
  Future<String?> uploadImage(String path, Uint8List bytes) async {
    try {
      // Automatically attempt to create the bucket in case it is missing
      try {
        await _client.storage.createBucket('clipboards', const BucketOptions(public: true));
      } catch (_) {
        // Safe to ignore if already exists or no permissions
      }

      await _client.storage.from('clipboards').uploadBinary(
            path,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/png',
              upsert: true,
            ),
          );
      return path;
    } catch (e) {
      debugPrint('[ClipboardRepository] uploadImage error: $e');
      return null;
    }
  }

  /// Downloads image bytes from Supabase Storage.
  Future<Uint8List?> downloadImage(String path) async {
    try {
      final bytes = await _client.storage.from('clipboards').download(path);
      return bytes;
    } catch (e) {
      debugPrint('[ClipboardRepository] downloadImage error: $e');
      return null;
    }
  }

  /// Deletes all clipboard items and associated storage files for the user.
  Future<void> clearHistory(String userId) async {
    try {
      // 1. Delete all items in the database for the user
      await _client
          .from(AppConstants.clipboardsTable)
          .delete()
          .eq('user_id', userId);

      // 2. List and delete all storage files for the user
      final files = await _client.storage.from('clipboards').list(path: userId);
      if (files.isNotEmpty) {
        final paths = files.map((f) => '$userId/${f.name}').toList();
        await _client.storage.from('clipboards').remove(paths);
      }
    } catch (e) {
      debugPrint('[ClipboardRepository] clearHistory error: $e');
    }
  }
}
