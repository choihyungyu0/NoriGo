create extension if not exists pgcrypto;

create table if not exists public.culture_scan_records (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz default now(),
  user_language text,
  current_location text,
  detected_object text,
  korean_keyword text,
  question text,
  description text,
  meaning text,
  etiquette text,
  story text,
  korean_phrase text,
  pronunciation text,
  phrase_meaning text,
  confidence numeric,
  source_note text,
  source_type text default 'ennoia_kto_mcp'
);

create table if not exists public.itinerary_plans (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz default now(),
  date_label text,
  summary text,
  time_saved text,
  source_note text,
  raw_json jsonb,
  source_type text default 'ennoia_kto_mcp'
);

create table if not exists public.retrip_events (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz default now(),
  original_place text,
  trigger_type text,
  crowd_level text,
  estimated_wait text,
  recommended_action text,
  source_note text,
  raw_json jsonb,
  source_type text default 'ennoia_kto_mcp'
);

alter table public.culture_scan_records enable row level security;
alter table public.itinerary_plans enable row level security;
alter table public.retrip_events enable row level security;

create policy "Authenticated users can insert culture scan records"
  on public.culture_scan_records
  for insert
  to authenticated
  with check (auth.uid() is not null);

create policy "Authenticated users can select culture scan records"
  on public.culture_scan_records
  for select
  to authenticated
  using (auth.uid() is not null);

create policy "Authenticated users can insert itinerary plans"
  on public.itinerary_plans
  for insert
  to authenticated
  with check (auth.uid() is not null);

create policy "Authenticated users can select itinerary plans"
  on public.itinerary_plans
  for select
  to authenticated
  using (auth.uid() is not null);

create policy "Authenticated users can insert retrip events"
  on public.retrip_events
  for insert
  to authenticated
  with check (auth.uid() is not null);

create policy "Authenticated users can select retrip events"
  on public.retrip_events
  for select
  to authenticated
  using (auth.uid() is not null);

comment on table public.culture_scan_records is
  'MVP ennoia Culture Guide persistence. Add user_id ownership policies before production.';
comment on table public.itinerary_plans is
  'MVP ennoia Itinerary persistence. Add user_id ownership policies before production.';
comment on table public.retrip_events is
  'MVP ennoia Re-Trip persistence. Add user_id ownership policies before production.';
