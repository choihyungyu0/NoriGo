create extension if not exists pgcrypto;

create table if not exists public.itinerary_plans (
  id uuid primary key default gen_random_uuid(),
  user_id uuid,
  title text,
  date_label text,
  source_type text,
  source_badge text,
  raw_json jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.itinerary_items (
  id uuid primary key default gen_random_uuid(),
  plan_id uuid references public.itinerary_plans(id) on delete cascade,
  user_id uuid,
  local_item_id text,
  replaced_from_local_item_id text,
  sort_order integer,
  time_label text,
  place_name text,
  kto_content_id text,
  content_type_id text,
  address text,
  image_url text,
  reason text,
  crowd_level text,
  stay_time text,
  culture_tip text,
  latitude double precision,
  longitude double precision,
  status text not null default 'planned',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.itinerary_items add column if not exists plan_id uuid;
alter table public.itinerary_items add column if not exists user_id uuid;
alter table public.itinerary_items add column if not exists local_item_id text;
alter table public.itinerary_items add column if not exists replaced_from_local_item_id text;
alter table public.itinerary_items add column if not exists sort_order integer;
alter table public.itinerary_items add column if not exists time_label text;
alter table public.itinerary_items add column if not exists place_name text;
alter table public.itinerary_items add column if not exists kto_content_id text;
alter table public.itinerary_items add column if not exists content_type_id text;
alter table public.itinerary_items add column if not exists address text;
alter table public.itinerary_items add column if not exists image_url text;
alter table public.itinerary_items add column if not exists reason text;
alter table public.itinerary_items add column if not exists crowd_level text;
alter table public.itinerary_items add column if not exists stay_time text;
alter table public.itinerary_items add column if not exists culture_tip text;
alter table public.itinerary_items add column if not exists latitude double precision;
alter table public.itinerary_items add column if not exists longitude double precision;
alter table public.itinerary_items add column if not exists status text not null default 'planned';
alter table public.itinerary_items add column if not exists created_at timestamptz not null default now();
alter table public.itinerary_items add column if not exists updated_at timestamptz not null default now();

create table if not exists public.retrip_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid,
  plan_id uuid,
  original_item_id text,
  original_place_name text,
  trigger_type text,
  crowd_level text,
  estimated_wait text,
  source_type text,
  source_badge text,
  recommended_action text,
  raw_json jsonb,
  selected_alternative_json jsonb,
  created_at timestamptz not null default now()
);

alter table public.retrip_events add column if not exists user_id uuid;
alter table public.retrip_events add column if not exists plan_id uuid;
alter table public.retrip_events add column if not exists original_item_id text;
alter table public.retrip_events add column if not exists original_place_name text;
alter table public.retrip_events add column if not exists trigger_type text;
alter table public.retrip_events add column if not exists crowd_level text;
alter table public.retrip_events add column if not exists estimated_wait text;
alter table public.retrip_events add column if not exists source_type text;
alter table public.retrip_events add column if not exists source_badge text;
alter table public.retrip_events add column if not exists recommended_action text;
alter table public.retrip_events add column if not exists raw_json jsonb;
alter table public.retrip_events add column if not exists selected_alternative_json jsonb;
alter table public.retrip_events add column if not exists created_at timestamptz not null default now();

create index if not exists itinerary_items_plan_id_idx on public.itinerary_items(plan_id);
create index if not exists itinerary_items_user_id_idx on public.itinerary_items(user_id);
create index if not exists itinerary_items_local_item_id_idx on public.itinerary_items(local_item_id);
create index if not exists retrip_events_plan_id_idx on public.retrip_events(plan_id);
create index if not exists retrip_events_user_id_idx on public.retrip_events(user_id);
