import 'package:flutter/material.dart';

typedef NavCallback = void Function();

class CustomBottomNav extends StatelessWidget {
  final bool centerOn; // ON/OFF state for the central button
  final ValueChanged<bool>? onCenterToggle;
  final NavCallback? onHistory;
  final NavCallback? onMessage;
  final NavCallback? onReservations;
  final NavCallback? onOffers;
  final int offersBadgeCount;

  const CustomBottomNav({
    super.key,
    required this.centerOn,
    this.onCenterToggle,
    this.onHistory,
    this.onMessage,
    this.onReservations,
    this.onOffers,
    this.offersBadgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    // Height of the bottom bar
    const double barHeight = 72;
    return SizedBox(
      height: barHeight + 36, // leave room for the floating hex button
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // The bottom bar background
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: barHeight,
              decoration: BoxDecoration(
                color: Colors.black,
                boxShadow: [
                  BoxShadow(
                    color: const Color.fromRGBO(0, 0, 0, 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _navItem(
                      icon: Icons.history,
                      label: 'Historial',
                      onTap: onHistory,
                    ),
                    _navItem(
                      icon: Icons.message,
                      label: 'Mensaje',
                      onTap: onMessage,
                    ),
                    // spacer for central button
                    const SizedBox(width: 64),
                    _navItem(
                      icon: Icons.calendar_today,
                      label: 'Reservas',
                      onTap: onReservations,
                    ),
                    _navItem(
                      icon: Icons.local_offer,
                      label: 'Ofertas',
                      onTap: onOffers,
                      badgeCount: offersBadgeCount,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Center hexagon button (floating above the bar)
          Positioned(
            bottom: barHeight - 20, // adjust the overlap
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: () {
                  if (onCenterToggle != null) onCenterToggle!(!centerOn);
                },
                child: HexagonButton(
                  text: centerOn ? 'ON' : 'OFF',
                  color: centerOn
                      ? Colors.greenAccent.shade400
                      : Colors.redAccent.shade700,
                  label: centerOn ? 'Activo' : 'Ocupado',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required String label,
    NavCallback? onTap,
    int badgeCount = 0,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: Colors.white, size: 22),
                if (badgeCount > 0)
                  Positioned(
                    right: -10,
                    top: -8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.orange,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 4),
                        ],
                      ),
                      child: Text(
                        badgeCount > 99 ? '99+' : badgeCount.toString(),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Hexagon button implemented with ClipPath
class HexagonButton extends StatelessWidget {
  final Color color;
  final String text;
  final String label;
  const HexagonButton({
    super.key,
    required this.color,
    required this.text,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    // hexagon size
    const double size = 84.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipPath(
          clipper: _HexagonClipper(),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: color,
              boxShadow: [
                BoxShadow(
                  color: const Color.fromRGBO(0, 0, 0, 0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _HexagonClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path path = Path();
    final double w = size.width;
    final double h = size.height;
    final double side = w / 2;
    // Simple regular hexagon centered
    final dx = w * 0.25;
    path.moveTo(dx, 0);
    path.lineTo(dx + side, 0);
    path.lineTo(w, h * 0.5);
    path.lineTo(dx + side, h);
    path.lineTo(dx, h);
    path.lineTo(0, h * 0.5);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
