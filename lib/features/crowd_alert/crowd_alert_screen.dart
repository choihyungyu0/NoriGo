import 'package:flutter/material.dart';
import 'package:norigo/ai/context/ai_context.dart';
import 'package:norigo/ai/harness/ai_client.dart';
import 'package:norigo/ai/harness/norigo_ai_harness.dart';
import 'package:norigo/app/theme.dart';
import 'package:norigo/core/widgets/app_card.dart';
import 'package:norigo/core/widgets/nori_button.dart';
import 'package:norigo/core/widgets/section_header.dart';
import 'package:norigo/data/mock/mock_norigo_data.dart';
import 'package:norigo/data/models/recommendation.dart';

class CrowdAlertScreen extends StatefulWidget {
  const CrowdAlertScreen({super.key});

  @override
  State<CrowdAlertScreen> createState() => _CrowdAlertScreenState();
}

class _CrowdAlertScreenState extends State<CrowdAlertScreen> {
  late final Future<AiUserMessage> _aiMessage;

  @override
  void initState() {
    super.initState();
    final contextData = AiContextBuilder.fromPreference(
      preference: MockNoriGoData.preference,
      currentLocation: 'Anguk',
      itinerary: MockNoriGoData.itinerary,
      nearbyAlternatives: MockNoriGoData.alertAlternatives,
      crowdForecast: MockNoriGoData.crowdForecast,
      publicDataSummary: 'Mock crowd heatmap shows lunch-time cafe wait risk.',
    );
    _aiMessage = const NoriGoAiHarness(
      client: MockAiClient(),
    ).explainCrowdAlert(contextData);
  }

  @override
  Widget build(BuildContext context) {
    final forecast = MockNoriGoData.crowdForecast;
    final alternatives = MockNoriGoData.alertAlternatives;

    return Scaffold(
      appBar: AppBar(title: const Text('Crowd alert')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            NoriCard(
              color: NoriGoColors.danger.withValues(alpha: 0.1),
              borderColor: NoriGoColors.danger.withValues(alpha: 0.22),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.priority_high, color: NoriGoColors.danger),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      forecast.appQueueRiskMessage,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: NoriGoColors.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionHeader(
              title: 'Original plan',
              subtitle: '${forecast.placeName} at ${forecast.scheduledTime}',
            ),
            const SizedBox(height: 10),
            NoriCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          forecast.placeName,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      const InfoPill(
                        label: 'Very High',
                        icon: Icons.groups_3_outlined,
                        color: NoriGoColors.danger,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricBlock(
                          label: 'Estimated wait',
                          value:
                              '${forecast.estimatedWaitMin}-${forecast.estimatedWaitMax} min',
                        ),
                      ),
                      Expanded(
                        child: _MetricBlock(
                          label: 'Scheduled time',
                          value: forecast.scheduledTime,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            FutureBuilder<AiUserMessage>(
              future: _aiMessage,
              builder: (context, snapshot) {
                final message = snapshot.data;
                return NoriCard(
                  color: NoriGoColors.sky,
                  borderColor: Colors.transparent,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            color: NoriGoColors.sea,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            message?.title ?? 'Checking AI route risk...',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        message?.message ??
                            'NoriGo is validating wait risk and nearby alternatives.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            const SectionHeader(
              title: 'AI alternatives',
              subtitle: 'Similar mood, lower wait risk',
            ),
            const SizedBox(height: 10),
            ...alternatives.map(_AlternativeCard.new),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: NoriButton(
                    label: 'Keep original plan',
                    icon: Icons.check_circle_outline,
                    isSecondary: true,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: NoriButton(
                    label: 'Switch plan',
                    icon: Icons.swap_horiz,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Plan switched to Cafe Owall.'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricBlock extends StatelessWidget {
  const _MetricBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _AlternativeCard extends StatelessWidget {
  const _AlternativeCard(this.recommendation);

  final Recommendation recommendation;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: NoriCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    recommendation.placeName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                InfoPill(
                  label: '${recommendation.walkingMinutes} min walk',
                  icon: Icons.directions_walk,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Diversity ${recommendation.diversityScore}% • ${recommendation.crowdLevel} crowd • ${recommendation.rating.toStringAsFixed(1)} rating',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              recommendation.message,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}
