import 'package:flutter/material.dart';
import '../../bloc/auth_state.dart';

class AuthTabs extends StatelessWidget {
  final AuthMode currentMode;
  final ValueChanged<AuthMode> onModeSelected;

  const AuthTabs({
    super.key,
    required this.currentMode,
    required this.onModeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF141728),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF282E4E),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              title: 'Iniciar Sesión',
              isSelected: currentMode == AuthMode.login,
              onTap: () => onModeSelected(AuthMode.login),
            ),
          ),
          Expanded(
            child: _TabButton(
              title: 'Crear Cuenta',
              isSelected: currentMode == AuthMode.register,
              onTap: () => onModeSelected(AuthMode.register),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final String title;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.title,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(0xFF7E8B9F),
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
