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
    '광장(전통)시장',
    'POI060',
    array[
      'Gwangjang Market',
      'Gwangjang',
      '광장시장',
      '광장전통시장'
    ],
    null,
    null,
    false,
    'Official Seoul real-time citydata AREA_NM verified against the citydata_ppltn API.'
  ),
  (
    '남산공원',
    'POI091',
    array[
      'N Seoul Tower',
      'Namsan Tower',
      'N Seoul Tower Observatory',
      '남산서울타워',
      'N서울타워',
      '남산'
    ],
    null,
    null,
    false,
    'Official Seoul real-time citydata AREA_NM used as the nearest available Seoul real-time area for N Seoul Tower.'
  )
on conflict (area_nm) do update set
  area_code = excluded.area_code,
  aliases = excluded.aliases,
  data_quality_note = excluded.data_quality_note,
  updated_at = now();

delete from public.seoul_realtime_areas
where area_nm in ('광장시장', '남산서울타워');
