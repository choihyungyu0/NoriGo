class AiResponseValidator {
  const AiResponseValidator._();

  static bool hasRequiredStringFields(
    Map<String, Object?> response,
    List<String> fields,
  ) {
    for (final field in fields) {
      final value = response[field];
      if (value is! String || value.trim().isEmpty) {
        return false;
      }
    }
    return true;
  }

  static String safeText(
    Map<String, Object?> response,
    String field,
    String fallback,
  ) {
    final value = response[field];
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    return fallback;
  }
}
