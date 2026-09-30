import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/auth/sign_in_screen.dart';
import 'features/auth/sign_up_screen.dart';
import 'features/auth/splash_screen.dart';
import 'features/landlord/assign_student_screen.dart';
import 'features/landlord/dashboard_screen.dart';
import 'features/landlord/issue_detail_screen.dart';
import 'features/landlord/issues_screen.dart';
import 'features/landlord/properties_screen.dart';
import 'features/landlord/property_detail_screen.dart';
import 'features/landlord/property_form_screen.dart';
import 'features/landlord/room_detail_screen.dart';
import 'features/landlord/room_form_screen.dart';
import 'features/shared/alerts_screen.dart';
import 'features/shared/profile_screen.dart';
import 'features/shared/shell.dart';
import 'features/student/my_issues_screen.dart';
import 'features/student/report_screens.dart';
import 'features/student/student_home_screen.dart';
import 'features/student/student_issue_screen.dart';
import 'models/enums.dart';
import 'providers/auth.dart';

/// Route paths in one place so screens never hard-code strings.
abstract final class Routes {
  static const splash = '/splash';
  static const signIn = '/sign-in';
  static const signUp = '/sign-up';

  static const landlord = '/landlord';
  static const landlordIssues = '/landlord/issues';
  static const landlordProperties = '/landlord/properties';
  static const landlordAlerts = '/landlord/alerts';
  static const landlordProfile = '/landlord/profile';
  static String landlordIssue(int id) => '/landlord/issue/$id';
  static const newProperty = '/landlord/property/new';
  static String property(int id) => '/landlord/property/$id';
  static String editProperty(int id) => '/landlord/property/$id/edit';
  static String newRoom(int propertyId) => '/landlord/property/$propertyId/room/new';
  static String room(int id) => '/landlord/room/$id';
  static String editRoom(int id) => '/landlord/room/$id/edit';
  static String assignStudent(int roomId) => '/landlord/room/$roomId/assign';

  static const student = '/student';
  static const studentIssues = '/student/issues';
  static const studentAlerts = '/student/alerts';
  static const studentProfile = '/student/profile';
  static const report = '/student/report';
  static const reportDetails = '/student/report/details';
  static String reportDone(int id) => '/student/report/done/$id';
  static String studentIssue(int id) => '/student/issue/$id';
}

final _rootKey = GlobalKey<NavigatorState>();

int _id(GoRouterState s, [String name = 'id']) => int.parse(s.pathParameters[name]!);

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen(authControllerProvider, (_, _) => refresh.value++);
  ref.onDispose(refresh.dispose);

  GoRoute page(String path, Widget Function(GoRouterState s) build) =>
      GoRoute(path: path, parentNavigatorKey: _rootKey, builder: (context, s) => build(s));

  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      final loc = state.matchedLocation;
      // Still checking the saved session (or couldn't reach the server): stay on the splash.
      if (!auth.hasValue) return loc == Routes.splash ? null : Routes.splash;

      final user = auth.value;
      final atAuth = loc == Routes.signIn || loc == Routes.signUp;
      if (user == null) return atAuth ? null : Routes.signIn;

      final home = user.role == Role.landlord ? Routes.landlord : Routes.student;
      if (atAuth || loc == Routes.splash || !loc.startsWith(home)) return home;
      return null;
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: Routes.signIn, builder: (_, _) => const SignInScreen()),
      GoRoute(path: Routes.signUp, builder: (_, _) => const SignUpScreen()),

      // Landlord: bottom nav Dashboard · Issues · Properties · Alerts · Profile
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => RoleShell(shell: shell, role: Role.landlord),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: Routes.landlord, builder: (_, _) => const DashboardScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.landlordIssues, builder: (_, _) => const IssuesScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.landlordProperties, builder: (_, _) => const PropertiesScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.landlordAlerts, builder: (_, _) => const AlertsScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.landlordProfile, builder: (_, _) => const ProfileScreen())]),
        ],
      ),
      page('/landlord/issue/:id', (s) => IssueDetailScreen(issueId: _id(s))),
      page(Routes.newProperty, (_) => const PropertyFormScreen()),
      page('/landlord/property/:id', (s) => PropertyDetailScreen(propertyId: _id(s))),
      page('/landlord/property/:id/edit', (s) => PropertyFormScreen(propertyId: _id(s))),
      page('/landlord/property/:id/room/new', (s) => RoomFormScreen(propertyId: _id(s))),
      page('/landlord/room/:id', (s) => RoomDetailScreen(roomId: _id(s))),
      page('/landlord/room/:id/edit', (s) => RoomFormScreen(roomId: _id(s))),
      page('/landlord/room/:id/assign', (s) => AssignStudentScreen(roomId: _id(s))),

      // Student: bottom nav Home · My issues · Alerts · Profile
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => RoleShell(shell: shell, role: Role.student),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: Routes.student, builder: (_, _) => const StudentHomeScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.studentIssues, builder: (_, _) => const MyIssuesScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.studentAlerts, builder: (_, _) => const AlertsScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.studentProfile, builder: (_, _) => const ProfileScreen())]),
        ],
      ),
      page(Routes.report, (_) => const ReportWhereScreen()),
      page(Routes.reportDetails, (_) => const ReportDetailsScreen()),
      page('/student/report/done/:id', (s) => ReportDoneScreen(issueId: _id(s))),
      page('/student/issue/:id', (s) => StudentIssueScreen(issueId: _id(s))),
    ],
  );
});
