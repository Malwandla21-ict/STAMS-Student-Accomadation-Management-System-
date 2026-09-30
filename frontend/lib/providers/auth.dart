import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enums.dart';
import '../models/user.dart';
import 'repositories.dart';

/// The signed-in user, or null when signed out. Loading while the splash
/// screen checks the saved session.
class AuthController extends AsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() async {
    // Keep the splash (A1) on screen long enough to read, even when the check is instant.
    final minimumSplash = Future<void>.delayed(const Duration(milliseconds: 900));
    final user = await ref.read(authRepositoryProvider).restore();
    await minimumSplash;
    return user;
  }

  /// Throws [ApiException] so the form can show the message.
  Future<void> signIn({required String email, required String password}) async {
    final user = await ref.read(authRepositoryProvider).signIn(email: email, password: password);
    state = AsyncData(user);
  }

  Future<void> signUp({required String name, required String email, required String password, required Role role}) async {
    final user = await ref.read(authRepositoryProvider).signUp(name: name, email: email, password: password, role: role);
    state = AsyncData(user);
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    state = const AsyncData(null);
  }

  Future<void> sessionExpired() async {
    if (state.value == null) return;
    await signOut();
  }

  void retry() => ref.invalidateSelf();
}

final authControllerProvider = AsyncNotifierProvider<AuthController, AppUser?>(AuthController.new);

final currentUserProvider = Provider<AppUser?>((ref) => ref.watch(authControllerProvider).value);
