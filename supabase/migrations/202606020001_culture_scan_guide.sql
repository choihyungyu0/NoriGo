create extension if not exists pgcrypto;

create table if not exists public.culture_guide_entries (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  object_key text not null,
  place_type text not null,
  category text not null,
  title_ko text not null,
  title_en text not null,
  short_question text,
  meaning text not null,
  etiquette text not null,
  story text,
  korean_phrase text,
  pronunciation text,
  phrase_meaning text,
  allowed_intents text[],
  blocked_topics text[],
  tags text[],
  is_active boolean not null default true
);

alter table public.culture_guide_entries add column if not exists created_at timestamptz not null default now();
alter table public.culture_guide_entries add column if not exists updated_at timestamptz not null default now();
alter table public.culture_guide_entries add column if not exists object_key text;
alter table public.culture_guide_entries add column if not exists place_type text;
alter table public.culture_guide_entries add column if not exists category text;
alter table public.culture_guide_entries add column if not exists title_ko text;
alter table public.culture_guide_entries add column if not exists title_en text;
alter table public.culture_guide_entries add column if not exists short_question text;
alter table public.culture_guide_entries add column if not exists meaning text;
alter table public.culture_guide_entries add column if not exists etiquette text;
alter table public.culture_guide_entries add column if not exists story text;
alter table public.culture_guide_entries add column if not exists korean_phrase text;
alter table public.culture_guide_entries add column if not exists pronunciation text;
alter table public.culture_guide_entries add column if not exists phrase_meaning text;
alter table public.culture_guide_entries add column if not exists allowed_intents text[];
alter table public.culture_guide_entries add column if not exists blocked_topics text[];
alter table public.culture_guide_entries add column if not exists tags text[];
alter table public.culture_guide_entries add column if not exists is_active boolean not null default true;

create unique index if not exists culture_guide_entries_object_key_idx
  on public.culture_guide_entries(object_key);
create index if not exists culture_guide_entries_place_type_idx
  on public.culture_guide_entries(place_type);
create index if not exists culture_guide_entries_category_idx
  on public.culture_guide_entries(category);
create index if not exists culture_guide_entries_tags_idx
  on public.culture_guide_entries using gin(tags);

