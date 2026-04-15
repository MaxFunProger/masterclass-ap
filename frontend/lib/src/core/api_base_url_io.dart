import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;

/// Debug Android: эмулятор -> `10.0.2.2` при `--dart-define=ANDROID_EMULATOR=true`; иначе `--dart-define=API_HOST=...` или прод.
const _androidEmulatorHost =
    bool.fromEnvironment('ANDROID_EMULATOR', defaultValue: false);

String getApiBaseUrl() {
  if (kDebugMode) {
    if (Platform.isAndroid) {
      if (_androidEmulatorHost) {
        return 'http://10.0.2.2';
      }
      return 'http://158.160.151.247';
    }
    return 'http://127.0.0.1';
  }
  return 'http://158.160.151.247';
}

int getDefaultChatPort() => 5000;
