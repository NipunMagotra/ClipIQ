import 'dart:async';

import 'package:clipboard_watcher/clipboard_watcher.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// Monitors the system clipboard for changes and exposes a [Stream<void>].
///
/// On **desktop** (Windows / macOS / Linux): uses [clipboard_watcher] which
/// polls the clipboard at a fixed interval and fires events in the background
/// (even when the window is minimised).
///
/// On **mobile** (Android / iOS): background clipboard access is OS-restricted,
/// so we fire an event each time the app comes to the foreground via
/// [WidgetsBindingObserver]. The user's copy won't be synced until they
/// switch back to ClipQ.
class ClipboardMonitorService
    with ClipboardListener, WidgetsBindingObserver {
  ClipboardMonitorService._();

  static ClipboardMonitorService? _instance;
  static ClipboardMonitorService get instance =>
      _instance ??= ClipboardMonitorService._();

  StreamController<void>? _controller;

  /// Fires whenever the clipboard content changes.
  Stream<void> get clipboardChanges {
    _controller ??= StreamController<void>.broadcast();
    return _controller!.stream;
  }

  bool _running = false;

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  /// Starts monitoring clipboard changes.
  Future<void> start() async {
    if (_running) return;
    _running = true;

    // Start clipboard watcher for foreground tracking on all platforms
    clipboardWatcher.addListener(this);
    await clipboardWatcher.start();
    debugPrint('[ClipboardMonitor] started (clipboard_watcher)');

    // Add widgets binding observer for lifecycle/resume tracking on mobile
    if (!_isDesktop) {
      WidgetsBinding.instance.addObserver(this);
      debugPrint('[ClipboardMonitor] started (mobile/AppLifecycle)');
    }
  }

  /// Stops monitoring and releases resources.
  Future<void> stop() async {
    if (!_running) return;
    _running = false;

    clipboardWatcher.removeListener(this);
    await clipboardWatcher.stop();

    if (!_isDesktop) {
      WidgetsBinding.instance.removeObserver(this);
    }

    await _controller?.close();
    _controller = null;
    debugPrint('[ClipboardMonitor] stopped');
  }

  // ── ClipboardListener (desktop) ───────────────────────────────────────────

  @override
  void onClipboardChanged() {
    if (_controller != null && !_controller!.isClosed) {
      _controller!.add(null);
    }
  }

  // ── WidgetsBindingObserver (mobile) ───────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _controller != null &&
        !_controller!.isClosed) {
      _controller!.add(null);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  bool get _isDesktop =>
      defaultTargetPlatform == TargetPlatform.windows ||
      defaultTargetPlatform == TargetPlatform.macOS ||
      defaultTargetPlatform == TargetPlatform.linux;
}