insert into public.culture_guide_entries (
  object_key,
  place_type,
  category,
  title_ko,
  title_en,
  short_question,
  meaning,
  etiquette,
  story,
  korean_phrase,
  pronunciation,
  phrase_meaning,
  allowed_intents,
  blocked_topics,
  tags,
  is_active
) values
  (
    'temple_stone_stack',
    'temple',
    'temple_etiquette',
    '사찰 돌탑',
    'Temple stone stack',
    'Why do people stack stones at temples?',
    'Small stone stacks often express a quiet wish for health, peace, or good fortune.',
    'Look without touching existing stacks. If signs allow it, add one small stone gently and keep the area tidy.',
    'At Korean temples, stone stacks are treated as personal wishes rather than photo props.',
    '소원 성취하세요',
    'so-won seong-chwi-ha-se-yo',
    'May your wish come true.',
    array['understand_etiquette','travel_behavior','ask_phrase'],
    array['religious_debate','politics','historical_controversy'],
    array['stone_stack','wish','temple','bulguksa'],
    true
  ),
  (
    'restaurant_call_bell',
    'restaurant',
    'restaurant_etiquette',
    '식당 호출벨',
    'Restaurant call bell',
    'Is it polite to press the call bell?',
    'Many Korean restaurants use call bells so guests can ask for service without waving loudly.',
    'Press once, wait, and keep your request short and polite. Repeated pressing can feel impatient.',
    'The bell helps staff cover many tables quickly while keeping the dining room calm.',
    '여기요',
    'yeo-gi-yo',
    'Excuse me, over here please.',
    array['understand_etiquette','order_food','ask_service'],
    array['labor_conflict','national_character'],
    array['call_bell','restaurant','service','ordering'],
    true
  ),
  (
    'subway_pregnant_seat',
    'subway',
    'transit_etiquette',
    '임산부 배려석',
    'Pregnant priority seat',
    'Can I sit in the pink subway seat?',
    'Pink subway seats are reserved to make pregnancy support visible and easy.',
    'Avoid sitting there even when the train looks quiet. Choose another seat unless you are pregnant.',
    'The color helps people offer space without asking personal questions.',
    '먼저 앉으세요',
    'meon-jeo an-jeu-se-yo',
    'Please sit first.',
    array['understand_etiquette','transit_behavior'],
    array['gender_politics','social_conflict'],
    array['subway','pregnant_seat','priority_seat','transit'],
    true
  ),
  (
    'cafe_quiet_work',
    'cafe',
    'cafe_etiquette',
    '조용한 카페 이용',
    'Quiet cafe culture',
    'Why is everyone so quiet in this cafe?',
    'Many cafes are used for studying, working, and calm conversation.',
    'Keep calls short, use headphones, and avoid taking a large table during busy hours if you are alone.',
    'Cafe culture in Korea often blends social space with study and work space.',
    '조용히 할게요',
    'jo-yong-hi hal-ge-yo',
    'I will keep it quiet.',
    array['understand_etiquette','cafe_behavior','work'],
    array['social_stereotypes'],
    array['cafe','quiet','work','study'],
    true
  ),
  (
    'kiosk_ordering',
    'cafe_or_restaurant',
    'ordering_etiquette',
    '키오스크 주문',
    'Kiosk ordering',
    'Should I order at the kiosk?',
    'Many cafes and casual restaurants use kiosks for ordering and payment before pickup.',
    'Check whether you need a table number, keep the line moving, and ask staff politely if the screen is confusing.',
    'Kiosks reduce waiting time but can be difficult for travelers, so asking for help is normal.',
    '도와주실 수 있나요?',
    'do-wa-ju-sil su in-na-yo',
    'Could you help me?',
    array['order_food','ask_help','travel_behavior'],
    array['technology_complaints'],
    array['kiosk','ordering','cafe','restaurant','payment'],
    true
  ),
  (
    'market_queue_ticket',
    'market',
    'market_etiquette',
    '시장 대기표',
    'Market queue ticket',
    'Why are people taking number tickets?',
    'Popular stalls may use numbered tickets so the line stays fair even in a crowded market.',
    'Take one ticket, stay nearby, and listen or watch for your number before ordering.',
    'The ticket system keeps busy stalls orderly without a long physical line.',
    '몇 번이에요?',
    'myeot beo-ni-e-yo',
    'What number is it?',
    array['queue','order_food','market_behavior'],
    array['merchant_disputes'],
    array['market','queue','ticket','waiting_number'],
    true
  ),
  (
    'market_cash_food',
    'market',
    'market_etiquette',
    '시장 현금과 음식 예절',
    'Market cash and food manners',
    'Can I pay by card and eat while walking?',
    'Many market stalls accept cards, but small cash can still help at older or very small stalls.',
    'Ask before paying, avoid blocking the stall while eating, and use the nearby bins or trays as directed.',
    'Traditional markets move quickly, so small courtesies help everyone share tight space.',
    '카드 돼요?',
    'ka-deu dwae-yo',
    'Do you take cards?',
    array['payment','food_manners','market_behavior'],
    array['economic_complaints'],
    array['market','cash','card','food','manners'],
    true
  ),
  (
    'palace_photo_etiquette',
    'palace',
    'photo_etiquette',
    '궁궐 사진 예절',
    'Palace photo etiquette',
    'Can I take photos here?',
    'Palaces welcome photos in many outdoor areas, but some interiors, ceremonies, or protected zones may restrict them.',
    'Follow signs, avoid flash where restricted, and do not block paths or step over low barriers for photos.',
    'Historic sites balance beautiful travel photos with preservation and visitor flow.',
    '사진 찍어도 되나요?',
    'sa-jin jji-geo-do dwe-na-yo',
    'May I take a photo?',
    array['photo','historic_site','travel_behavior'],
    array['historical_controversy'],
    array['palace','photo','etiquette','historic_site'],
    true
  ),
  (
    'hanok_resident_etiquette',
    'hanok_village',
    'resident_etiquette',
    '한옥마을 주민 배려',
    'Hanok village resident etiquette',
    'Why are there quiet signs in the village?',
    'Some hanok villages are real residential neighborhoods, not only photo zones.',
    'Keep voices low, avoid photographing private doors or windows, and stay on public paths.',
    'The best visit respects both the beauty of hanok and the privacy of people living there.',
    '조용히 지나갈게요',
    'jo-yong-hi ji-na-gal-ge-yo',
    'I will pass quietly.',
    array['resident_respect','photo','travel_behavior'],
    array['privacy_conflict','social_stereotypes'],
    array['hanok','resident','quiet','photo','village'],
    true
  ),
  (
    'waiting_number_ticket',
    'restaurant',
    'restaurant_etiquette',
    '식당 대기번호',
    'Restaurant waiting number ticket',
    'How do waiting numbers work?',
    'Busy restaurants may ask guests to register or take a number before being seated.',
    'Enter your party size, watch the display, and return quickly when your number is called.',
    'Number systems make busy restaurants fairer and reduce crowding at the door.',
    '대기번호가 몇 번인가요?',
    'dae-gi-beon-ho-ga myeot beo-nin-ga-yo',
    'What waiting number am I?',
    array['restaurant_waiting','queue','travel_behavior'],
    array['service_complaints'],
    array['restaurant','waiting_number','queue','ticket'],
    true
  )
