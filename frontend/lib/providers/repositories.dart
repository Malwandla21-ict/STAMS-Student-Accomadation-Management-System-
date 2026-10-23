import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config.dart';
import '../data/api_client.dart';
import '../data/demo/demo_repositories.dart';
import '../data/demo/demo_store.dart';
import '../data/repositories.dart';
import '../data/token_store.dart';
import 'auth.dart';

/// Backs every repository in demo mode (--dart-define=STAMS_DEMO=true).
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

final issueRepositoryProvider = Provider<IssueRepository>((ref) =>
    kDemoMode ? DemoIssueRepository(ref.watch(demoStoreProvider)) : ApiIssueRepository(ref.watch(apiClientProvider)));

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) => kDemoMode
    ? DemoNotificationRepository(ref.watch(demoStoreProvider))
    : ApiNotificationRepository(ref.watch(apiClientProvider)));

final studentHomeRepositoryProvider = Provider<StudentHomeRepository>((ref) => kDemoMode
    ? DemoStudentHomeRepository(ref.watch(demoStoreProvider))
    : ApiStudentHomeRepository(ref.watch(apiClientProvider)));

/// The signed-in user's id. Lists depend on it so they refetch when the account changes.
final actingUserIdProvider = Provider<int>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) throw StateError('No signed-in user');
  return user.id;
});
