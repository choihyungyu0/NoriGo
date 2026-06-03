insert into public.seoul_realtime_areas (
  area_nm,
  area_code,
  aliases,
  coord_source,
  coord_confidence,
  is_estimated,
  data_quality_note
)
values (
  '광화문·덕수궁',
  'POI009',
  array[
    'Gwanghwamun',
    'Gwanghwamun Plaza',
    'Deoksugung',
    'Deoksu Palace',
    '광화문',
    '덕수궁'
  ],
  null,
  null,
  false,
  'Official Seoul real-time citydata AREA_NM used by the Ennoia API connector default.'
)
on conflict (area_nm) do update set
  area_code = excluded.area_code,
  aliases = excluded.aliases,
  data_quality_note = excluded.data_quality_note,
  updated_at = now();
