import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../config.dart';
import '../../providers/auth.dart';
import '../../providers/data.dart';
import '../../theme/app_colors.dart';
import '../../utils/format.dart';
import '../../widgets/common.dart';

/// A6 - account, notification preferences, sign out.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // Local only until the backend stores notification preferences.
  bool _primaryAlerts = true;
  bool _digest = false;

  void _notYet(String what) => showMessage(context, '$what isn’t available yet');

  Future<void> _signOut() async {
    final ok = await confirm(context, title: 'Sign out?', message: 'You’ll need your email and password to sign back in.', action: 'Sign out');
    if (ok) await ref.read(authControllerProvider.notifier).signOut();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();
    final landlord = user.isLandlord;

    final String roleLabel;
    if (landlord) {
      final count = ref.watch(propertiesProvider).value?.length;
      roleLabel = count == null ? 'Landlord' : 'Landlord · ${Fmt.plural(count, 'property', 'properties')}';
    } else {
      final home = ref.watch(studentHomeProvider);
      roleLabel = !home.hasValue ? 'Student' : (home.value == null ? 'Student · No room yet' : 'Student · ${home.value!.room.name}');
    }

    Widget section(String title) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
          child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.onSurfaceVariant)),
        );
    Widget item(IconData icon, String label, {VoidCallback? onTap, Widget? trailing, Color? color}) => ListTile(
          leading: Icon(icon, color: color),
          title: Text(label, style: TextStyle(color: color, fontWeight: color == null ? null : FontWeight.w600)),
          trailing: trailing ?? (color == null ? const Icon(Symbols.chevron_right_rounded) : null),
          onTap: onTap,
        );
    Widget toggle(IconData icon, String label, String subtitle, bool value, ValueChanged<bool> onChanged) => SwitchListTile(
          secondary: Icon(icon, color: AppColors.onSurfaceVariant),
          title: Text(label),
          subtitle: Text(subtitle),
          value: value,
          onChanged: onChanged,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        );

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const PageHeader(title: 'Profile'),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: OutlinedCard(
              child: Row(children: [
                InitialsAvatar(user.initials, size: 64, background: AppColors.primary, foreground: Colors.white),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(user.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
                    const SizedBox(height: 4),
                    Text(user.email, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant)),
                    const SizedBox(height: 6),
                    SmallTag(label: roleLabel, icon: landlord ? Symbols.apartment_rounded : Symbols.school_rounded),
                  ]),
                ),
              ]),
            ),
          ),
          section('Account'),
          item(Symbols.edit_rounded, 'Edit profile', onTap: () => _notYet('Editing your profile')),
          item(Symbols.key_rounded, 'Change password', onTap: () => _notYet('Changing your password')),
          section('Notifications'),
          if (landlord) ...[
            toggle(Symbols.notifications_active_rounded, 'Nudge alerts', 'Push when a student nudges', _primaryAlerts,
                (v) => setState(() => _primaryAlerts = v)),
            toggle(Symbols.mail_rounded, 'Daily email digest', 'Open issues summary at 8:00', _digest, (v) => setState(() => _digest = v)),
          ] else ...[
            toggle(Symbols.notifications_active_rounded, 'Status updates', 'Push when your landlord updates an issue', _primaryAlerts,
                (v) => setState(() => _primaryAlerts = v)),
            toggle(Symbols.mail_rounded, 'Email updates', 'A copy of each update by email', _digest, (v) => setState(() => _digest = v)),
          ],
          section('App'),
          item(Symbols.contrast_rounded, 'Appearance',
              trailing: const Text('Light', style: TextStyle(fontSize: 14, color: AppColors.onSurfaceVariant)),
              onTap: () => _notYet('Dark mode')),
          item(Symbols.help_rounded, 'Help & feedback', onTap: () => _notYet('Help & feedback')),
          item(Symbols.logout_rounded, 'Sign out', color: AppColors.error, onTap: _signOut),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'STAMS v$kAppVersion${kDemoMode ? ' · Demo mode' : ''}',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12, color: AppColors.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
