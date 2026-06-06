import 'package:flutter/material.dart';
import 'package:norigo/app/router.dart';
import 'package:norigo/core/widgets/nori_bottom_navigation.dart';
import 'package:norigo/features/discover/discover_screen.dart';
import 'package:norigo/features/home/home_screen.dart';
import 'package:norigo/features/my/presentation/my_page_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, 4).toInt();
  }

  @override
  void didUpdateWidget(covariant HomeShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      _currentIndex = widget.initialIndex.clamp(0, 4).toInt();
    }
  }

  void _selectTab(int index) {
    if (index == 0) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
      return;
    }

    if (index == 1) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.itinerary);
      return;
    }

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
      const SizedBox.shrink(),
      const SizedBox.shrink(),
      const DiscoverScreen(),
      const MyPageScreen(showBottomNavigation: false),
    ];

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: NoriBottomNavigation(
        currentIndex: _currentIndex,
        onChanged: _selectTab,
      ),
    );
  }
}
