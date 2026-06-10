# Project Context: Universal Clipboard Sync App

## Technical Stack
- **Frontend Framework:** Flutter (Dart)
- **Target Platforms:** Android, iOS, macOS, Windows
- **Backend & Database:** Supabase (PostgreSQL with Realtime WebSockets)
- **Core Clipboard Engine:** `super_clipboard: ^0.9.1`

## System Constraints & Architectural Blueprints

### 1. Database Schema Design (Supabase)
- Table name: `clipboards`
- Columns:
  - `id` (uuid, primary key)
  - `user_id` (uuid, links to auth.users)
  - `content_type` (text: 'text', 'html', 'image')
  - `text_content` (text, nullable)
  - `storage_path` (text, nullable - for image/binary uploads in Supabase Storage buckets)
  - `copied_at` (timestamp with time zone, default: now())
  - `device_id` (text - prevents echo-looping syncs back to origin device)

### 2. Core Flutter Implementations (super_clipboard API Blueprint)
Always write `super_clipboard` read/write handlers matching this structural template:

```dart
// Reading Clipboard Content Safely
final clipboard = SystemClipboard.instance;
if (clipboard != null) {
  final reader = await clipboard.read();
  if (reader.canProvide(Formats.plainText)) {
    final text = await reader.readValue(Formats.plainText);
    // Sync to Supabase logic goes here
  }
}

// Writing Clipboard Content Safely
final clipboard = SystemClipboard.instance;
if (clipboard != null) {
  final item = DataWriterItem();
  item.add(Formats.plainText("Text to sync"));
  await clipboard.write([item]);
}
```

### 3. Critical Platform Configurations

* **macOS:** Must maintain hardware entitlements for sandbox isolation. Ensure `<key>com.apple.security.print</key><true/>` configurations are injected when setting up app profiles.
* **Android:** Android 10+ clipboard background limitations mean the app relies on dynamic app lifecycle tracking or an explicit Foreground Service task to capture context state cleanly.
* **Realtime Filtering:** Every device must filter incoming database broadcast payloads against its own local device ID metadata to prevent infinite clipboard rewriting loops.
