import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class InputField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final String? suffix;
  final Widget? suffixWidget;
  final IconData? prefixIcon;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final String? helperText;
  final String? errorText;
  final bool readOnly;
  final VoidCallback? onTap;
  final bool showClearButton;

  const InputField({
    super.key,
    required this.label,
    required this.hint,
    required this.controller,
    this.suffix,
    this.suffixWidget,
    this.prefixIcon,
    this.keyboardType,
    this.onChanged,
    this.helperText,
    this.errorText,
    this.readOnly = false,
    this.onTap,
    this.showClearButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B);
    final fillColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : const Color(0xFFE2E8F0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: labelColor,
                letterSpacing: 0.1,
              ),
            ),
            if (suffix != null && suffixWidget == null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFFFF8C00).withValues(alpha: 0.15)
                      : const Color(0xFF1E3A5F).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  suffix!,
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFFFFA726)
                        : const Color(0xFF1E3A5F),
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 7),
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, child) {
            final hasText = value.text.isNotEmpty;

            return TextField(
              controller: controller,
              keyboardType: keyboardType ??
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: onChanged,
              readOnly: readOnly,
              onTap: onTap,
              style: TextStyle(
                color: isDark ? Colors.white : AppColors.textDark,
                fontSize: 15.5,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: TextStyle(
                  color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                  fontSize: 14,
                  fontWeight: FontWeight.normal,
                ),
                helperText: helperText,
                helperMaxLines: 2,
                helperStyle: TextStyle(
                  color: isDark ? Colors.white54 : const Color(0xFF64748B),
                  fontSize: 11.5,
                ),
                errorText: errorText,
                prefixIcon: prefixIcon != null
                    ? Icon(
                        prefixIcon,
                        color: isDark
                            ? const Color(0xFFFFA726)
                            : const Color(0xFF1E3A5F),
                        size: 20,
                      )
                    : null,
                suffixIcon: suffixWidget ??
                    (showClearButton && hasText && !readOnly
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 18),
                            color: isDark ? Colors.white38 : Colors.grey.shade500,
                            splashRadius: 18,
                            onPressed: () {
                              controller.clear();
                              onChanged?.call('');
                            },
                          )
                        : null),
                filled: true,
                fillColor: fillColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: AppColors.accent,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.error),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