on conflict (object_key) do update set
  place_type = excluded.place_type,
  category = excluded.category,
  title_ko = excluded.title_ko,
  title_en = excluded.title_en,
  short_question = excluded.short_question,
  meaning = excluded.meaning,
  etiquette = excluded.etiquette,
  story = excluded.story,
  korean_phrase = excluded.korean_phrase,
  pronunciation = excluded.pronunciation,
  phrase_meaning = excluded.phrase_meaning,
  allowed_intents = excluded.allowed_intents,
  blocked_topics = excluded.blocked_topics,
  tags = excluded.tags,
  is_active = excluded.is_active,
  updated_at = now();

create table if not exists public.culture_scan_records (
  id uuid primary key default gen_random_uuid(),
  user_id uuid,
  created_at timestamptz not null default now(),
  location_name text,
  place_type text,
  detected_object text,
  korean_keyword text,
  user_intent text,
  user_language text,
  source_type text,
  source_badge text,
  ennoia_succeeded boolean not null default false,
  response_json jsonb,
  image_path text
);

alter table public.culture_scan_records add column if not exists user_id uuid;
alter table public.culture_scan_records add column if not exists created_at timestamptz not null default now();
alter table public.culture_scan_records add column if not exists location_name text;
alter table public.culture_scan_records add column if not exists place_type text;
alter table public.culture_scan_records add column if not exists detected_object text;
alter table public.culture_scan_records add column if not exists korean_keyword text;
alter table public.culture_scan_records add column if not exists user_intent text;
alter table public.culture_scan_records add column if not exists user_language text;
alter table public.culture_scan_records add column if not exists source_type text;
alter table public.culture_scan_records add column if not exists source_badge text;
alter table public.culture_scan_records add column if not exists ennoia_succeeded boolean not null default false;
alter table public.culture_scan_records add column if not exists response_json jsonb;
alter table public.culture_scan_records add column if not exists image_path text;

create index if not exists culture_scan_records_user_id_idx
  on public.culture_scan_records(user_id);
create index if not exists culture_scan_records_created_at_idx
  on public.culture_scan_records(created_at desc);

alter table public.culture_guide_entries enable row level security;
alter table public.culture_scan_records enable row level security;

drop policy if exists "Authenticated users can read culture guide entries"
  on public.culture_guide_entries;
create policy "Authenticated users can read culture guide entries"
  on public.culture_guide_entries
  for select
  to authenticated
  using (is_active = true);

drop policy if exists "Users can read their own culture scan records"
  on public.culture_scan_records;
create policy "Users can read their own culture scan records"
  on public.culture_scan_records
  for select
  to authenticated
  using (user_id = auth.uid());

drop policy if exists "Users can insert their own culture scan records"
  on public.culture_scan_records;
create policy "Users can insert their own culture scan records"
  on public.culture_scan_records
  for insert
  to authenticated
  with check (user_id = auth.uid());
