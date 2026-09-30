import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config.dart';
import '../data/api_client.dart';
import '../data/demo/demo_repositories.dart';
import '../data/demo/demo_store.dart';
import '../data/repositories.dart';
import '../data/token_store.dart';
import 'auth.dart';

/// Backs everything in demo mode, and issues/alerts/student home in API mode
/// until the backend has those endpoints.
final demoStoreProvider = Provider<DemoStore>((ref) => DemoStore());

final tokenStoreProvider = Provider<TokenStore>((ref) => kDemoMode ? MemoryTokenStore() : SecureTokenStore());

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient(
      ref.watch(tokenStoreProvider),
      // A 401 on any call means the saved token expired - send the user back to sign in.
      onUnauthorized: () => ref.read(authControllerProvider.notifier).sessionExpired(),
    ));

final authRepositoryProvider = Provider<AuthRepository>((ref) => kDemoMode
    ? DemoAuthRepository(ref.watch(demoStoreProvider))
    : ApiAuthRepository(ref.watch(apiClientProvider), ref.watch(tokenStoreProvider)));

final propertyRepositoryProvider = Provider<PropertyRepository>((ref) =>
    kDemoMode ? DemoPropertyRepository(ref.watch(demoStoreProvider)) : ApiPropertyRepository(ref.watch(apiClientProvider)));

final roomRepositoryProvider = Provider<RoomRepository>((ref) =>
    kDemoMode ? DemoRoomRepository(ref.watch(demoStoreProvider)) : ApiRoomRepository(ref.watch(apiClientProvider)));

// No backend endpoints yet: always the demo implementations.
final issueRepositoryProvider = Provider<IssueRepository>((ref) => DemoIssueRepository(ref.watch(demoStoreProvider)));

final notificationRepositoryProvider =
    Provider<NotificationRepository>((ref) => DemoNotificationRepository(ref.watch(demoStoreProvider)));

final studentHomeRepositoryProvider =
    Provider<StudentHomeRepository>((ref) => DemoStudentHomeRepository(ref.watch(demoStoreProvider)));

/// Whose data the demo-backed repositories should show.
/// Demo mode: the signed-in demo user. API mode: the seeded landlord (Tom) or
/// student (Aisha), because real accounts don't exist in the demo store.
final actingUserIdProvider = Provider<int>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) throw StateError('No signed-in user');
  if (kDemoMode) return user.id;
  return user.isLandlord ? demoLandlordId : demoStudentId;
});
