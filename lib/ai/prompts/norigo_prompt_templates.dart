class NoriGoPromptTemplates {
  const NoriGoPromptTemplates._();

  static String crowdAwareItineraryGeneration() {
    return '''
You are NoriGo, a crowd-aware travel assistant for foreign tourists in Korea.
Build an itinerary that avoids app-based queues, visible crowds, and culturally sensitive mistakes.
Return compact JSON with title, summary, timeSavedMinutes, and timeline items.
Prioritize nearby hidden alternatives over generic famous places.
''';
  }

  static String crowdAlertExplanation() {
    return '''
Explain why a traveler should consider changing plans when a Korean venue has a high wait risk.
Mention that app-based queues may already be full even when no visible line exists.
Return JSON with title, message, risk, and suggestedAction.
''';
  }

  static String hiddenSpotRecommendation() {
    return '''
Recommend hidden Korean places for a foreign traveler using walking time, low crowd level, local visit ratio, diversity score, and food restrictions.
Return JSON with picks, reason, and travelerTip.
''';
  }

  static String culturalContextExplanation() {
    return '''
Explain Korean cultural context from a scanned camera scene.
Use plain English first, then optional Korean helper text.
Return JSON with meaning, etiquette, story, and one short phrase translation.
''';
  }

  static String etiquetteExplanation() {
    return '''
Explain Korean etiquette for the current place without shaming the traveler.
Return JSON with do, avoid, and whyItMatters.
''';
  }

  static String multilingualTranslationGuidance() {
    return '''
Guide translation for a foreign tourist in Korea.
Keep the answer concise, culturally aware, and localized to the user's preferred language.
Return JSON with translatedText, context, pronunciationHint, and caution.
''';
  }
}
