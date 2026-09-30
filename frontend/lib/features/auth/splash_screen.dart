import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config.dart';
import '../../data/api_client.dart';
import '../../providers/auth.dart';
import '../../theme/app_colors.dart';
import '../../widgets/stams_logo.dart';

/// A1 - shown while the saved session is checked.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final error = auth.hasError ? ApiException.from(auth.error!) : null;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent, systemNavigationBarColor: AppColors.navy),
      child: Scaffold(
        backgroundColor: AppColors.navy,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const StamsMark(size: 104, barColor: AppColors.chalk),
                    const SizedBox(height: 22),
                    const StamsWordmark(height: 38, color: AppColors.chalk),
                    const SizedBox(height: 12),
                    Text(
                      'STUDENT ACCOMMODATION\nMANAGEMENT SYSTEM',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall!.copyWith(
                            color: AppColors.onNavySoft,
                            letterSpacing: 11 * 0.16,
                            height: 16 / 11,
                          ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 28),
                child: error == null
                    ? const Column(children: [
                        SizedBox.square(
                          dimension: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: AppColors.brandIris,
                            backgroundColor: Color(0x33F5F3EC),
                          ),
                        ),
                        SizedBox(height: 14),
                        Text('v$kAppVersion', style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: Color(0xFF9FB0C1))),
                      ])
                    : Column(children: [
                        Text(
                          error.message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.chalk, fontSize: 14, height: 20 / 14),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => ref.read(authControllerProvider.notifier).retry(),
                          style: FilledButton.styleFrom(backgroundColor: AppColors.chalk, foregroundColor: AppColors.navy),
                          child: const Text('Try again'),
                        ),
                      ]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
