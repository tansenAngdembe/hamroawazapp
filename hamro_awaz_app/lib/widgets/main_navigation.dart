import 'package:flutter/material.dart';

import '../core/constants/app_colors.dart';
import '../models/user.dart';
import '../screens/citizen/dashboard_screen.dart';
import '../screens/citizen/map_view_screen.dart';
import '../screens/citizen/my_complaints_screen.dart';
import '../screens/citizen/profile_screen.dart';

/// Bottom navigation with **lazy** tab bodies so Google Maps / geolocation / API
/// are not all started at once (prevents startup OOM and native map crashes).
class MainNavigation extends StatefulWidget {
  final User user;

  const MainNavigation({super.key, required this.user});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final Map<int, Widget> _tabCache = {};

  Widget _tabForIndex(int index) {
    return _tabCache.putIfAbsent(index, () {
      switch (index) {
        case 0:
          return const DashboardScreen();
        case 1:
          return const MyComplaintsScreen();
        case 2:
          return const MapViewScreen();
        case 3:
          return ProfileScreen(user: widget.user);
        default:
          return const SizedBox.shrink();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabForIndex(_currentIndex),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          if (index == _currentIndex) return;
          setState(() => _currentIndex = index);
        },
        backgroundColor: Colors.white,
        indicatorColor: AppColors.primary.withValues(alpha: 0.1),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: 'Complaints',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
