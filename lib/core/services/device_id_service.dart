import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../constants/app_constants.dart';

/// Generates and persists a unique device identifier.
///
/// The device_id is used to prevent echo-loop syncs — when a clipboard item
/// is inserted by this device, the Realtime subscription on this device will
/// skip writing it back to the local clipboard.
class DeviceIdService {
  static String? _cachedId;

  DeviceIdService._();

  /// Returns the stable device ID, creating one if this is the first launch.
  static Future<String> getDeviceId() async {
    if (_cachedId != null) return _cachedId!;

    final prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString(AppConstants.prefDeviceId);

    if (id == null) {
      id = const Uuid().v4();
      await prefs.setString(AppConstants.prefDeviceId, id);
    }

    _cachedId = id;
    return id;
  }

  /// Retrieves the user-set device name (defaults to platform name).
  static Future<String> getDeviceName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(AppConstants.prefDeviceName) ?? _defaultDeviceName();
  }

  /// Persists a user-chosen device name.
  static Future<void> setDeviceName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefDeviceName, name);
  }

  static String _defaultDeviceName() {
    // A simple fallback; can be enhanced with device_info_plus later.
    return 'My Device';
  }
}
