import 'package:flutter/material.dart';

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
  final bool readOnly;
  final VoidCallback? onTap;

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
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? Colors.white70 : const Color(0xFF2C3E50);
    final fillColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? Colors.white12 : Colors.grey.shade300;
    final focusedColor = const Color(0xFFFF8C00);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: labelColor,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType ?? const TextInputType.numberWithOptions(decimal: true),
          onChanged: onChanged,
          readOnly: readOnly,
          onTap: onTap,
          style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1E293B),
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDark ? Colors.white38 : Colors.grey.shade400,
              fontSize: 14,
            ),
            helperText: helperText,
            helperStyle: TextStyle(
              color: isDark ? Colors.white54 : Colors.grey.shade600,
              fontSize: 12,
            ),
            prefixIcon: prefixIcon != null
                ? Icon(
                    prefixIcon,
                    color: isDark ? const Color(0xFFFFA726) : const Color(0xFF1E3A5F),
                    size: 20,
                  )
                : null,
            suffix: suffix != null
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      suffix!,
                      style: TextStyle(
                        color: isDark ? const Color(0xFFFFA726) : const Color(0xFF1E3A5F),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  )
                : null,
            suffixIcon: suffixWidget,
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
              borderSide: BorderSide(color: focusedColor, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}
