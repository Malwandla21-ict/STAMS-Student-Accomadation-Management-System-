import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../models/enums.dart';
import '../../providers/data.dart';
import '../../theme/app_colors.dart';

/// Bottom navigation scaffold for both roles. M3 NavigationBar, 80dp,
/// active indicator = primaryContainer, badges = error.
class RoleShell extends ConsumerWidget {
  const RoleShell({super.key, required this.shell, required this.role});

  final StatefulNavigationShell shell;
  final Role role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(unreadAlertCountProvider);
    final issuesBadge = role == Role.landlord ? ref.watch(nudgedOpenIssueCountProvider) : 0;

    final items = role == Role.landlord
        ? [
            (Symbols.space_dashboard_rounded, 'Dashboard', 0),
            (Symbols.handyman_rounded, 'Issues', issuesBadge),
            (Symbols.apartment_rounded, 'Properties', 0),
            (Symbols.notifications_rounded, 'Alerts', alerts),
            (Symbols.account_circle_rounded, 'Profile', 0),
          ]
        : [
            (Symbols.home_rounded, 'Home', 0),
            (Symbols.handyman_rounded, 'My issues', 0),
            (Symbols.notifications_rounded, 'Alerts', alerts),
            (Symbols.account_circle_rounded, 'Profile', 0),
          ];

    return Scaffold(
      body: shell,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.surfaceHighest))),
        child: NavigationBar(
          selectedIndex: shell.currentIndex,
          // Tapping the current tab pops it back to its root.
          onDestinationSelected: (i) => shell.goBranch(i, initialLocation: i == shell.currentIndex),
          destinations: [
            for (final (icon, label, badge) in items)
              NavigationDestination(
                icon: _BadgedIcon(icon: icon, badge: badge, filled: false),
                selectedIcon: _BadgedIcon(icon: icon, badge: badge, filled: true),
                label: label,
                tooltip: badge > 0 ? '$label, $badge new' : label,
              ),
          ],
        ),
      ),
    );
  }
}

class _BadgedIcon extends StatelessWidget {
  const _BadgedIcon({required this.icon, required this.badge, required this.filled});

  final IconData icon;
  final int badge;
  final bool filled;

  // A small iris dot rather than a red number: it says "something new" without nagging.
  // The count is still in the destination's tooltip / screen-reader label.
  @override
  Widget build(BuildContext context) => Badge(
        isLabelVisible: badge > 0,
        smallSize: 8,
        backgroundColor: AppColors.tertiary,
        offset: const Offset(2, -2),
        child: Icon(icon, fill: filled ? 1 : 0),
      );
}
