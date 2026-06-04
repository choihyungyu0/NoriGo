import 'package:flutter/material.dart';
import 'package:norigo/app/router.dart';
import 'package:norigo/core/localization/l10n_extension.dart';
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
    final l10n = context.l10n;
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
      bottomNavigationBar: _NoriBottomNavigation(
        currentIndex: _currentIndex,
        labels: [l10n.home, l10n.itinerary, l10n.scan, l10n.discover, l10n.my],
        onChanged: _selectTab,
      ),
    );
  }
}

class _NoriBottomNavigation extends StatelessWidget {
  const _NoriBottomNavigation({
    required this.currentIndex,
    required this.labels,
    required this.onChanged,
  });

  final int currentIndex;
  final List<String> labels;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE8E3F2))),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5E4D85).withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SizedBox(
        height: 88 + bottomPadding,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: 0,
              right: 0,
              top: 14,
              bottom: bottomPadding == 0 ? 10 : bottomPadding,
              child: Row(
                children: [
                  _BottomNavItem(
                    id: 'home',
                    icon: Icons.home_outlined,
                    label: labels[0],
                    selected: currentIndex == 0,
                    onTap: () => onChanged(0),
                  ),
                  _BottomNavItem(
                    id: 'itinerary',
                    icon: Icons.calendar_month_outlined,
                    label: labels[1],
                    selected: currentIndex == 1,
                    onTap: () => onChanged(1),
                  ),
                  const Expanded(child: SizedBox.shrink()),
                  _BottomNavItem(
                    id: 'discover',
                    icon: Icons.explore_rounded,
                    label: labels[3],
                    selected: currentIndex == 3,
                    onTap: () => onChanged(3),
                  ),
                  _BottomNavItem(
                    id: 'my',
                    icon: Icons.person_outline_rounded,
                    label: labels[4],
                    selected: currentIndex == 4,
                    onTap: () => onChanged(4),
                  ),
                ],
              ),
            ),
            Positioned(
              top: -18,
              left: 0,
              right: 0,
              child: Center(
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () => onChanged(2),
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFE8E3F2)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF5E4D85,
                          ).withValues(alpha: 0.18),
                          blurRadius: 22,
                          offset: const Offset(0, 9),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.center_focus_strong_rounded,
                      color: currentIndex == 2
                          ? const Color(0xFF5717D9)
                          : const Color(0xFF7A7F93),
                      size: 34,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 58,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  labels[2],
                  style: TextStyle(
                    color: currentIndex == 2
                        ? const Color(0xFF5717D9)
                        : const Color(0xFF7A7F93),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem extends StatelessWidget {
  const _BottomNavItem({
    required this.id,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String id;
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF5717D9) : const Color(0xFF7A7F93);
    return Expanded(
      child: InkWell(
        key: ValueKey(selected ? 'bottomNav-$id-selected' : 'bottomNav-$id'),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
