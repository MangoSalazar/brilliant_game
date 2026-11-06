import 'package:flutter/material.dart';

class BrilliantTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData prefixIcon;
  final bool obscureText;
  final bool isPassword;
  final VoidCallback? onToggleVisibility;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;

  const BrilliantTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hintText,
    required this.prefixIcon,
    this.obscureText = false,
    this.isPassword = false,
    this.onToggleVisibility,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFB0B7C3),
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF16192E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFF282E4E),
              width: 1.2,
            ),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            enabled: enabled,
            textInputAction: textInputAction,
            onSubmitted: onSubmitted,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: const TextStyle(
                color: Color(0xFF555E75),
                fontSize: 14,
              ),
              prefixIcon: Icon(
                prefixIcon,
                color: const Color(0xFF6B7280),
                size: 20,
              ),
              suffixIcon: isPassword
                  ? IconButton(
                      icon: Icon(
                        obscureText ? Icons.visibility_off : Icons.visibility,
                        color: const Color(0xFF6B7280),
                        size: 20,
                      ),
                      onPressed: onToggleVisibility,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
