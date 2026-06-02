import 'package:flutter/material.dart';
import 'package:norigo/app/theme.dart';
import 'package:norigo/features/culture_scan/application/culture_scan_controller.dart';

class CultureBottomControls extends StatelessWidget {
  const CultureBottomControls({
    required this.selectedLanguage,
    required this.scanStatus,
    required this.flashEnabled,
    required this.onLanguageChanged,
    required this.onScanCulture,
    required this.onToggleFlash,
    super.key,
  });

  final String selectedLanguage;
  final CultureScanStatus scanStatus;
  final bool flashEnabled;
  final ValueChanged<String> onLanguageChanged;
  final VoidCallback onScanCulture;
  final VoidCallback onToggleFlash;

  bool get _isScanning => scanStatus == CultureScanStatus.scanning;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _LanguageSelector(
                  value: selectedLanguage,
                  onChanged: onLanguageChanged,
                ),
              ),
              const SizedBox(width: 12),
              _ScanButton(
                isScanning: _isScanning,
                onPressed: _isScanning ? null : onScanCulture,
              ),
              const SizedBox(width: 12),
              _IconControlButton(
                icon: flashEnabled ? Icons.flash_on : Icons.flash_off,
                label: flashEnabled ? 'Flash on' : 'Flash off',
                onTap: onToggleFlash,
              ),
            ],
          ),
          const SizedBox(height: 10),
          const _BottomNavMock(),
        ],
      ),
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: 'Language',
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      items: const ['English', 'Japanese', 'Chinese', 'French']
          .map(
            (language) => DropdownMenuItem(
              value: language,
              child: Text(language, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      onChanged: (language) {
        if (language != null) onChanged(language);
      },
    );
  }
}

class _ScanButton extends StatelessWidget {
  const _ScanButton({required this.isScanning, required this.onPressed});

  final bool isScanning;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Scan Culture',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 66,
            height: 66,
            child: FilledButton(
              onPressed: onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: NoriGoColors.purple,
                foregroundColor: Colors.white,
                padding: EdgeInsets.zero,
                shape: const CircleBorder(),
              ),
              child: isScanning
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.center_focus_strong, size: 30),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Scan Culture',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: NoriGoColors.purple,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _IconControlButton extends StatelessWidget {
  const _IconControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: IconButton.outlined(onPressed: onTap, icon: Icon(icon, size: 20)),
    );
  }
}

class _BottomNavMock extends StatelessWidget {
  const _BottomNavMock();

  static const _items = [
    (Icons.home_outlined, 'Home'),
    (Icons.route_outlined, 'Itinerary'),
    (Icons.center_focus_strong, 'Scan'),
    (Icons.travel_explore, 'Discover'),
    (Icons.person_outline, 'My'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _items.map((item) {
        final active = item.$2 == 'Scan';
        return Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                item.$1,
                color: active ? NoriGoColors.purple : NoriGoColors.softInk,
                size: 21,
              ),
              const SizedBox(height: 3),
              Text(
                item.$2,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: active ? NoriGoColors.purple : NoriGoColors.softInk,
                  fontSize: 11,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
