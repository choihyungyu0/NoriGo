insert into storage.buckets (id, name, public)
values ('culture-scans', 'culture-scans', false)
on conflict (id) do update
set public = excluded.public;

drop policy if exists "Users can upload their culture scan images"
  on storage.objects;
create policy "Users can upload their culture scan images"
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'culture-scans'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

drop policy if exists "Users can read their culture scan images"
  on storage.objects;
create policy "Users can read their culture scan images"
  on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'culture-scans'
    and auth.uid()::text = (storage.foldername(name))[1]
  );

alter table public.culture_scan_records
  add column if not exists image_path text;

alter table public.culture_scan_records
  add column if not exists detected_object_source text not null default 'manual';

alter table public.culture_scan_records
  add column if not exists vision_confidence double precision;

alter table public.culture_scan_records
  add column if not exists vision_alternatives jsonb;
