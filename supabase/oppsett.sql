-- Oppsett av databasen for Hjemme-appen: fryser, bod og rydding.
-- Kjøres én gang i et nytt Supabase-prosjekt (SQL Editor, eller av Claude via Supabase-koblingen).
-- Filen kan trygt kjøres flere ganger: ingenting slettes, og startdata legges bare inn hvis tabellene er tomme.
--
-- Tilgang: alle som har lenken til appen kan lese og endre (ingen innlogging), som i originalappen.
-- Morgenvarselet for Rydding settes opp etterpå med supabase/varsel.sql.

-- =====================================================================
-- Fryser
-- =====================================================================

create table if not exists rooms (
  id uuid primary key default gen_random_uuid(),
  slug text not null unique,                 -- «felles» er fryseren på forsiden
  person1_name text default 'Person 1',
  person2_name text default 'Person 2',
  person3_name text default 'Person 3',
  created_at timestamptz default now()
);

create table if not exists items (
  id uuid primary key default gen_random_uuid(),
  room_id uuid references rooms(id) on delete cascade,
  name text not null,
  quantity numeric not null default 0,
  unit text default 'stk',
  owner text default 'ukjent',
  note text,
  added_at timestamptz default now(),
  updated_at timestamptz default now(),
  status text default 'active' check (status in ('active', 'archived'))
);

create table if not exists history (
  id uuid primary key default gen_random_uuid(),
  room_id uuid references rooms(id) on delete cascade,
  item_id uuid,
  item_name text not null,
  action text not null,
  owner text,
  quantity_before numeric,
  quantity_after numeric,
  "timestamp" timestamptz default now()
);

create index if not exists idx_items_room_status on items(room_id, status);
create index if not exists idx_history_room on history(room_id, "timestamp" desc);

create or replace function update_updated_at_column() returns trigger
language plpgsql set search_path = '' as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists update_items_updated_at on items;
create trigger update_items_updated_at before update on items
  for each row execute function update_updated_at_column();

insert into rooms (slug) values ('felles') on conflict (slug) do nothing;

alter table rooms enable row level security;
alter table items enable row level security;
alter table history enable row level security;

drop policy if exists "Alle kan lese og endre frysere" on rooms;
create policy "Alle kan lese og endre frysere" on rooms for all to anon, authenticated using (true) with check (true);
drop policy if exists "Alle kan lese og endre varer" on items;
create policy "Alle kan lese og endre varer" on items for all to anon, authenticated using (true) with check (true);
drop policy if exists "Alle kan lese og endre historikk i fryseren" on history;
create policy "Alle kan lese og endre historikk i fryseren" on history for all to anon, authenticated using (true) with check (true);

grant select, insert, update, delete on rooms, items, history to anon, authenticated;

do $$ begin alter publication supabase_realtime add table rooms; exception when duplicate_object then null; end $$;
do $$ begin alter publication supabase_realtime add table items; exception when duplicate_object then null; end $$;
do $$ begin alter publication supabase_realtime add table history; exception when duplicate_object then null; end $$;

-- =====================================================================
-- Bod: bokser, kofferter og annet, og hva som ligger i dem
-- =====================================================================

create table if not exists storage_boxes (
  id uuid primary key default gen_random_uuid(),
  kind text not null default 'box' check (kind in ('box', 'bin', 'suitcase', 'cardboard', 'loose')),
  size text not null default 'normal' check (size in ('normal', 'low', 'long')),
  number int unique,                                   -- nummeret på lappen (plastboksene)
  label text not null default '',
  color text not null default 'clear',
  placement text not null default 'shelf' check (placement in ('shelf', 'floor', 'elsewhere', 'stacked')),
  shelf text check (shelf in ('A', 'B')),              -- A = innerst, B = høyre vegg
  level int check (level between 1 and 4),             -- 1 = nederst, 3 = øverst, 4 = oppå hylla
  slot int check (slot between 1 and 4),               -- 1 = lengst til venstre
  pos_x real,                                          -- plass på gulvet, meter fra venstre vegg
  pos_z real,                                          -- plass på gulvet, meter fra innerste vegg
  rotation real not null default 0,                    -- grader
  stack_on uuid references storage_boxes(id) on delete set null, -- boksen den står oppå
  location text not null default '',                   -- hvor den står hvis den ikke er i boden
  room text not null default 'kjeller' check (room in ('kjeller', 'loft')), -- hvilken bod
  created_at timestamptz not null default now()
);

