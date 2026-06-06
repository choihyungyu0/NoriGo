import 'package:flutter/foundation.dart';
import 'package:norigo/features/itinerary/domain/alternative_place.dart';
import 'package:norigo/features/itinerary/domain/itinerary_item.dart';
import 'package:norigo/features/itinerary/domain/itinerary_plan.dart';

class ItinerarySessionStore {
  const ItinerarySessionStore._();

  static ItineraryPlan? _currentPlan;
  static final ValueNotifier<ItineraryPlan?> notifier =
      ValueNotifier<ItineraryPlan?>(null);

  static ItineraryPlan? get currentPlan => _currentPlan;

  static void savePlan(ItineraryPlan plan) {
    _currentPlan = plan;
    notifier.value = plan;
  }

  static void replaceItem({
    required String originalItemId,
    required AlternativePlace alternative,
  }) {
    final plan = _currentPlan;
    if (plan == null) return;

    final items = plan.items
        .map((item) {
          if (item.id != originalItemId) return item;
          return item.copyWith(
            id: alternative.id,
            placeName: alternative.name,
            contentId: alternative.contentId,
            contentTypeId: alternative.contentTypeId,
            address: alternative.address,
            imageAssetPath: alternative.imageAssetPath,
            imageUrl: alternative.imageUrl,
            aiTip: alternative.recommendationCopy ?? alternative.description,
            cultureTip: alternative.description,
            crowdLevel: _crowdLevelFromLabel(alternative.crowdLevel),
            mapX: alternative.mapX,
            mapY: alternative.mapY,
            status: 'planned',
          );
        })
        .toList(growable: false);

    savePlan(plan.copyWith(items: items));
  }

  static void resetForTesting() {
    _currentPlan = null;
    notifier.value = null;
  }

  static ItineraryCrowdLevel _crowdLevelFromLabel(String label) {
    return label.toLowerCase().contains('moderate')
        ? ItineraryCrowdLevel.moderate
        : ItineraryCrowdLevel.low;
  }
}
