/// App-wide constants for ClipQ.
class AppConstants {
  AppConstants._();

  // ── Supabase ──────────────────────────────────────────────────────────────
  static const String clipboardsTable = 'clipboards';
  static const String realtimeChannel = 'public:clipboards';

  // ── Content types ─────────────────────────────────────────────────────────
  static const String contentTypeText  = 'text';
  static const String contentTypeHtml  = 'html';
  static const String contentTypeImage = 'image';

  // ── Limits ────────────────────────────────────────────────────────────────
  /// Maximum characters to store per text/html clipboard item.
  static const int maxTextLength = 50000;

  /// Number of items to load per page in history view.
  static const int historyPageSize = 50;

  // ── Sync debounce ─────────────────────────────────────────────────────────
  /// How long to wait after a clipboard change before uploading,
  /// to avoid hammering Supabase when the user copies rapidly.
  static const Duration uploadDebounce = Duration(milliseconds: 600);

  // ── Animation ─────────────────────────────────────────────────────────────
  static const Duration animFast   = Duration(milliseconds: 150);
  static const Duration animNormal = Duration(milliseconds: 300);
  static const Duration animSlow   = Duration(milliseconds: 500);

  // ── SharedPreferences keys ────────────────────────────────────────────────
  static const String prefDeviceId   = 'device_id';
  static const String prefDeviceName = 'device_name';
  static const String prefSyncPaused = 'sync_paused';

  // ── Tray ─────────────────────────────────────────────────────────────────
  static const String appName = 'ClipQ';
}
