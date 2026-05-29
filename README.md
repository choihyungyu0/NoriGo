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

NoriGo keeps Flutter as the app surface and calls Supabase Edge Functions for private API work:

```text
Flutter app -> Supabase Edge Function -> Korea Tourism Organization OpenAPI -> KTO_DATA -> ennoia Itinerary API Agent -> JSON response -> Flutter screen
```

Flutter never receives the ennoia API key or Korea Tourism Organization OpenAPI service key. Culture Guide and Re-Trip still use their existing ennoia agent paths; itinerary generation avoids MCP at runtime by passing KTO_DATA directly to an MCP-free ennoia API Agent.

Created Edge Functions:

- `supabase/functions/ennoia-culture-guide/index.ts`
- `supabase/functions/ennoia-itinerary/index.ts`
- `supabase/functions/ennoia-retrip/index.ts`

Persistence tables:

- `culture_scan_records`
- `itinerary_plans`
- `retrip_events`

After a real itinerary response, the `ennoia-itinerary` Edge Function writes the parsed result to `itinerary_plans` with the Supabase service role key and returns `persisted: true`. Flutter then shows `Saved to Supabase`. Mock fallback still stays local and shows `Local mock only`.

The migration enables RLS and creates insert/select policies for the `authenticated` role only. This project does not yet include a real Supabase Auth session or per-user `user_id` columns, so production policies must be tightened before launch by adding ownership columns and scoping `using` / `with check` to `auth.uid()`.

Required Supabase Edge Function secrets:

```powershell
npx.cmd supabase secrets set ENNOIA_API_ENDPOINT="https://api.ennoia.so/api/preset/v2/chat/completions"
npx.cmd supabase secrets set ENNOIA_PROJECT="KNTO-PROMPTON-2026-278"
npx.cmd supabase secrets set ENNOIA_CULTURE_HASH="dc44d0299932b02678332570c300d55fbfb0ce66a17d99748b7d037af057c979"
npx.cmd supabase secrets set ENNOIA_ITINERARY_API_HASH="your-mcp-free-itinerary-api-agent-hash"
npx.cmd supabase secrets set ENNOIA_RETRIP_HASH="aca71cdc813b24da90d4b20b03e5bbd7c7ca7bf8aa60769a1ba7eebd934d5ac1"
npx.cmd supabase secrets set ENNOIA_USER_ID="norigo-demo-user"
npx.cmd supabase secrets set ENNOIA_API_KEY="your-ennoia-api-key"
npx.cmd supabase secrets set KTO_SERVICE_KEY="your-kto-openapi-service-key"
```

`SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY` are available to hosted Supabase Edge Functions by default. If serving locally, include both in `supabase/.env.local` so itinerary persistence can be tested locally too.

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

## Supabase Persistence

Apply the persistence migration:

```powershell
npx.cmd supabase db push
```

Or apply the SQL file directly in the Supabase SQL editor:

```text
supabase/migrations/20260529193000_create_ennoia_persistence_tables.sql
```

Rows are inserted after successful calls to:

- `ennoia-culture-guide` -> `culture_scan_records`
- `ennoia-itinerary` -> `itinerary_plans` from inside the Edge Function
- `ennoia-retrip` -> `retrip_events`

## Evidence Checklist

- Edge Function logs show ennoia Agent requests without exposing `ENNOIA_API_KEY`.
- Flutter UI shows `KTO OpenAPI + ennoia` for real itinerary output.
- Flutter UI shows `Saved to Supabase` only after the insert request succeeds.
- Flutter UI shows `Local mock only` when mock fallback is active or persistence is unavailable.
- Supabase itinerary rows include `source_type = 'kto_openapi_ennoia'` for live KTO OpenAPI data or `source_type = 'kto_openapi_fallback'` when demo KTO_DATA was needed.
- RLS is enabled; before production, add Supabase Auth ownership columns and user-scoped policies.

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
