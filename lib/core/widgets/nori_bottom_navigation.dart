import 'package:flutter/material.dart';
import 'package:norigo/core/localization/l10n_extension.dart';

class NoriBottomNavigation extends StatelessWidget {
  const NoriBottomNavigation({
    required this.currentIndex,
    required this.onChanged,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onChanged;

  static const _baseHeight = 88.0;

  static double heightFor(BuildContext context) {
    return _baseHeight + MediaQuery.paddingOf(context).bottom;
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final selectedIndex = currentIndex.clamp(0, _items.length - 1).toInt();
    final labels = [
      context.l10n.home,
      context.l10n.itinerary,
      context.l10n.scan,
      context.l10n.discover,
      context.l10n.my,
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: _borderColor)),
        boxShadow: [
          BoxShadow(
            color: _shadowColor.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SizedBox(
        height: heightFor(context),
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
                    item: _items[0],
                    label: labels[0],
                    selected: selectedIndex == 0,
                    onTap: () => onChanged(0),
                  ),
                  _BottomNavItem(
                    item: _items[1],
                    label: labels[1],
                    selected: selectedIndex == 1,
                    onTap: () => onChanged(1),
                  ),
                  const Expanded(child: SizedBox.shrink()),
                  _BottomNavItem(
                    item: _items[3],
                    label: labels[3],
                    selected: selectedIndex == 3,
                    onTap: () => onChanged(3),
                  ),
                  _BottomNavItem(
                    item: _items[4],
                    label: labels[4],
                    selected: selectedIndex == 4,
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
                  key: ValueKey(
                    selectedIndex == 2
                        ? 'bottomNav-scan-selected'
                        : 'bottomNav-scan',
                  ),
                  customBorder: const CircleBorder(),
                  onTap: () => onChanged(2),
                  child: KeyedSubtree(
                    key: ValueKey(
                      selectedIndex == 2 ? 'active-nav-Scan' : 'nav-Scan',
                    ),
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: _borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: _shadowColor.withValues(alpha: 0.18),
                            blurRadius: 22,
                            offset: const Offset(0, 9),
                          ),
                        ],
                      ),
                      child: Icon(
                        _items[2].icon,
                        color: selectedIndex == 2
                            ? _selectedColor
                            : _mutedColor,
                        size: 34,
                      ),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selectedIndex == 2 ? _selectedColor : _mutedColor,
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
    required this.item,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final _BottomNavData item;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? _selectedColor : _mutedColor;
    return Expanded(
      child: InkWell(
        key: ValueKey(
          selected ? 'bottomNav-${item.id}-selected' : 'bottomNav-${item.id}',
        ),
        onTap: onTap,
        child: KeyedSubtree(
          key: ValueKey(
            selected ? 'active-nav-${item.keyLabel}' : 'nav-${item.keyLabel}',
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icon, color: color, size: 30),
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
      ),
    );
  }
}

class _BottomNavData {
  const _BottomNavData({
    required this.id,
    required this.keyLabel,
    required this.icon,
  });

  final String id;
  final String keyLabel;
  final IconData icon;
}

const _items = [
  _BottomNavData(id: 'home', keyLabel: 'Home', icon: Icons.home_outlined),
  _BottomNavData(
    id: 'itinerary',
    keyLabel: 'Itinerary',
    icon: Icons.calendar_month_outlined,
  ),
  _BottomNavData(
    id: 'scan',
    keyLabel: 'Scan',
    icon: Icons.center_focus_strong_rounded,
  ),
  _BottomNavData(
    id: 'discover',
    keyLabel: 'Discover',
    icon: Icons.explore_rounded,
  ),
  _BottomNavData(id: 'my', keyLabel: 'My', icon: Icons.person_outline_rounded),
];

const _selectedColor = Color(0xFF5717D9);
const _mutedColor = Color(0xFF7A7F93);
const _borderColor = Color(0xFFE8E3F2);
const _shadowColor = Color(0xFF5E4D85);
