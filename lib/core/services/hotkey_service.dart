import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hotkey_manager/hotkey_manager.dart';
import 'package:window_manager/window_manager.dart';

/// Service to handle global application hotkeys (e.g. to toggle the window popup).
class HotkeyService {
  HotkeyService._();

  static HotkeyService? _instance;
  static HotkeyService get instance => _instance ??= HotkeyService._();

  bool _initialised = false;

  /// Initialises global shortcut listener on desktop platforms.
  static Future<void> initIfDesktop() async {
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      await instance._init();
    }
  }

  Future<void> _init() async {
    if (_initialised) return;
    _initialised = true;

    // Must ensure clean registration during hot reload/restarts.
    await hotKeyManager.unregisterAll();

    final isMac = Platform.isMacOS;
    final modifier = isMac ? HotKeyModifier.meta : HotKeyModifier.control;

    // Default global hotkey: Cmd + Alt + V (macOS) or Ctrl + Alt + V (Windows/Linux)
    final toggleHotKey = HotKey(
      key: PhysicalKeyboardKey.keyV,
      modifiers: [modifier, HotKeyModifier.alt],
      scope: HotKeyScope.system,
    );

    await hotKeyManager.register(
      toggleHotKey,
      keyDownHandler: (hotKey) async {
        await toggleWindow();
      },
    );

    debugPrint('[HotkeyService] Registered global shortcut: ${isMac ? "Cmd+Alt+V" : "Ctrl+Alt+V"}');
  }

  /// Toggles the window visibility.
  /// Hides the window if it's currently visible and focused.
  /// Shows and focuses the window if it's hidden or not focused.
  Future<void> toggleWindow() async {
    final isVisible = await windowManager.isVisible();
    final isFocused = await windowManager.isFocused();
    if (isVisible && isFocused) {
      await windowManager.hide();
    } else {
      await windowManager.show();
      await windowManager.focus();
    }
  }
}
