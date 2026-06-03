create table if not exists public.saved_places (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  place_name text not null,
  category text,
  latitude double precision,
  longitude double precision,
  image_url text,
  tags text[],
  source_type text,
  source_badge text,
  kto_content_id text,
  raw_json jsonb not null default '{}'::jsonb
);

alter table public.saved_places enable row level security;

drop policy if exists "saved_places_select_own" on public.saved_places;
create policy "saved_places_select_own"
on public.saved_places
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "saved_places_insert_own" on public.saved_places;
create policy "saved_places_insert_own"
on public.saved_places
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "saved_places_delete_own" on public.saved_places;
create policy "saved_places_delete_own"
on public.saved_places
for delete
to authenticated
using (auth.uid() = user_id);

create index if not exists saved_places_user_created_idx
on public.saved_places (user_id, created_at desc);
