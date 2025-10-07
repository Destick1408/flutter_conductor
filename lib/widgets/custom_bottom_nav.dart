import 'package:flutter/material.dart';

class SimpleBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int offersBadgeCount;
  final Color backgroundColor;
  final Color selectedColor;
  final Color unselectedColor;

  const SimpleBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.offersBadgeCount = 0,
    this.backgroundColor = Colors.black,
    this.selectedColor = Colors.yellowAccent,
    this.unselectedColor = Colors.white70,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTap,
      type: BottomNavigationBarType.fixed,
      backgroundColor: backgroundColor,
      selectedItemColor: selectedColor,
      unselectedItemColor: unselectedColor,
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.history),
          label: 'Historial',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.message),
          label: 'Mensaje',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.calendar_today),
          label: 'Reservas',
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.local_offer),
          label: 'Ofertas',
        ),
      ],
    );
  }
}
