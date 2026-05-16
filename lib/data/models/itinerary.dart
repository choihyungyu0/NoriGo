class Itinerary {
  const Itinerary({
    required this.id,
    required this.title,
    required this.items,
    required this.timeSavedMinutes,
  });

  final String id;
  final String title;
  final List<ItineraryItem> items;
  final int timeSavedMinutes;
}

class ItineraryItem {
  const ItineraryItem({
    required this.time,
    required this.title,
    required this.crowdLevel,
    required this.stayTime,
    required this.recommendationMessage,
  });

  final String time;
  final String title;
  final String crowdLevel;
  final String stayTime;
  final String recommendationMessage;
}