create table if not exists storage_items (
  id uuid primary key default gen_random_uuid(),
  box_id uuid not null references storage_boxes(id) on delete cascade,
  name text not null,
  created_at timestamptz not null default now()
);

create index if not exists storage_items_box_id_idx on storage_items(box_id);
create index if not exists storage_boxes_stack_on_idx on storage_boxes(stack_on);

alter table storage_boxes enable row level security;
alter table storage_items enable row level security;

drop policy if exists "Alle kan lese og endre bokser" on storage_boxes;
create policy "Alle kan lese og endre bokser" on storage_boxes for all to anon, authenticated using (true) with check (true);
drop policy if exists "Alle kan lese og endre innhold" on storage_items;
create policy "Alle kan lese og endre innhold" on storage_items for all to anon, authenticated using (true) with check (true);

grant select, insert, update, delete on storage_boxes, storage_items to anon, authenticated;

do $$ begin alter publication supabase_realtime add table storage_boxes; exception when duplicate_object then null; end $$;
do $$ begin alter publication supabase_realtime add table storage_items; exception when duplicate_object then null; end $$;

-- Boden starter tom. Eksempeldata vises med /bod?demo (fra lib/bodSeed.json).

-- =====================================================================
-- Rydding: faste oppgaver, historikk og innstillinger
-- Tabellene heter chore_* fordi fryseren allerede bruker navnet «rooms».
-- =====================================================================
create table if not exists chore_rooms (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  sort_order int not null default 0,
  created_at timestamptz not null default now()
);

create table if not exists chores (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  room_id uuid not null references chore_rooms(id) on delete restrict,
  interval_weeks int not null check (interval_weeks > 0),
  priority text not null default 'medium' check (priority in ('high', 'medium', 'low')),
  est_minutes int not null default 15 check (est_minutes > 0),        -- aktiv innsats i minutter
  fixed_months int[] check (                                         -- f.eks. {4,10} = april og oktober
    fixed_months is null
    or (cardinality(fixed_months) > 0 and fixed_months <@ array[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12])
  ),
  purchase_item text,                                                -- null = ingen innkjøp
  purchase_done_for date,                                            -- fristen varen er kjøpt for
  notes text,
  snoozed_until date,                                                -- utsatt til denne ryddedagen
  initial_due date,                                                  -- startfrist før første gang er registrert
  archived boolean not null default false,                           -- arkivert, historikken beholdes
  created_at timestamptz not null default now()
);

create index if not exists chores_room_id_idx on chores(room_id);

create table if not exists chore_completions (
  id uuid primary key default gen_random_uuid(),
  chore_id uuid not null references chores(id) on delete cascade,
  done_on date not null default ((now() at time zone 'Europe/Oslo')::date), -- norsk dato, ikke UTC
  created_at timestamptz not null default now(),
  unique (chore_id, done_on)                                         -- ett «gjort» per oppgave per dag
);

create table if not exists chore_settings (
  id int primary key default 1 check (id = 1),                       -- bare én rad
  cleaning_weekday int not null default 0 check (cleaning_weekday between 0 and 6), -- 0 = søndag, 4 = torsdag
  cap_minutes int not null default 105 check (cap_minutes > 0),
  notify_time time not null default '09:00',
  cap_today int check (cap_today > 0),                               -- minutter i dag, null = vanlig tid
  cap_today_on date,                                                 -- dagen cap_today gjelder for
  notify_sent_on date                                                -- dagen morgenvarselet sist ble sendt
);

insert into chore_settings (id) values (1) on conflict (id) do nothing;

-- Samme tilgang som fryseren og boden: alle med lenken kan lese og endre.
alter table chore_rooms enable row level security;
alter table chores enable row level security;
alter table chore_completions enable row level security;
alter table chore_settings enable row level security;

