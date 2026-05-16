import 'package:flutter/material.dart';
import 'package:norigo/app/router.dart';
import 'package:norigo/app/theme.dart';
import 'package:norigo/core/widgets/app_card.dart';
import 'package:norigo/core/widgets/nori_button.dart';
import 'package:norigo/core/widgets/nori_chip.dart';
import 'package:norigo/core/widgets/section_header.dart';

class TripBasicsScreen extends StatefulWidget {
  const TripBasicsScreen({super.key});

  @override
  State<TripBasicsScreen> createState() => _TripBasicsScreenState();
}

class _TripBasicsScreenState extends State<TripBasicsScreen> {
  String _language = 'English';
  bool _firstVisit = true;
  String _mainPurpose = 'Sightseeing';
  int _tripLength = 5;
  bool _needsQueueHelp = true;
  String _companionType = 'Solo';
  String _foodNeeds = 'None';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trip basics')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SectionHeader(
              title: 'Personalize Korea for you',
              subtitle:
                  'NoriGo keeps context compact: only what helps your route, crowd alerts, and culture guide.',
            ),
            const SizedBox(height: 18),
            _choiceSection(
              title: 'Preferred language',
              values: const ['English', 'Japanese', 'Chinese', 'French'],
              selected: _language,
              onChanged: (value) => setState(() => _language = value),
            ),
            _staticDestination(),
            _choiceSection(
              title: 'First visit',
              values: const ['Yes', 'No'],
              selected: _firstVisit ? 'Yes' : 'No',
              onChanged: (value) =>
                  setState(() => _firstVisit = value == 'Yes'),
            ),
            _choiceSection(
              title: 'Main purpose',
              values: const ['Sightseeing', 'Food', 'Cafe', 'Culture'],
              selected: _mainPurpose,
              onChanged: (value) => setState(() => _mainPurpose = value),
            ),
            _tripLengthCard(),
            _toggleCard(),
            _choiceSection(
              title: 'Companion type',
              values: const ['Solo', 'Friends', 'Family', 'Couple'],
              selected: _companionType,
              onChanged: (value) => setState(() => _companionType = value),
            ),
            _choiceSection(
              title: 'Food needs',
              values: const ['None', 'Halal', 'Vegetarian', 'Allergy'],
              selected: _foodNeeds,
              onChanged: (value) => setState(() => _foodNeeds = value),
            ),
            const SizedBox(height: 12),
            NoriButton(
              label: 'Next: interests & alerts',
              icon: Icons.tune,
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.interestsAlerts),
            ),
          ],
        ),
      ),
    );
  }

  Widget _staticDestination() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: NoriCard(
        child: Row(
          children: [
            const Icon(Icons.place_outlined, color: NoriGoColors.sea),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Destination',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'South Korea',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tripLengthCard() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: NoriCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Trip length',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_tripLength days',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Shorter trip',
              onPressed: _tripLength > 1
                  ? () => setState(() => _tripLength -= 1)
                  : null,
              icon: const Icon(Icons.remove),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: 'Longer trip',
              onPressed: () => setState(() => _tripLength += 1),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggleCard() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: NoriCard(
        child: SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Need queue help'),
          subtitle: const Text(
            'Help me avoid app waitlists and reservation traps.',
          ),
          value: _needsQueueHelp,
          onChanged: (value) => setState(() => _needsQueueHelp = value),
        ),
      ),
    );
  }

  Widget _choiceSection({
    required String title,
    required List<String> values,
    required String selected,
    required ValueChanged<String> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: NoriCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.labelLarge),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: values.map((value) {
                return NoriChoiceChip(
                  label: value,
                  selected: selected == value,
                  onSelected: (_) => onChanged(value),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
