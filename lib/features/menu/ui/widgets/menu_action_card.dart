import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Tarjeta interactiva de acción principal del Menú ("Crear Partida" o "Unirse a Partida").
class MenuActionCard extends StatefulWidget {
  final Key? cardKey;
  final String title;
  final String subtitle;
  final String? badgeText;
  final FaIconData icon;
  final FaIconData buttonIcon;
  final String buttonText;
  final List<Color> gradientColors;
  final VoidCallback onTap;

  const MenuActionCard({
    super.key,
    this.cardKey,
    required this.title,
    required this.subtitle,
    this.badgeText,
    required this.icon,
    required this.buttonIcon,
    required this.buttonText,
    required this.gradientColors,
    required this.onTap,
  });

  @override
  State<MenuActionCard> createState() => _MenuActionCardState();
}

class _MenuActionCardState extends State<MenuActionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final primaryAccent = widget.gradientColors.first;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        key: widget.cardKey,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF141728),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isHovered
                  ? primaryAccent.withValues(alpha: 0.8)
                  : const Color(0xFF222845),
              width: _isHovered ? 1.8 : 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              if (_isHovered)
                BoxShadow(
                  color: primaryAccent.withValues(alpha: 0.25),
                  blurRadius: 28,
                  offset: const Offset(0, 6),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Icono con contenedor de degradado
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: widget.gradientColors,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: primaryAccent.withValues(alpha: 0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: FaIcon(
                        widget.icon,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),

                  // Badge opcional (ej. "Game Master" o "5 Dígitos")
                  if (widget.badgeText != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: primaryAccent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: primaryAccent.withValues(alpha: 0.4),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        widget.badgeText!,
                        style: TextStyle(
                          color: primaryAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),

              // Título
              Text(
                widget.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),

              // Subtítulo
              Text(
                widget.subtitle,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),

              // Botón estilizado inferior
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: widget.gradientColors,
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: primaryAccent.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FaIcon(
                      widget.buttonIcon,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.buttonText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
