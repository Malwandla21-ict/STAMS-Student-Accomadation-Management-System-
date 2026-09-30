import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      // Screens show their own error + "Try again"; don't retry silently in the background.
      retry: (retryCount, error) => null,
      child: const StamsApp(),
    ),
  );
}
