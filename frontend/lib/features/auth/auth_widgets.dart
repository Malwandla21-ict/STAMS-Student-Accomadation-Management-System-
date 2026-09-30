import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

String? validateEmail(String? v) {
  final value = v?.trim() ?? '';
  if (value.isEmpty) return 'Enter your email';
  if (!_emailPattern.hasMatch(value)) return 'Enter a valid email address';
  return null;
}

/// Password field with the show/hide eye.
class PasswordField extends StatefulWidget {
  const PasswordField({super.key, required this.controller, this.validator, this.label = 'Password', this.onSubmitted, this.autofillHints});

  final TextEditingController controller;
  final String? Function(String?)? validator;
  final String label;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) => TextFormField(
        controller: widget.controller,
        obscureText: _obscure,
        validator: widget.validator,
        autofillHints: widget.autofillHints,
        onFieldSubmitted: widget.onSubmitted,
        textInputAction: widget.onSubmitted == null ? TextInputAction.next : TextInputAction.done,
        decoration: InputDecoration(
          labelText: widget.label,
          prefixIcon: const Icon(Symbols.lock_rounded, size: 22),
          suffixIcon: IconButton(
            tooltip: _obscure ? 'Show password' : 'Hide password',
            icon: Icon(_obscure ? Symbols.visibility_rounded : Symbols.visibility_off_rounded, size: 22),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
        ),
      );
}

/// Inline form error from the server ("Incorrect email or password").
class FormErrorBanner extends StatelessWidget {
  const FormErrorBanner(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(color: AppColors.errorContainer, borderRadius: BorderRadius.circular(AppRadius.medium)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Symbols.error_rounded, size: 20, color: AppColors.onErrorContainer),
              const SizedBox(width: 10),
              Expanded(
                child: Text(message, style: const TextStyle(fontSize: 14, height: 20 / 14, color: AppColors.onErrorContainer)),
              ),
            ],
          ),
        ),
      );
}
