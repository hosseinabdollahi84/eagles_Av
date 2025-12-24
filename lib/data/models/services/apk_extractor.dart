import 'package:flutter/services.dart';

class ShizukuApkExtractor {
  static const MethodChannel _channel = MethodChannel('shizuku_apk');

  static Future<String> extractApk(String packageName) async {
    try {
      final String? result = await _channel.invokeMethod('extractApk', {
        'packageName': packageName,
      });
      return result ?? 'error';
    } on PlatformException catch (e) {
      return "error: ${e.message}";
    } catch (e) {
      return 'Error: $e';
    }
  }
}
