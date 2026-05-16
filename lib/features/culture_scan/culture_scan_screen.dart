import 'package:flutter/material.dart';
import 'package:norigo/app/theme.dart';
import 'package:norigo/core/widgets/app_card.dart';
import 'package:norigo/core/widgets/nori_button.dart';
import 'package:norigo/core/widgets/section_header.dart';
import 'package:norigo/data/mock/mock_norigo_data.dart';

class CultureScanScreen extends StatefulWidget {
  const CultureScanScreen({super.key});

  @override
  State<CultureScanScreen> createState() => _CultureScanScreenState();
}

class _CultureScanScreenState extends State<CultureScanScreen> {
  String _language = 'English';

  @override
  Widget build(BuildContext context) {
    final guide = MockNoriGoData.cultureGuide;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SectionHeader(
            title: 'Culture scan',
            subtitle: 'Camera-based context for etiquette, signs, and stories',
          ),
          const SizedBox(height: 14),
          Container(
            height: 310,
            decoration: BoxDecoration(
              color: const Color(0xFF172027),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.52),
                          width: 1.4,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  top: 18,
                  left: 18,
                  child: InfoPill(
                    label: 'Bulguksa',
                    icon: Icons.temple_buddhist,
                    color: NoriGoColors.gold,
                  ),
                ),
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      guide.koreanText,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 26,
                  left: 28,
                  right: 28,
                  child: NoriCard(
                    padding: const EdgeInsets.all(12),
                    color: Colors.white.withValues(alpha: 0.94),
                    child: Text(
                      guide.englishMeaning,
                      style: Theme.of(context).textTheme.titleMedium,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _language,
            decoration: const InputDecoration(
              labelText: 'Language',
              prefixIcon: Icon(Icons.language),
            ),
            items: const ['English', 'Japanese', 'Chinese', 'French']
                .map(
                  (language) =>
                      DropdownMenuItem(value: language, child: Text(language)),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() => _language = value);
              }
            },
          ),
          const SizedBox(height: 14),
          NoriCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.auto_awesome, color: NoriGoColors.sea),
                    const SizedBox(width: 8),
                    Text(
                      'AI Culture Guide',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  guide.question,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                _GuideRow(title: 'Meaning', body: guide.meaning),
                _GuideRow(title: 'Etiquette', body: guide.etiquette),
                _GuideRow(title: 'Story', body: guide.story),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: NoriButton(
                  label: 'Scan Culture',
                  icon: Icons.center_focus_strong,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Culture scan refreshed.')),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: NoriButton(
                  label: 'AR View',
                  icon: Icons.view_in_ar,
                  isSecondary: true,
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'AR view will connect after camera setup.',
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GuideRow extends StatelessWidget {
  const _GuideRow({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: NoriGoColors.sea),
          ),
          const SizedBox(height: 4),
          Text(body, style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }
}
