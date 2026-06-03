import 'dart:async';

import 'package:flutter/material.dart';
import 'package:norigo/app/theme.dart';
import 'package:norigo/core/localization/l10n_extension.dart';
import 'package:norigo/core/widgets/app_card.dart';
import 'package:norigo/core/widgets/nori_chip.dart';
import 'package:norigo/core/widgets/section_header.dart';
import 'package:norigo/data/mock/mock_norigo_data.dart';
import 'package:norigo/data/models/place.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';
  String _category = 'All';

  static const _categories = [
    'All',
    'Quiet cafe',
    'Dessert',
    'Local food',
    'Photo spot',
    'Culture',
  ];

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      if (mounted) {
        setState(() => _query = value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final picks = _filteredPlaces();
    final l10n = context.l10n;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SectionHeader(
            title: l10n.discoverHiddenSpots,
            subtitle: l10n.discoverSubtitle,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              hintText: l10n.discoverSearchHint,
              prefixIcon: const Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((category) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: NoriChoiceChip(
                    label: category,
                    selected: _category == category,
                    onSelected: (_) => setState(() => _category = category),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          const _DiscoverMap(),
          const SizedBox(height: 18),
          SectionHeader(title: l10n.aiPicks),
          const SizedBox(height: 10),
          if (picks.isEmpty)
            NoriCard(child: Text(l10n.noCalmPlaces))
          else
            ...picks.map(_HiddenSpotCard.new),
        ],
      ),
    );
  }

  List<Place> _filteredPlaces() {
    final normalizedQuery = _query.trim().toLowerCase();
    return MockNoriGoData.hiddenSpots.where((place) {
      final matchesQuery =
          normalizedQuery.isEmpty ||
          place.name.toLowerCase().contains(normalizedQuery) ||
          place.area.toLowerCase().contains(normalizedQuery) ||
          place.tags.any((tag) => tag.toLowerCase().contains(normalizedQuery));
      final matchesCategory =
          _category == 'All' ||
          place.category == _category ||
          place.tags.contains(_category);
      return matchesQuery && matchesCategory;
    }).toList();
  }
}

class _DiscoverMap extends StatelessWidget {
  const _DiscoverMap();

  @override
  Widget build(BuildContext context) {
    return NoriCard(
      padding: EdgeInsets.zero,
      child: Container(
        height: 190,
        decoration: BoxDecoration(
          color: NoriGoColors.sky,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            Positioned(
              left: 20,
              top: 24,
              child: _MapMarker(label: 'Yeonnam', color: NoriGoColors.sea),
            ),
            Positioned(
              right: 28,
              top: 72,
              child: _MapMarker(label: 'Mangwon', color: NoriGoColors.coral),
            ),
            Positioned(
              left: 78,
              bottom: 28,
              child: _MapMarker(label: 'Seochon', color: NoriGoColors.gold),
            ),
            Center(
              child: Text(
                context.l10n.mapPlaceholder,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(color: NoriGoColors.softInk),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapMarker extends StatelessWidget {
  const _MapMarker({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(Icons.location_on, color: color, size: 30),
        Text(label, style: Theme.of(context).textTheme.labelLarge),
      ],
    );
  }
}

class _HiddenSpotCard extends StatelessWidget {
  const _HiddenSpotCard(this.place);

  final Place place;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: NoriCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    place.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text(
                  place.rating.toStringAsFixed(1),
                  style: Theme.of(
                    context,
                  ).textTheme.titleMedium?.copyWith(color: NoriGoColors.gold),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.star, color: NoriGoColors.gold, size: 18),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${place.walkingMinutes} min walk • ${place.crowdLevel} crowd • Local visit ratio ${place.localVisitRatio}%',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Diversity score ${place.diversityScore}%',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: place.tags.map((tag) {
                return InfoPill(
                  label: tag,
                  icon: Icons.check,
                  color: tag == 'Quiet'
                      ? NoriGoColors.success
                      : NoriGoColors.sea,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
