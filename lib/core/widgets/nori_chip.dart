import 'package:flutter/material.dart';
import 'package:norigo/app/theme.dart';

class NoriChoiceChip extends StatelessWidget {
  const NoriChoiceChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
    super.key,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 16,
              color: selected ? NoriGoColors.sea : NoriGoColors.softInk,
            ),
            const SizedBox(width: 6),
          ],
          Text(label),
        ],
      ),
      selected: selected,
      showCheckmark: false,
      onSelected: onSelected,
    );
  }
}
