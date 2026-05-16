class CrowdForecast {
  const CrowdForecast({
    required this.placeName,
    required this.crowdLevel,
    required this.estimatedWaitMin,
    required this.estimatedWaitMax,
    required this.scheduledTime,
    required this.appQueueRiskMessage,
  });

  final String placeName;
  final String crowdLevel;
  final int estimatedWaitMin;
  final int estimatedWaitMax;
  final String scheduledTime;
  final String appQueueRiskMessage;
}
