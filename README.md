# NoriGo

NoriGo is a crowd-aware and culture-aware AI travel assistant for foreign tourists visiting Korea.

This prototype includes:

- English-first onboarding for trip basics, interests, alerts, queue help, and food needs.
- Bottom-tab travel experience: Home, Itinerary, Scan, Discover, and My.
- Crowd alert flow that explains hidden app-based queue risk.
- Camera-style culture scan mock with Korean context and etiquette guidance.
- Hidden spot discovery with low-crowd, local-ratio, and diversity-score signals.
- Public organization dashboard placeholder using aggregate-only metrics.
- Mock-first repository boundaries for future Supabase tables and public data APIs.
- AI prompt, context, client, validation, and fallback harness structure.

No Supabase, OAuth, public data, camera, map, or AI credentials are hardcoded. The app uses deterministic mock repositories until real configuration exists.

## Run

```bash
flutter pub get
flutter run
```

## Verify

```bash
dart format .
flutter analyze
flutter test
```
