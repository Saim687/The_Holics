import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:the_holics/core/router/app_routes.dart';
import 'package:the_holics/core/theme/app_theme.dart';

class HolicsBottomNav extends StatelessWidget {
  final int currentIndex;

  const HolicsBottomNav({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    if (!isMobile) return const SizedBox.shrink();

    return BottomNavigationBar(
      currentIndex: currentIndex,
      selectedItemColor: AppTheme.bodyHolicsOrange,
      unselectedItemColor: AppTheme.textSecondary,
      backgroundColor: AppTheme.surfaceCard,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.fitness_center),
          label: 'Body',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.spa),
          label: 'Skin',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
      onTap: (index) {
        if (index == currentIndex) return;
        if (index == 0) {
          context.go(AppRoutes.home);
        } else if (index == 1) {
          context.go(AppRoutes.bodyHolics);
        } else if (index == 2) {
          context.go(AppRoutes.skinHolics);
        } else if (index == 3) {
          context.go(AppRoutes.profile);
        }
      },
    );
  }
}