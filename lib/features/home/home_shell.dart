import 'package:flutter/material.dart';
import 'package:norigo/app/router.dart';
import 'package:norigo/core/localization/l10n_extension.dart';
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
    final l10n = context.l10n;
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
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            label: l10n.home,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.route_outlined),
            label: l10n.itinerary,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.center_focus_strong),
            label: l10n.scan,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.travel_explore),
            label: l10n.discover,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            label: l10n.my,
          ),
        ],
      ),
    );
  }
}
