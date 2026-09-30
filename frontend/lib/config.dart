/// Build-time configuration, set with --dart-define.
///
///   flutter run                                   -> real API on the Android emulator host
///   flutter run --dart-define=STAMS_DEMO=true     -> no backend, everything from demo data
///   flutter run --dart-define=STAMS_API_URL=http://192.168.1.20:8081
library;

/// When true every repository is backed by the in-memory demo store,
/// so the whole app can be clicked through without the Spring backend.
const bool kDemoMode = bool.fromEnvironment('STAMS_DEMO');

/// 10.0.2.2 is the host machine as seen from the Android emulator.
const String kApiBaseUrl = String.fromEnvironment('STAMS_API_URL', defaultValue: 'http://10.0.2.2:8081');

const String kAppVersion = '1.0.0';
