alter table public.itinerary_plans
  add column if not exists title text;

alter table public.itinerary_plans
  add column if not exists date_label text;

alter table public.itinerary_plans
  add column if not exists source_type text;

alter table public.itinerary_plans
  add column if not exists source_badge text;

alter table public.itinerary_plans
  add column if not exists raw_json jsonb;

alter table public.itinerary_plans
  add column if not exists created_at timestamptz not null default now();

alter table public.itinerary_plans
  add column if not exists updated_at timestamptz not null default now();
