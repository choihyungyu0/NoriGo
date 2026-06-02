alter table public.itinerary_items enable row level security;

drop policy if exists "Authenticated users can read their own itinerary items"
  on public.itinerary_items;
create policy "Authenticated users can read their own itinerary items"
  on public.itinerary_items
  for select
  to authenticated
  using (auth.uid() is not null and auth.uid() = user_id);

drop policy if exists "Authenticated users can insert their own itinerary items"
  on public.itinerary_items;
create policy "Authenticated users can insert their own itinerary items"
  on public.itinerary_items
  for insert
  to authenticated
  with check (auth.uid() is not null and auth.uid() = user_id);

drop policy if exists "Authenticated users can update their own itinerary items"
  on public.itinerary_items;
create policy "Authenticated users can update their own itinerary items"
  on public.itinerary_items
  for update
  to authenticated
  using (auth.uid() is not null and auth.uid() = user_id)
  with check (auth.uid() is not null and auth.uid() = user_id);
