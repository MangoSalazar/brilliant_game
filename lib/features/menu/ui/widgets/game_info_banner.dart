import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

/// Barra informativa compacta que muestra los parámetros y reglas destacadas del juego.
class GameInfoBanner extends StatelessWidget {
  const GameInfoBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF141728).withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF222845),
          width: 1.1,
        ),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceAround,
        runAlignment: WrapAlignment.center,
        spacing: 20,
        runSpacing: 12,
        children: const [
          _InfoItem(
            icon: FontAwesomeIcons.trophy,
            color: Color(0xFFF59E0B),
            title: 'Meta de Victoria',
            value: '21+ Puntos',
          ),
          _InfoItem(
            icon: FontAwesomeIcons.users,
            color: Color(0xFF38BDF8),
            title: 'Capacidad por Sala',
            value: 'Hasta 6 Jugadores',
          ),
          _InfoItem(
            icon: FontAwesomeIcons.diceD6,
            color: Color(0xFFA855F7),
            title: 'Tirada de Ronda',
            value: '2 Dados Globales',
          ),
          _InfoItem(
            icon: FontAwesomeIcons.mapLocationDot,
            color: Color(0xFF10B981),
            title: 'Mapas de Juego',
            value: '4 Prediseñados',
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final FaIconData icon;
  final Color color;
  final String title;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Center(
            child: FaIcon(
              icon,
              color: color,
              size: 14,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF64748B),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
