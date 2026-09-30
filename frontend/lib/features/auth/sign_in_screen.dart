import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../config.dart';
import '../../data/api_client.dart';
import '../../data/demo/demo_store.dart';
import '../../providers/auth.dart';
import '../../router.dart';
import '../../theme/app_colors.dart';
import '../../widgets/buttons.dart';
import '../../widgets/common.dart';
import '../../widgets/stams_logo.dart';
import 'auth_widgets.dart';

/// A2 - email + password.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_form.currentState!.validate()) return;
    setState(() => _busy = true);
    try {
      await ref.read(authControllerProvider.notifier).signIn(email: _email.text, password: _password.text);
      // The router redirects to the role's home.
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.isUnauthorized ? 'Incorrect email or password.' : e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _fillDemo(String email) {
    _email.text = email;
    _password.text = demoPassword;
    _submit();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: Form(
          key: _form,
          child: AutofillGroup(
            child: CustomScrollView(
              slivers: [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 40, 20, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Align(alignment: Alignment.centerLeft, child: StamsMark(size: 56)),
                        const SizedBox(height: 20),
                        Text('Welcome back', style: t.headlineMedium),
                        const SizedBox(height: 8),
                        Text('Sign in to manage your rooms and repairs.',
                            style: t.bodyLarge!.copyWith(color: AppColors.onSurfaceVariant)),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          autofillHints: const [AutofillHints.email],
                          textInputAction: TextInputAction.next,
                          validator: validateEmail,
                          decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Symbols.mail_rounded, size: 22)),
                        ),
                        const SizedBox(height: 16),
                        PasswordField(
                          controller: _password,
                          autofillHints: const [AutofillHints.password],
                          validator: (v) => (v ?? '').isEmpty ? 'Enter your password' : null,
                          onSubmitted: (_) => _submit(),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: InlineAction(
                            'Forgot password?',
                            onPressed: () => showMessage(context, 'Password reset isn’t available yet - ask STAMS support.'),
                          ),
                        ),
                        if (_error != null) ...[const SizedBox(height: 8), FormErrorBanner(_error!)],
                        const SizedBox(height: 24),
                        BigButton(label: 'Sign in', loading: _busy, onPressed: _submit),
                        if (kDemoMode) ...[const SizedBox(height: 24), _DemoAccounts(onPick: _fillDemo)],
                        const Spacer(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('New to STAMS?', style: t.bodyMedium!.copyWith(color: AppColors.onSurfaceVariant)),
                            TextButton(onPressed: () => context.go(Routes.signUp), child: const Text('Create an account')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Demo mode only: one tap signs in as a seeded account.
class _DemoAccounts extends StatelessWidget {
  const _DemoAccounts({required this.onPick});

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    final accounts = [
      ('Landlord · Tom', 'tom.hadley@hadleylets.co.uk', Symbols.apartment_rounded),
      ('Student · Aisha', 'aisha.bello@uni.ac.uk', Symbols.school_rounded),
      ('No room yet · Maya', 'maya.thomas@uni.ac.uk', Symbols.hourglass_top_rounded),
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: AppColors.tertiaryContainer, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Demo mode - sign in as',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.onTertiaryContainer)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (label, email, icon) in accounts)
                ActionChip(
                  avatar: Icon(icon, size: 18, color: AppColors.onTertiaryContainer),
                  label: Text(label),
                  backgroundColor: Colors.white,
                  side: BorderSide.none,
                  onPressed: () => onPick(email),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
