import 'package:flutter/material.dart';
import 'package:mobile/l10n/app_localizations.dart';
import '../../core/theme/app_colors.dart';
import 'mizan_text_field.dart';

enum PasswordStrength { none, weak, medium, strong }

class MizanPasswordField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final bool showStrengthMeter;
  final TextInputAction? textInputAction;

  const MizanPasswordField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.validator,
    this.onChanged,
    this.showStrengthMeter = false,
    this.textInputAction,
  });

  @override
  State<MizanPasswordField> createState() => _MizanPasswordFieldState();
}

class _MizanPasswordFieldState extends State<MizanPasswordField> {
  bool _obscureText = true;
  PasswordStrength _strength = PasswordStrength.none;

  PasswordStrength _evaluateStrength(String password) {
    if (password.isEmpty) return PasswordStrength.none;
    if (password.length < 6) return PasswordStrength.weak;

    int score = 0;
    if (password.length >= 8) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[A-Za-z]').hasMatch(password)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) score++;

    if (score >= 3 && password.length >= 8) return PasswordStrength.strong;
    if (score >= 2) return PasswordStrength.medium;
    return PasswordStrength.weak;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MizanTextField(
          controller: widget.controller,
          label: widget.label ?? l10n.password,
          hint: widget.hint ?? '••••••••',
          obscureText: _obscureText,
          textInputAction: widget.textInputAction,
          prefixIcon: const Icon(Icons.lock_outline, size: 20),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
              size: 20,
              color: Colors.grey,
            ),
            onPressed: () {
              setState(() {
                _obscureText = !_obscureText;
              });
            },
          ),
          validator: widget.validator,
          onChanged: (val) {
            if (widget.showStrengthMeter) {
              setState(() {
                _strength = _evaluateStrength(val);
              });
            }
            widget.onChanged?.call(val);
          },
        ),
        if (widget.showStrengthMeter && _strength != PasswordStrength.none) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildBar(1)),
              const SizedBox(width: 4),
              Expanded(child: _buildBar(2)),
              const SizedBox(width: 4),
              Expanded(child: _buildBar(3)),
              const SizedBox(width: 12),
              Text(
                _getStrengthLabel(l10n),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _getStrengthColor(),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildBar(int level) {
    bool active = false;
    if (_strength == PasswordStrength.weak && level == 1) active = true;
    if (_strength == PasswordStrength.medium && level <= 2) active = true;
    if (_strength == PasswordStrength.strong && level <= 3) active = true;

    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: active ? _getStrengthColor() : Colors.grey.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  Color _getStrengthColor() {
    switch (_strength) {
      case PasswordStrength.strong:
        return AppColors.accentBrightGreen;
      case PasswordStrength.medium:
        return AppColors.warningAmber;
      case PasswordStrength.weak:
      case PasswordStrength.none:
        return AppColors.dangerRed;
    }
  }

  String _getStrengthLabel(AppLocalizations l10n) {
    switch (_strength) {
      case PasswordStrength.strong:
        return l10n.strong;
      case PasswordStrength.medium:
        return l10n.medium;
      case PasswordStrength.weak:
      case PasswordStrength.none:
        return l10n.weak;
    }
  }
}
