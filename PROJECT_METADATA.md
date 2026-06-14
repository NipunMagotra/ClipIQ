# ClipQ Project Metadata (AI Context & Architecture)

This document provides a comprehensive blueprint of the ClipQ codebase to help AI coding assistants understand the architecture, data flow, structure, and design patterns used in the project.

---

## 🛠️ Tech Stack & Dependencies

*   **Frontend Framework:** Flutter (Dart SDK `^3.12.1`)
*   **Backend & Realtime Database:** Supabase (`supabase_flutter` for authentication, database, and storage)
*   **State Management:** Riverpod (`flutter_riverpod` async/sync providers)
*   **Navigation / Routing:** GoRouter (`go_router`)
*   **Clipboard Operations:** `super_clipboard` (rich content parsing) & `clipboard_watcher` (clipboard event monitoring)
*   **Desktop Management:** `window_manager`, `tray_manager`, `protocol_handler`, and `hotkey_manager`

---

## 📂 Project Directory Structure

The application follows a clean-architecture/feature-first pattern:

```text
lib/
├── app_router.dart                     # Application routes (login, home, settings)
├── main.dart                           # Main entry point (initializes Supabase and Window/Tray setups)
├── core/
│   ├── config/
│   │   └── supabase_config.dart        # Supabase API credentials
│   ├── constants/
│   │   └── app_constants.dart          # Configuration timeouts, sizes, debounces
│   ├── services/
│   │   ├── clipboard_monitor_service.dart # Listens to OS clipboard events
│   │   ├── clipboard_service.dart      # Wrapper for reading/writing via super_clipboard
│   │   ├── device_id_service.dart      # Generates/retrieves persistent unique device identifiers
│   │   └── hotkey_service.dart         # Global hotkey listener (e.g. show/hide window)
│   └── theme/
│       └── app_theme.dart              # Theme configurations (curated dark theme palette)
└── features/
    ├── auth/
    │   ├── data/
    │   │   └── auth_repository.dart    # Supabase authentication integration
    │   ├── presentation/
    │   │   ├── auth_notifier.dart      # Manages user authentication state
    │   │   └── pages/
    │   │       └── login_page.dart     # UI: Supports Email/Password, Create Account, and Magic Link
    │   └── domain/
    ├── clipboard/
    │   ├── application/
    │   │   └── clipboard_sync_service.dart # Orchestrates local-to-remote & remote-to-local sync
    │   ├── data/
    │   │   ├── clipboard_repository.dart # Connects to Supabase Database/Storage
    │   │   └── models/
    │   │       └── clipboard_item.dart # Data model representing a single synced clipboard item
    │   └── presentation/
    │       ├── notifiers/
    │       │   └── clipboard_history_notifier.dart # Riverpod state for clipboard list history
    │       ├── pages/
    │       │   ├── home_page.dart      # UI: Main clipboard list, copy/paste, pause/resume
    │       │   └── settings_page.dart  # UI: User details, logout, and device status
    │       └── widgets/
    │           └── clip_card.dart      # UI component representing a clipboard item card
    └── tray/
        └── tray_manager_service.dart   # System tray integration (show, hide, exit)
```

---

## 🗄️ Database Schema Design (Supabase)

The database matches the following PostgreSQL definition:

*   **Table Name:** `clipboards`
*   **Columns:**
    *   `id` (uuid, primary key)
    *   `user_id` (uuid, references `auth.users`)
    *   `content_type` (text: `'text'` | `'html'` | `'image'`)
    *   `text_content` (text, nullable)
    *   `storage_path` (text, nullable - paths inside the Supabase Storage bucket for binary files/images)
    *   `copied_at` (timestamp with timezone, default: `now()`)
    *   `device_id` (text - identifier of the source device)

---

## 🔄 Core Application Flows & Blueprints

### 1. Safe Clipboard Read/Write (via `super_clipboard`)
Always perform clipboard reading and writing using `SystemClipboard.instance` securely matching this design:

```dart
// Reading system clipboard safely
final clipboard = SystemClipboard.instance;
if (clipboard != null) {
  final reader = await clipboard.read();
  if (reader.canProvide(Formats.plainText)) {
    final text = await reader.readValue(Formats.plainText);
    // sync logic
  }
}

// Writing to system clipboard safely
final clipboard = SystemClipboard.instance;
if (clipboard != null) {
  final item = DataWriterItem();
  item.add(Formats.plainText("Text to sync"));
  await clipboard.write([item]);
}
```

### 2. Clipboard Sync Pipeline (`ClipboardSyncService`)
1. **Local Monitor:** Listens to `ClipboardMonitorService.instance.clipboardChanges`.
   * *Desktop:* Uses `clipboard_watcher` (polling-based backend daemon).
   * *Mobile:* Restricts OS clipboard access in the background; falls back to app lifecycle monitoring (triggers sync when app is foregrounded).
2. **Debounce:** Evokes `AppConstants.uploadDebounce` (e.g. 500ms) to ignore rapid multi-format changes.
3. **Deduplication:** Verifies new copy doesn't match the last uploaded/downloaded payload.
4. **Echo Prevention:** Subscribes to Supabase Realtime channel for new inserts. If the `device_id` of the remote record matches `DeviceIdService.getDeviceId()`, the payload is ignored to avoid an infinite loop of writing to/from the clipboard.

---

## ⚠️ Important Rules for AI Modifying this Project

1. **Do not remove Echo Prevention:** The `device_id` comparison check in the remote insert listener (`_onRemoteInsert` in `ClipboardSyncService`) is critical. Removing it will trigger endless feedback loops.
2. **Platform Specifics:** Keep desktop-only plugins (`window_manager`, `tray_manager`, `hotkey_manager`) behind checking guards (e.g. `_isDesktop`).
3. **C-Runtime (CRT) Windows Build Mismatches:** If compiling in Debug mode on Windows causes linker errors due to `window_manager` or `screen_retriever` using debug CRT `libcpmtd.lib` while other objects use standard CRT, build the app in **Release Mode** using `flutter run -d windows --release` to ensure proper linking.
