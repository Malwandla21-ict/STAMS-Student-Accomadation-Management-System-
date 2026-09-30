import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../data/api_client.dart';
import '../../models/enums.dart';
import '../../providers/auth.dart';
import '../../router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/buttons.dart';
import '../../widgets/common.dart';
import 'auth_widgets.dart';

/// A3 - choose Landlord or Student, then name / email / password.
class SignUpScreen extends ConsumerStatefulWidget {
  const SignUpScreen({super.key});

  @override
  ConsumerState<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends ConsumerState<SignUpScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  Role? _role;
  bool _busy = false;
  bool _roleMissing = false;
  String? _error;
  Map<String, String> _fieldErrors = const {};

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _fieldErrors = const {};
      _roleMissing = _role == null;
    });
    final valid = _form.currentState!.validate();
    if (!valid || _role == null) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(authControllerProvider.notifier)
          .signUp(name: _name.text, email: _email.text, password: _password.text, role: _role!);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _fieldErrors = e.fieldErrors;
          _error = e.fieldErrors.isEmpty ? e.message : null;
        });
        _form.currentState!.validate();
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final cta = switch (_role) {
      Role.student => 'Create student account',
      Role.landlord => 'Create landlord account',
      null => 'Create account',
    };
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Symbols.arrow_back_rounded),
          onPressed: () => context.go(Routes.signIn),
        ),
        title: const Text('Create account'),
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Text('I am a…', style: t.titleMedium),
            const SizedBox(height: 12),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _RoleCard(
                      icon: Symbols.apartment_rounded,
                      title: 'Landlord',
                      subtitle: 'I own or manage student rooms',
                      selected: _role == Role.landlord,
                      onTap: () => setState(() {
                        _role = Role.landlord;
                        _roleMissing = false;
                      }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _RoleCard(
                      icon: Symbols.school_rounded,
                      title: 'Student',
                      subtitle: 'I live in a student room',
                      selected: _role == Role.student,
                      onTap: () => setState(() {
                        _role = Role.student;
                        _roleMissing = false;
                      }),
                    ),
                  ),
                ],
              ),
            ),
            if (_roleMissing)
              const Padding(
                padding: EdgeInsets.fromLTRB(4, 8, 4, 0),
                child: Text('Choose Landlord or Student', style: TextStyle(fontSize: 12, color: AppColors.error)),
              ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              validator: (v) => (v ?? '').trim().isEmpty ? 'Enter your full name' : _fieldErrors['name'],
              decoration: const InputDecoration(labelText: 'Full name', prefixIcon: Icon(Symbols.person_rounded, size: 22)),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: (v) => validateEmail(v) ?? _fieldErrors['email'],
              decoration: InputDecoration(
                labelText: 'Email',
                prefixIcon: const Icon(Symbols.mail_rounded, size: 22),
                helperText: _role == Role.student ? 'Your landlord finds you by this email to add you to a room.' : null,
                helperMaxLines: 2,
              ),
            ),
            const SizedBox(height: 16),
            PasswordField(
              controller: _password,
              autofillHints: const [AutofillHints.newPassword],
              validator: (v) {
                final len = (v ?? '').length;
                if (len < 8 || len > 72) return 'Use 8 to 72 characters';
                return _fieldErrors['password'];
              },
              onSubmitted: (_) => _submit(),
            ),
            if (_error != null) ...[const SizedBox(height: 16), FormErrorBanner(_error!)],
            const SizedBox(height: 24),
            BigButton(label: cta, loading: _busy, onPressed: _submit),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Already have an account?', style: t.bodyMedium!.copyWith(color: AppColors.onSurfaceVariant)),
                TextButton(onPressed: () => context.go(Routes.signIn), child: const Text('Sign in')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.icon, required this.title, required this.subtitle, required this.selected, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? AppColors.onPrimaryContainer : AppColors.onSurface;
    return Semantics(
      selected: selected,
      inMutuallyExclusiveGroup: true,
      button: true,
      child: Material(
        color: selected ? AppColors.primaryContainer : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.large),
          side: BorderSide(color: selected ? AppColors.primary : AppColors.outlineVariant, width: selected ? 2 : 1),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.large),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 132),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primary : AppColors.surfaceContainer,
                          borderRadius: BorderRadius.circular(AppRadius.medium),
                        ),
                        child: Icon(icon, color: selected ? Colors.white : AppColors.primary),
                      ),
                      const Spacer(),
                      RadioDot(selected: selected),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(title, style: Theme.of(context).textTheme.titleMedium!.copyWith(color: fg)),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, height: 18 / 13, color: selected ? fg : AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
