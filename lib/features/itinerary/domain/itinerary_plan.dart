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
    this.persistedPlanId,
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
  final String? persistedPlanId;

  ItineraryPlan copyWith({
    String? id,
    String? dateLabel,
    String? title,
    List<ItineraryItem>? items,
    String? estimatedTimeSaved,
    String? sourceType,
    String? sourceBadge,
    String? sourceNote,
    String? summary,
    String? persistedPlanId,
  }) {
    return ItineraryPlan(
      id: id ?? this.id,
      dateLabel: dateLabel ?? this.dateLabel,
      title: title ?? this.title,
      items: items ?? this.items,
      estimatedTimeSaved: estimatedTimeSaved ?? this.estimatedTimeSaved,
      sourceType: sourceType ?? this.sourceType,
      sourceBadge: sourceBadge ?? this.sourceBadge,
      sourceNote: sourceNote ?? this.sourceNote,
      summary: summary ?? this.summary,
      persistedPlanId: persistedPlanId ?? this.persistedPlanId,
    );
  }
}
