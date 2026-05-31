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

## ennoia Integration

NoriGo keeps Flutter as the app surface and calls the ennoia Agent API through Supabase Edge Functions. The itinerary function now retrieves dynamic Korea Tourism Organization OpenAPI candidates itself, scores them, selects a route, and sends the selected `KTO_DATA` to ennoia for personalized explanations:

```text
Flutter app -> Supabase Edge Function -> KTO OpenAPI -> candidate scoring -> ennoia Agent API -> JSON response -> Flutter screen
```

Flutter receives only the public Supabase URL and anon key through `--dart-define`. Email login and sign up call Supabase Auth REST endpoints from the app. After login, Edge Function calls send the signed-in user's Supabase access token in `Authorization` and the public anon key in `apikey`; `KTO_SERVICE_KEY` and `ENNOIA_API_KEY` stay in Supabase Edge Function secrets.

Created Edge Functions:

- `supabase/functions/ennoia-culture-guide/index.ts`
- `supabase/functions/ennoia-itinerary/index.ts`
- `supabase/functions/ennoia-retrip/index.ts`

Required Supabase Edge Function secrets:

```powershell
npx.cmd supabase secrets set ENNOIA_API_ENDPOINT="https://api.ennoia.so/api/preset/v2/chat/completions"
npx.cmd supabase secrets set ENNOIA_PROJECT="KNTO-PROMPTON-2026-278"
npx.cmd supabase secrets set ENNOIA_CULTURE_HASH="dc44d0299932b02678332570c300d55fbfb0ce66a17d99748b7d037af057c979"
npx.cmd supabase secrets set ENNOIA_ITINERARY_API_HASH="your-mcp-free-itinerary-agent-hash"
npx.cmd supabase secrets set ENNOIA_RETRIP_HASH="aca71cdc813b24da90d4b20b03e5bbd7c7ca7bf8aa60769a1ba7eebd934d5ac1"
npx.cmd supabase secrets set ENNOIA_API_KEY="your-ennoia-api-key"
npx.cmd supabase secrets set KTO_SERVICE_KEY="your-kto-openapi-service-key"
```

The AI itinerary is not manually fixed. User interests, base location, companion type, and crowd preference expand into multiple Korean KTO keyword searches. The Edge Function deduplicates by KTO `contentid`, keeps real candidate fields, scores candidates for preference fit, content type relevance, images, address quality, Seoul relevance, route distance, crowd preference, and diversity, then builds a five-stop route before ennoia writes `reason`, `culture_tip`, `stay_time`, and `crowd_level`.

Fallback exists only when `KTO_SERVICE_KEY` is missing, KTO OpenAPI fails, or fewer than five usable KTO candidates are available after keyword searches. Fallback responses use `source_type = kto_openapi_fallback`, `source_badge = Demo fallback`, and a `source_note` that does not claim real KTO OpenAPI success. Real KTO + ennoia responses use `source_type = kto_openapi_ennoia`.

Deploy the functions:

```powershell
npx.cmd supabase functions deploy ennoia-culture-guide
npx.cmd supabase functions deploy ennoia-itinerary
npx.cmd supabase functions deploy ennoia-retrip
```

Run Flutter with only Supabase public config:

```powershell
flutter run --dart-define=SUPABASE_URL="https://your-project.supabase.co" --dart-define=SUPABASE_ANON_KEY="your-supabase-anon-key"
```

For local function testing, create a local env file outside commits and serve a function:

```powershell
npx.cmd supabase functions serve ennoia-culture-guide --env-file supabase/.env.local
```

Do not commit real API keys or local env files.

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
