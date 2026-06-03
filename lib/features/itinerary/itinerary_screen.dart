import 'package:flutter/material.dart';
import 'package:norigo/app/theme.dart';
import 'package:norigo/core/localization/l10n_extension.dart';
import 'package:norigo/core/widgets/app_card.dart';
import 'package:norigo/core/widgets/nori_button.dart';
import 'package:norigo/core/widgets/section_header.dart';
import 'package:norigo/data/mock/mock_norigo_data.dart';
import 'package:norigo/data/models/itinerary.dart';

class ItineraryScreen extends StatelessWidget {
  const ItineraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final itinerary = MockNoriGoData.itinerary;
    final l10n = context.l10n;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SectionHeader(
            title: l10n.aiItineraryPlanner,
            subtitle: itinerary.title,
          ),
          const SizedBox(height: 14),
          NoriCard(
            color: NoriGoColors.mint,
            borderColor: Colors.transparent,
            child: Row(
              children: [
                const Icon(Icons.timer_outlined, color: NoriGoColors.sea),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "You'll save up to 1h 25m",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...itinerary.items.map(_TimelineCard.new),
          const SizedBox(height: 16),
          const _MapPlaceholder(),
          const SizedBox(height: 18),
          NoriButton(
            label: l10n.saveThisPlan,
            icon: Icons.bookmark_add_outlined,
            onPressed: () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(l10n.savedToSupabase)));
            },
          ),
        ],
      ),
    );
  }
}

class _TimelineCard extends StatelessWidget {
  const _TimelineCard(this.item);

  final ItineraryItem item;

  Color get _crowdColor {
    switch (item.crowdLevel) {
      case 'Very High':
        return NoriGoColors.danger;
      case 'High':
        return NoriGoColors.warning;
      case 'Moderate':
        return NoriGoColors.gold;
      default:
        return NoriGoColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Text(
              item.time,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: NoriGoColors.sea),
            ),
          ),
          Expanded(
            child: NoriCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      InfoPill(
                        label: item.crowdLevel,
                        icon: Icons.groups_outlined,
                        color: _crowdColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${context.l10n.stayTime}: ${item.stayTime}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.recommendationMessage,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MapPlaceholder extends StatelessWidget {
  const _MapPlaceholder();

  @override
  Widget build(BuildContext context) {
    return NoriCard(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.routeOverviewMap,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Container(
            height: 170,
            decoration: BoxDecoration(
              color: NoriGoColors.sky,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: NoriGoColors.line),
            ),
            child: Stack(
              children: const [
                Positioned(top: 28, left: 32, child: _MapDot(label: 'Palace')),
                Positioned(top: 82, right: 34, child: _MapDot(label: 'Cafe')),
                Positioned(
                  bottom: 24,
                  left: 78,
                  child: _MapDot(label: 'Tower'),
                ),
                Center(
                  child: Icon(
                    Icons.alt_route,
                    size: 52,
                    color: NoriGoColors.sea,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapDot extends StatelessWidget {
  const _MapDot({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Icon(Icons.location_on, color: NoriGoColors.coral),
        Text(label, style: Theme.of(context).textTheme.labelLarge),
      ],
    );
  }
}
