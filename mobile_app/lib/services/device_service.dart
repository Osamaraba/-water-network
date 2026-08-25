import 'package:device_info_plus/device_info_plus.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceService {
  static String? _cachedUuid;

  Future<String> getDeviceUuid() async {
    if (_cachedUuid != null) return _cachedUuid!;

    // Web monitoring console uses a stable per-browser UUID stored locally
    // so device binding works without a physical device identifier.
    if (kIsWeb) {
      const key = 'yarmouk_web_device_uuid';
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(key);
      if (stored != null && stored.isNotEmpty) {
        _cachedUuid = stored;
        return _cachedUuid!;
      }
      final generated = _generateWebUuid();
      await prefs.setString(key, generated);
      _cachedUuid = generated;
      return _cachedUuid!;
    }

    final deviceInfo = DeviceInfoPlugin();
    String rawId;

    if (defaultTargetPlatform == TargetPlatform.android) {
      final androidInfo = await deviceInfo.androidInfo;
      rawId = androidInfo.id +
          (androidInfo.brand ?? '') +
          (androidInfo.model ?? '') +
          (androidInfo.fingerprint ?? '');
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final iosInfo = await deviceInfo.iosInfo;
      rawId = (iosInfo.identifierForVendor ?? '') +
          (iosInfo.name ?? '') +
          (iosInfo.model ?? '');
    } else {
      rawId = 'unknown_device';
    }

    final bytes = utf8.encode(rawId);
    final digest = sha256.convert(bytes);
    _cachedUuid = digest.toString().substring(0, 32);

    return _cachedUuid!;
  }

  String _generateWebUuid() {
    final raw = utf8.encode(
        '${DateTime.now().microsecondsSinceEpoch}-${DateTime.now().toIso8601String()}');
    final digest = sha256.convert(raw);
    return digest.toString().substring(0, 32);
  }

  Future<Map<String, dynamic>> getDeviceInfo() async {
    if (kIsWeb) return {'platform': 'web'};

    final deviceInfo = DeviceInfoPlugin();

    if (defaultTargetPlatform == TargetPlatform.android) {
      final info = await deviceInfo.androidInfo;
      return {
        'platform': 'android',
        'version': info.version.release,
        'sdk': info.version.sdkInt,
        'brand': info.brand,
        'model': info.model,
        'manufacturer': info.manufacturer,
      };
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      final info = await deviceInfo.iosInfo;
      return {
        'platform': 'ios',
        'version': info.systemVersion,
        'model': info.model,
        'name': info.name,
      };
    }
    return {'platform': 'unknown'};
  }
}
