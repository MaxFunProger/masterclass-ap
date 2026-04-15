import 'package:flutter/foundation.dart';

String getApiBaseUrl() {
  if (kDebugMode) {
    return 'http://localhost';
  }
  return 'http://158.160.151.247';
}

int getDefaultChatPort() => 5000;
