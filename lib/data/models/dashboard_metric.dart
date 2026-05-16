class DashboardMetric {
  const DashboardMetric({
    required this.label,
    required this.value,
    required this.trend,
    required this.description,
  });

  final String label;
  final String value;
  final String trend;
  final String description;
}
