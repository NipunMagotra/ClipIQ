import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import '../../core/constants/app_constants.dart';

/// Manages the system tray icon and window hide/restore on desktop.
///
/// This class is a no-op on mobile. Use [TrayManagerService.initIfDesktop()]
/// to safely initialise only on Windows / macOS / Linux.
class TrayManagerService with TrayListener, WindowListener {
  TrayManagerService._();

  static TrayManagerService? _instance;
  static TrayManagerService get instance =>
      _instance ??= TrayManagerService._();

  bool _initialised = false;

  /// Call once from [main] after [WindowManager.ensureInitialized()].
  static Future<void> initIfDesktop() async {
    if (!_isDesktop) return;
    await instance._init();
  }

  Future<void> _init() async {
    if (_initialised) return;
    _initialised = true;

    trayManager.addListener(this);
    windowManager.addListener(this);

    await windowManager.setPreventClose(true);

    await trayManager.setIcon(_trayIconPath);
    await trayManager.setToolTip(AppConstants.appName);
    await trayManager.setContextMenu(_buildMenu());

    debugPrint('[TrayManager] initialised');
  }

  // ── Context menu ──────────────────────────────────────────────────────────

  Menu _buildMenu() {
    return Menu(
      items: [
        MenuItem(
          key: 'show',
          label: 'Show ${AppConstants.appName}',
        ),
        MenuItem.separator(),
        MenuItem(
          key: 'quit',
          label: 'Quit',
        ),
      ],
    );
  }

  // ── TrayListener ──────────────────────────────────────────────────────────

  @override
  void onTrayIconMouseDown() => _showWindow();

  @override
  void onTrayMenuItemClick(MenuItem menuItem) {
    switch (menuItem.key) {
      case 'show':
        _showWindow();
      case 'quit':
        _quit();
    }
  }

  // ── WindowListener ────────────────────────────────────────────────────────

  @override
  void onWindowClose() async {
    // Minimise to tray instead of quitting.
    await windowManager.hide();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<void> _showWindow() async {
    final isVisible = await windowManager.isVisible();
    if (!isVisible) await windowManager.show();
    await windowManager.focus();
  }

  Future<void> _quit() async {
    trayManager.removeListener(this);
    windowManager.removeListener(this);
    await windowManager.setPreventClose(false);
    await windowManager.destroy();
  }

  static bool get _isDesktop =>
      !kIsWeb &&
      (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  /// Platform-appropriate tray icon path.
  ///
  /// Place a 16×16 `tray_icon.ico` (Windows) or `tray_icon.png` (macOS/Linux)
  /// under `assets/images/` and declare in pubspec.yaml.
  static String get _trayIconPath {
    if (Platform.isWindows) return 'assets/images/tray_icon.ico';
    return 'assets/images/tray_icon.png';
  }
}
