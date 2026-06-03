import 'package:flutter/material.dart';
import 'package:norigo/app/theme.dart';
import 'package:norigo/core/localization/l10n_extension.dart';
import 'package:norigo/core/widgets/app_card.dart';
import 'package:norigo/core/widgets/section_header.dart';
import 'package:norigo/data/mock/mock_norigo_data.dart';
import 'package:norigo/data/models/place.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    required this.onSelectTab,
    required this.onOpenCrowdAlert,
    super.key,
  });

  final ValueChanged<int> onSelectTab;
  final VoidCallback onOpenCrowdAlert;

  @override
  Widget build(BuildContext context) {
    final places = MockNoriGoData.hiddenSpots;
    final l10n = context.l10n;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.homeGreeting,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.homeTagline,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                tooltip: l10n.notifications,
                onPressed: onOpenCrowdAlert,
                icon: const Icon(Icons.notifications_outlined),
              ),
            ],
          ),
          const SizedBox(height: 18),
          TextField(
            decoration: InputDecoration(
              hintText: l10n.homeSearchHint,
              prefixIcon: const Icon(Icons.search),
            ),
            onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
          ),
          const SizedBox(height: 16),
          NoriCard(
            color: NoriGoColors.mint,
            borderColor: Colors.transparent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InfoPill(
                  label: l10n.aiRouteCheck,
                  icon: Icons.auto_awesome,
                  color: NoriGoColors.sea,
                ),
                const SizedBox(height: 14),
                Text(
                  l10n.crowdFreeRouteNow,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Dessert cafe queues are rising near Anguk. NoriGo can switch your 13:00 stop before the app waitlist fills.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: onOpenCrowdAlert,
                  icon: const Icon(Icons.alt_route),
                  label: Text(l10n.reviewAlert),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          SectionHeader(title: l10n.quickActions),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            childAspectRatio: 2.35,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: [
              _QuickAction(
                icon: Icons.map_outlined,
                label: l10n.crowdMap,
                onTap: () => _showSnack(context, l10n.sectionComingSoon),
              ),
              _QuickAction(
                icon: Icons.hourglass_bottom,
                label: l10n.waitTimeHelp,
                onTap: onOpenCrowdAlert,
              ),
              _QuickAction(
                icon: Icons.translate,
                label: l10n.liveTranslation,
                onTap: () => onSelectTab(2),
              ),
              _QuickAction(
                icon: Icons.explore_outlined,
                label: l10n.hiddenSpots,
                onTap: () => onSelectTab(3),
              ),
            ],
          ),
          const SizedBox(height: 22),
          SectionHeader(
            title: l10n.goodToVisitNow,
            subtitle: l10n.lowCrowdPicks,
          ),
          const SizedBox(height: 10),
          ...places.map(_PlaceNowCard.new),
          const SizedBox(height: 18),
          NoriCard(
            color: NoriGoColors.sky,
            borderColor: Colors.transparent,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline, color: NoriGoColors.gold),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.todaysCultureTip,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'In hanok villages, many streets are real residential areas. Keep voices low and avoid filming doorways.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return NoriCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: NoriGoColors.sea),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceNowCard extends StatelessWidget {
  const _PlaceNowCard(this.place);

  final Place place;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: NoriCard(
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: NoriGoColors.coral.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.storefront, color: NoriGoColors.coral),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${place.walkingMinutes} min walk • ${place.crowdLevel} crowd • ${place.area}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