drop policy if exists "Alle kan lese og endre rom" on chore_rooms;
create policy "Alle kan lese og endre rom" on chore_rooms
  for all to anon, authenticated using (true) with check (true);

drop policy if exists "Alle kan lese og endre oppgaver" on chores;
create policy "Alle kan lese og endre oppgaver" on chores
  for all to anon, authenticated using (true) with check (true);

drop policy if exists "Alle kan lese og endre historikk" on chore_completions;
create policy "Alle kan lese og endre historikk" on chore_completions
  for all to anon, authenticated using (true) with check (true);

drop policy if exists "Alle kan lese og endre innstillinger" on chore_settings;
create policy "Alle kan lese og endre innstillinger" on chore_settings
  for all to anon, authenticated using (true) with check (true);

grant select, insert, update, delete on chore_rooms, chores, chore_completions, chore_settings to anon, authenticated;

-- Sanntidsoppdatering mellom mobilene
do $$ begin
  alter publication supabase_realtime add table chore_rooms;
exception when duplicate_object then null; end $$;
do $$ begin
  alter publication supabase_realtime add table chores;
exception when duplicate_object then null; end $$;
do $$ begin
  alter publication supabase_realtime add table chore_completions;
exception when duplicate_object then null; end $$;
do $$ begin
  alter publication supabase_realtime add table chore_settings;
exception when duplicate_object then null; end $$;

