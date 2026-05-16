import 'package:flutter/material.dart';
import 'package:norigo/app/theme.dart';

class NoriButton extends StatelessWidget {
  const NoriButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isSecondary = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isSecondary;

  @override
  Widget build(BuildContext context) {
    final foreground = isSecondary ? NoriGoColors.ink : Colors.white;
    final background = isSecondary ? Colors.white : NoriGoColors.sea;

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: Icon(icon ?? Icons.arrow_forward, size: 18),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          minimumSize: const Size.fromHeight(50),
          side: isSecondary ? const BorderSide(color: NoriGoColors.line) : null,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
