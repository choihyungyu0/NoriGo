create extension if not exists pgcrypto;

create table if not exists public.seoul_realtime_areas (
  id uuid primary key default gen_random_uuid(),
  area_nm text unique not null,
  area_code text,
  aliases text[] not null default '{}',
  lat double precision,
  lng double precision,
  coord_source text,
  coord_confidence text,
  is_estimated boolean not null default false,
  data_quality_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.seoul_realtime_areas add column if not exists area_code text;
alter table public.seoul_realtime_areas add column if not exists aliases text[] not null default '{}';
alter table public.seoul_realtime_areas add column if not exists lat double precision;
alter table public.seoul_realtime_areas add column if not exists lng double precision;
alter table public.seoul_realtime_areas add column if not exists coord_source text;
alter table public.seoul_realtime_areas add column if not exists coord_confidence text;
alter table public.seoul_realtime_areas add column if not exists is_estimated boolean not null default false;
alter table public.seoul_realtime_areas add column if not exists data_quality_note text;
alter table public.seoul_realtime_areas add column if not exists created_at timestamptz not null default now();
alter table public.seoul_realtime_areas add column if not exists updated_at timestamptz not null default now();

create index if not exists seoul_realtime_areas_aliases_gin_idx
  on public.seoul_realtime_areas using gin (aliases);

insert into public.seoul_realtime_areas (
  area_nm,
  area_code,
  aliases,
  coord_source,
  coord_confidence,
  is_estimated,
  data_quality_note
)
values
  (
    '북촌한옥마을',
    null,
    array['Bukchon Hanok Village', 'Bukchon', '북촌'],
    null,
    null,
    false,
    'Aliases are seeded for Seoul real-time city data AREA_NM matching. Coordinates are intentionally null until verified against an official source.'
  ),
  (
    '경복궁',
    null,
    array['Gyeongbokgung Palace', 'Gyeongbokgung', '경복궁'],
    null,
    null,
    false,
    'Aliases are seeded for Seoul real-time city data AREA_NM matching. Coordinates are intentionally null until verified against an official source.'
  ),
  (
    '광장시장',
    null,
    array['Gwangjang Market', 'Gwangjang', '광장시장'],
    null,
    null,
    false,
    'Aliases are seeded for Seoul real-time city data AREA_NM matching. Coordinates are intentionally null until verified against an official source.'
  ),
  (
    '남산서울타워',
    null,
    array['N Seoul Tower', 'Namsan Tower', '남산서울타워'],
    null,
    null,
    false,
    'Aliases are seeded for Seoul real-time city data AREA_NM matching. Coordinates are intentionally null until verified against an official source.'
  ),
  (
    '명동 관광특구',
    null,
    array['Myeongdong', 'Myeongdong Seoul', '명동'],
    null,
    null,
    false,
    'Aliases are seeded for Seoul real-time city data AREA_NM matching. Coordinates are intentionally null until verified against an official source.'
  ),
  (
    '홍대 관광특구',
    null,
    array['Hongdae', 'Hongik University Street', '홍대'],
    null,
    null,
    false,
    'Aliases are seeded for Seoul real-time city data AREA_NM matching. Coordinates are intentionally null until verified against an official source.'
  ),
  (
    '익선동',
    null,
    array['Ikseondong', 'Ikseon-dong', '익선동'],
    null,
    null,
    false,
    'Aliases are seeded for Seoul real-time city data AREA_NM matching. Coordinates are intentionally null until verified against an official source.'
  ),
  (
    '성수카페거리',
    null,
    array['Seongsu', 'Seongsu Cafe Street', '성수'],
    null,
    null,
    false,
    'AREA_NM may need adjustment to 성수동 if Seoul citydata uses that official name; keep this row configurable.'
  ),
  (
    '잠실 관광특구',
    null,
    array['Jamsil', 'Lotte World', '잠실'],
    null,
    null,
    false,
    'Aliases are seeded for Seoul real-time city data AREA_NM matching. Coordinates are intentionally null until verified against an official source.'
  ),
  (
    '강남역',
    null,
    array['Gangnam Station', 'Gangnam', '강남역'],
    null,
    null,
    false,
    'Aliases are seeded for Seoul real-time city data AREA_NM matching. Coordinates are intentionally null until verified against an official source.'
  )
on conflict (area_nm) do update set
  aliases = excluded.aliases,
  data_quality_note = excluded.data_quality_note,
  updated_at = now();