-- Startdata: 7 rom og 48 oppgaver (hoppes over hvis det allerede finnes rom).
-- Generert fra lib/ryddingSeed.json.
do $$
begin
  if exists (select 1 from chore_rooms) then
    raise notice 'Ryddingen har allerede rom, startdata hoppes over';
    return;
  end if;

  insert into chore_rooms (name, sort_order) values
    ('Kjøkken', 1),
    ('Bad', 2),
    ('Soverom', 3),
    ('Stue', 4),
    ('Gjesterom', 5),
    ('Entré', 6),
    ('Hele boligen', 7);

  insert into chores (room_id, name, interval_weeks, priority, est_minutes, fixed_months, purchase_item)
  select r.id, v.name, v.interval_weeks, v.priority, v.est_minutes, v.fixed_months::int[], v.purchase_item
  from (values
    ('Kjøkken', 'Vaske kjøkkenhåndklær og kluter', 1, 'high', 5, null, null),
    ('Kjøkken', 'Rydde kjøleskapet for gammel mat', 1, 'high', 10, null, null),
    ('Kjøkken', 'Rense kaffemaskinen', 4, 'medium', 10, null, 'Rensetabletter'),
    ('Kjøkken', 'Vaske søppelbøtter', 4, 'medium', 15, null, null),
    ('Kjøkken', 'Rense filter i oppvaskmaskinen', 8, 'medium', 10, null, null),
    ('Kjøkken', 'Tørke fronter og håndtak på kjøkkenskap', 8, 'low', 15, null, null),
    ('Kjøkken', 'Avkalke kaffemaskinen', 12, 'medium', 10, null, 'Avkalkingsmiddel'),
    ('Kjøkken', 'Bytte/vaske filtermatte i kjøkkenvifta', 12, 'medium', 10, null, 'Filtermatte'),
    ('Kjøkken', 'Vaske kjøleskapet innvendig', 12, 'medium', 30, null, null),
    ('Kjøkken', 'Gå gjennom fryseren', 12, 'low', 15, null, null),
    ('Kjøkken', 'Rengjøre stekeovnen', 12, 'medium', 45, null, null),
    ('Kjøkken', 'Rense vannlåsen under vasken', 26, 'low', 20, null, null),
    ('Kjøkken', 'Slipe kniver', 26, 'low', 15, null, null),
    ('Kjøkken', 'Vaske kjøkkenskap innvendig', 26, 'low', 60, null, null),
    ('Kjøkken', 'Avrime fryseren', 52, 'medium', 30, null, null),
    ('Kjøkken', 'Støvsuge bak kjøleskapet', 52, 'low', 15, null, null),
    ('Kjøkken', 'Vaske vegger og tak på kjøkkenet', 52, 'low', 60, null, null),
    ('Bad', 'Vaskemaskin: pakning, såpeskuff og tom 90°-vask', 4, 'medium', 15, null, null),
    ('Bad', 'Tørketrommel: skylle kondensator/filterblokk', 4, 'medium', 10, null, null),
    ('Bad', 'Vaske dusjen: vegger, spyle alt inkl. sluk', 8, 'medium', 30, null, null),
    ('Bad', 'Rense pumpefilteret på vaskemaskinen', 12, 'medium', 15, null, null),
    ('Bad', 'Bytte dobørste', 26, 'low', 2, null, 'Dobørste'),
    ('Bad', 'Se over silikonfugene', 52, 'low', 10, null, null),
    ('Bad', 'Vaske vegger og tak på badet', 52, 'low', 45, null, null),
    ('Soverom', 'Skifte sengetøy', 1, 'high', 15, null, null),
    ('Soverom', 'Tørke av nattbordene', 12, 'low', 5, null, null),
    ('Soverom', 'Vaske puter', 26, 'medium', 10, null, null),
    ('Soverom', 'Snu eller rotere madrassen', 26, 'low', 10, null, null),
    ('Soverom', 'Vaske boksene under senga', 26, 'low', 20, null, null),
    ('Soverom', 'Vaske dyner', 52, 'medium', 15, null, null),
    ('Soverom', 'Vaske klesskapene', 52, 'low', 45, null, null),
    ('Soverom', 'Vaske vegger og tak på soverommet', 52, 'low', 60, null, null),
    ('Stue', 'Vaske bokhyller og vitrineskap', 26, 'low', 45, null, null),
    ('Stue', 'Vaske putetrekkene på sofaen', 52, 'low', 15, null, null),
    ('Stue', 'Vaske vegger og tak i stua', 52, 'low', 60, null, null),
    ('Gjesterom', 'Tørke støv og lufte gjesterommet', 12, 'low', 10, null, null),
    ('Gjesterom', 'Vaske vegger og tak på gjesterommet', 52, 'low', 45, null, null),
    ('Entré', 'Riste eller vaske dørmatta', 4, 'low', 5, null, null),
    ('Entré', 'Rydde og vaske skohylla og yttertøyet', 12, 'low', 20, null, null),
    ('Entré', 'Vaske vegger og tak i entréen', 52, 'low', 30, null, null),
    ('Hele boligen', 'Rense robotstøvsugeren', 4, 'medium', 10, null, null),
    ('Hele boligen', 'Moppe gulvene', 4, 'medium', 45, null, null),
    ('Hele boligen', 'Tørke støv av ventiler', 12, 'medium', 10, null, null),
    ('Hele boligen', 'Vaske lister', 12, 'low', 45, null, null),
    ('Hele boligen', 'Vaske vinduer', 26, 'low', 60, array[4, 10], null),
    ('Hele boligen', 'Bytte filteret i hovedvifta', 26, 'medium', 10, null, 'Ventilasjonsfilter'),
    ('Hele boligen', 'Bytte batteri i røykvarslerne', 52, 'high', 10, array[12], 'Batterier'),
    ('Hele boligen', 'Vaske gardiner', 52, 'low', 20, null, null)
  ) as v(room, name, interval_weeks, priority, est_minutes, fixed_months, purchase_item)
  join chore_rooms r on r.name = v.room;
end $$;

-- =====================================================================
-- Varsler: én rad per telefon som har slått på varsler
-- =====================================================================

create table if not exists push_subscriptions (
  id uuid primary key default gen_random_uuid(),
  endpoint text unique not null,   -- adressen varselet sendes til
  keys jsonb not null,             -- krypteringsnøklene fra telefonen (p256dh og auth)
  device text,                     -- f.eks. «iPhone», bare for å kjenne dem igjen
  created_at timestamptz not null default now(),
  last_sent_at timestamptz         -- sist et varsel kom fram
);

alter table push_subscriptions enable row level security;
drop policy if exists "Alle kan lese og endre varselabonnement" on push_subscriptions;
create policy "Alle kan lese og endre varselabonnement" on push_subscriptions for all to anon, authenticated using (true) with check (true);
grant select, insert, update, delete on push_subscriptions to anon, authenticated;
