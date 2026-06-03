enum DiscoverCategory {
  quietCafe('quiet_cafe', 'Quiet cafe'),
  dessert('dessert', 'Dessert'),
  localFood('local_food', 'Local food'),
  photoSpot('photo_spot', 'Photo spot'),
  culture('culture', 'Culture');

  const DiscoverCategory(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static DiscoverCategory fromApiValue(String? value) {
    final normalized = value?.trim().toLowerCase();
    return DiscoverCategory.values.firstWhere(
      (category) => category.apiValue == normalized,
      orElse: () => DiscoverCategory.quietCafe,
    );
  }
}
