import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:protocol_handler/protocol_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:window_manager/window_manager.dart';

import 'app_router.dart';
import 'core/config/supabase_config.dart';
import 'core/services/device_id_service.dart';
import 'core/services/hotkey_service.dart';
import 'core/theme/app_theme.dart';
import 'features/clipboard/application/clipboard_sync_service.dart';
import 'features/tray/tray_manager_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── 1. Supabase ────────────────────────────────────────────────────────────
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
    debug: kDebugMode,
  );

  // ── 2. Device ID ───────────────────────────────────────────────────────────
  await DeviceIdService.getDeviceId();

  // ── 3. Desktop: window + tray ──────────────────────────────────────────────
  if (_isDesktop) {
    await protocolHandler.register('clipq');
    await windowManager.ensureInitialized();
    await windowManager.waitUntilReadyToShow(
      const WindowOptions(
        size: Size(420, 700),
        minimumSize: Size(360, 500),
        center: true,
        title: 'ClipQ',
        backgroundColor: Colors.transparent,
        titleBarStyle: TitleBarStyle.normal,
      ),
      () async {
        await windowManager.show();
        await windowManager.focus();
      },
    );
    await TrayManagerService.initIfDesktop();
    await HotkeyService.initIfDesktop();
  }

  runApp(const ProviderScope(child: ClipQApp()));
}

// ── App widget ─────────────────────────────────────────────────────────────────

class ClipQApp extends ConsumerWidget {
  const ClipQApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Boot sync service eagerly so it starts before first navigation.
    ref.watch(clipboardSyncServiceProvider);

    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'ClipQ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: router,
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────

bool get _isDesktop =>
    !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);
