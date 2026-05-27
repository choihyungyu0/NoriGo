import 'package:flutter/material.dart';
import 'package:norigo/app/router.dart';
import 'package:norigo/features/discover/discover_screen.dart';
import 'package:norigo/features/home/home_screen.dart';
import 'package:norigo/features/itinerary/itinerary_screen.dart';
import 'package:norigo/features/profile/profile_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  void _selectTab(int index) {
    if (index == 2) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.scan);
      return;
    }

    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        onSelectTab: _selectTab,
        onOpenCrowdAlert: () =>
            Navigator.of(context).pushNamed(AppRoutes.itineraryCrowdAlert),
      ),
      const ItineraryScreen(),
      const SizedBox.shrink(),
      const DiscoverScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _selectTab,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.route_outlined),
            label: 'Itinerary',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.center_focus_strong),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.travel_explore),
            label: 'Discover',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: 'My',
          ),
        ],
      ),
    );
  }
}
