/// Build-time configuration, set with --dart-define.
///
///   flutter run                                   -> real API on this machine (port 8081)
///   flutter run --dart-define=STAMS_DEMO=true     -> no backend, everything from demo data
///   flutter run --dart-define=STAMS_API_URL=http://192.168.1.20:8081
library;

import 'package:flutter/foundation.dart';

/// When true every repository is backed by the in-memory demo store,
/// so the whole app can be clicked through without the Spring backend.
const bool kDemoMode = bool.fromEnvironment('STAMS_DEMO');

const String _apiUrlOverride = String.fromEnvironment('STAMS_API_URL');

/// The Spring backend. Without STAMS_API_URL it's the backend on this machine:
/// the Android emulator reaches the host as 10.0.2.2, everything else
/// (Chrome, desktop, iOS simulator) as localhost.
String get kApiBaseUrl {
  if (_apiUrlOverride.isNotEmpty) return _apiUrlOverride;
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) return 'http://10.0.2.2:8081';
  return 'http://localhost:8081';
}

const String kAppVersion = '1.0.0';

/// The backend returns paths like "/api/uploads/x.jpg"; images need the full address.
String absoluteApiUrl(String url) => url.startsWith('/') ? '$kApiBaseUrl$url' : url;
