import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Where the JWT lives between launches.
abstract interface class TokenStore {
  Future<String?> read();
  Future<void> write(String token);
  Future<void> clear();
}

class SecureTokenStore implements TokenStore {
  static const _key = 'stams.jwt';
  final _storage = const FlutterSecureStorage();
  String? _cached;

  @override
  Future<String?> read() async => _cached ??= await _storage.read(key: _key);

  @override
  Future<void> write(String token) async {
    _cached = token;
    await _storage.write(key: _key, value: token);
  }

  @override
  Future<void> clear() async {
    _cached = null;
    await _storage.delete(key: _key);
  }
}

/// Demo mode: the session only lasts until the app restarts.
class MemoryTokenStore implements TokenStore {
  String? _token;

  @override
  Future<String?> read() async => _token;

  @override
  Future<void> write(String token) async => _token = token;

  @override
  Future<void> clear() async => _token = null;
}
