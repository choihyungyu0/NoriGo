import 'package:norigo/features/itinerary/domain/itinerary_item.dart';

class ItineraryPlan {
  const ItineraryPlan({
    required this.id,
    required this.dateLabel,
    required this.title,
    required this.items,
    required this.estimatedTimeSaved,
    this.sourceType = 'mock',
    this.sourceBadge,
    this.sourceNote,
    this.summary,
  });

  final String id;
  final String dateLabel;
  final String title;
  final List<ItineraryItem> items;
  final String estimatedTimeSaved;
  final String sourceType;
  final String? sourceBadge;
  final String? sourceNote;
  final String? summary;
}
