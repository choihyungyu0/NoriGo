String itinerarySourceLabel(String? sourceType, {String? sourceBadge}) {
  final normalized = sourceType?.trim().toLowerCase() ?? '';

  if (normalized == 'kto_openapi_ennoia') {
    return 'KTO OpenAPI + ennoia';
  }
  if (normalized == 'kto_openapi' ||
      normalized == 'kto_openapi_basic' ||
      normalized == 'kto_openapi_direct') {
    return 'KTO OpenAPI';
  }
  if (normalized.contains('fallback')) {
    return 'Demo fallback';
  }
  if (normalized == 'mock_ennoia' || normalized == 'mock') {
    return 'Mock ennoia';
  }

  final badge = sourceBadge?.trim();
  if (badge != null && badge.isNotEmpty) return badge;

  if (normalized == 'ennoia') return 'ennoia';
  return 'Mock ennoia';
}

bool itineraryEnnoiaSucceeded(String? sourceType) {
  return sourceType?.trim().toLowerCase() == 'kto_openapi_ennoia';
}
