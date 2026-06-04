create table if not exists public.user_consents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  data_consent boolean not null default false,
  data_consent_accepted_at timestamptz,
  location_consent boolean not null default false,
  location_consent_accepted_at timestamptz,
  location_permission_status text,
  consent_version text not null default '2026-06-03',
  raw_json jsonb not null default '{}'::jsonb
);

create unique index if not exists user_consents_user_id_unique
on public.user_consents (user_id)
where user_id is not null;

create or replace function public.set_user_consents_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists set_user_consents_updated_at on public.user_consents;
create trigger set_user_consents_updated_at
before update on public.user_consents
for each row
execute function public.set_user_consents_updated_at();

alter table public.user_consents enable row level security;

drop policy if exists "user_consents_select_own" on public.user_consents;
create policy "user_consents_select_own"
on public.user_consents
for select
to authenticated
using (auth.uid() = user_id);

drop policy if exists "user_consents_insert_own" on public.user_consents;
create policy "user_consents_insert_own"
on public.user_consents
for insert
to authenticated
with check (auth.uid() = user_id);

drop policy if exists "user_consents_update_own" on public.user_consents;
create policy "user_consents_update_own"
on public.user_consents
for update
to authenticated
using (auth.uid() = user_id)
with check (auth.uid() = user_id);
