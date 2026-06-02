alter table public.itinerary_plans
  add column if not exists user_id uuid;

alter table public.itinerary_items
  add column if not exists user_id uuid;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'itinerary_plans_user_id_fkey'
      and conrelid = 'public.itinerary_plans'::regclass
  ) then
    alter table public.itinerary_plans
      add constraint itinerary_plans_user_id_fkey
      foreign key (user_id)
      references auth.users(id)
      on delete cascade
      not valid;
  end if;
end $$;

create index if not exists itinerary_plans_user_id_idx
  on public.itinerary_plans(user_id);

create index if not exists itinerary_plans_user_created_idx
  on public.itinerary_plans(user_id, created_at desc);

alter table public.itinerary_plans enable row level security;

drop policy if exists "Authenticated users can read their own itinerary plans"
  on public.itinerary_plans;
create policy "Authenticated users can read their own itinerary plans"
  on public.itinerary_plans
  for select
  to authenticated
  using (auth.uid() is not null and auth.uid() = user_id);

drop policy if exists "Authenticated users can insert their own itinerary plans"
  on public.itinerary_plans;
create policy "Authenticated users can insert their own itinerary plans"
  on public.itinerary_plans
  for insert
  to authenticated
  with check (auth.uid() is not null and auth.uid() = user_id);

drop policy if exists "Authenticated users can update their own itinerary plans"
  on public.itinerary_plans;
create policy "Authenticated users can update their own itinerary plans"
  on public.itinerary_plans
  for update
  to authenticated
  using (auth.uid() is not null and auth.uid() = user_id)
  with check (auth.uid() is not null and auth.uid() = user_id);
