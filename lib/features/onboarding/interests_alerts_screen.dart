import 'package:flutter/material.dart';
import 'package:norigo/app/router.dart';
import 'package:norigo/app/theme.dart';
import 'package:norigo/core/widgets/app_card.dart';
import 'package:norigo/core/widgets/nori_button.dart';
import 'package:norigo/core/widgets/nori_chip.dart';
import 'package:norigo/core/widgets/section_header.dart';

class InterestsAlertsScreen extends StatefulWidget {
  const InterestsAlertsScreen({super.key});

  @override
  State<InterestsAlertsScreen> createState() => _InterestsAlertsScreenState();
}

class _InterestsAlertsScreenState extends State<InterestsAlertsScreen> {
  final Set<String> _interests = {'Food', 'Dessert', 'Hanok'};
  double _crowdPreference = 0.2;
  bool _crowdAlerts = true;
  bool _aiRerouting = true;
  bool _cultureScan = true;
  bool _audioGuide = false;
  bool _waitTimeHelp = true;

  static const _interestValues = [
    'Food',
    'Dessert',
    'Hanok',
    'Traditional market',
    'K-drama',
    'Night view',
    'Shopping',
    'Photo spot',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Interests & alerts')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SectionHeader(
              title: 'Set your calm-travel signal',
              subtitle:
                  'These settings guide crowd alerts, rerouting, and cultural scan explanations.',
            ),
            const SizedBox(height: 18),
            NoriCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Interests',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _interestValues.map((interest) {
                      return NoriChoiceChip(
                        label: interest,
                        selected: _interests.contains(interest),
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _interests.add(interest);
                            } else {
                              _interests.remove(interest);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            NoriCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Crowd preference',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  Slider(
                    value: _crowdPreference,
                    onChanged: (value) =>
                        setState(() => _crowdPreference = value),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Quiet',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Text(
                        'Lively',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            NoriCard(
              child: Column(
                children: [
                  _switchTile(
                    title: 'Real-time crowd alerts',
                    subtitle: 'Warn me before waitlists fill.',
                    value: _crowdAlerts,
                    onChanged: (value) => setState(() => _crowdAlerts = value),
                  ),
                  _switchTile(
                    title: 'AI rerouting',
                    subtitle: 'Suggest nearby calm alternatives.',
                    value: _aiRerouting,
                    onChanged: (value) => setState(() => _aiRerouting = value),
                  ),
                  _switchTile(
                    title: 'Cultural scan guide',
                    subtitle: 'Explain signs, rituals, etiquette, and context.',
                    value: _cultureScan,
                    onChanged: (value) => setState(() => _cultureScan = value),
                  ),
                  _switchTile(
                    title: 'Audio guide',
                    subtitle: 'Read cultural guide summaries aloud later.',
                    value: _audioGuide,
                    onChanged: (value) => setState(() => _audioGuide = value),
                  ),
                  _switchTile(
                    title: 'Wait-time & reservation help',
                    subtitle: 'Help with hidden queue systems.',
                    value: _waitTimeHelp,
                    onChanged: (value) => setState(() => _waitTimeHelp = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const SectionHeader(title: 'Essential access'),
            const SizedBox(height: 10),
            Row(
              children: const [
                Expanded(
                  child: _AccessCard(
                    icon: Icons.location_on_outlined,
                    label: 'Location',
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _AccessCard(
                    icon: Icons.camera_alt_outlined,
                    label: 'Camera',
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: _AccessCard(
                    icon: Icons.notifications_outlined,
                    label: 'Notifications',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            NoriButton(
              label: 'Start exploring',
              icon: Icons.map_outlined,
              onPressed: () => Navigator.of(
                context,
              ).pushNamedAndRemoveUntil(AppRoutes.home, (route) => false),
            ),
          ],
        ),
      ),
    );
  }

  Widget _switchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }
}

class _AccessCard extends StatelessWidget {
  const _AccessCard({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return NoriCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      child: Column(
        children: [
          Icon(icon, color: NoriGoColors.sea),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Ask later',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
