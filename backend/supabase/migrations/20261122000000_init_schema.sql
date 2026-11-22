-- =====================================================================
-- TRIPSY - Supabase schema LENGKAP (jalankan sekali di SQL Editor)
--
-- Cakupan : Register/Profile, AI Itinerary, Home, Discovery, Snapsy
-- Target  : proyek Supabase baru. Skrip ini dibuat idempotent (aman
--           dijalankan ulang bila sempat error di tengah jalan).
--
-- Desain ringkas:
--   * Semua data milik pengguna dilindungi RLS (hanya pemilik yang akses).
--   * Konten publik (destinasi, snap, profil, komentar, ulasan) bisa
--     dibaca tanpa login, tetapi hanya pemilik yang boleh mengubahnya.
--   * Kolom agregat (rating_avg, like_count, ...) dijaga TRIGGER dan
--     ditutup dari klien dengan grant per kolom.
--   * destinations = cache data Wikipedia (diisi lazy oleh Edge Function
--     memakai service_role). Klien hanya boleh MEMBACA tabel ini.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 0. Ekstensi & fungsi bantu
-- ---------------------------------------------------------------------
create extension if not exists pg_trgm with schema extensions;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ---------------------------------------------------------------------
-- 1. profiles
-- ---------------------------------------------------------------------
create table if not exists public.profiles (
  id           uuid primary key references auth.users (id) on delete cascade,
  username     text,
  display_name text,
  bio          text,
  avatar_url   text,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

-- username unik tanpa membedakan huruf besar/kecil ("Cesta" = "cesta")
create unique index if not exists profiles_username_lower_key
  on public.profiles (lower(username));

drop trigger if exists trg_profiles_updated on public.profiles;
create trigger trg_profiles_updated
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- Buat profil otomatis saat user mendaftar (email maupun Google)
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name',
             new.raw_user_meta_data ->> 'name',
             split_part(new.email, '@', 1))
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Backfill: user yang sudah ada sebelum skrip ini dijalankan
insert into public.profiles (id, display_name)
select u.id, split_part(u.email, '@', 1)
from auth.users u
on conflict (id) do nothing;

-- ---------------------------------------------------------------------
-- 2. destinations (cache Wikipedia + data katalog Discovery)
-- ---------------------------------------------------------------------
create table if not exists public.destinations (
  id             uuid primary key default gen_random_uuid(),
  slug           text not null unique,
  name           text not null,
  description    text,                         -- ringkasan (cache Wikipedia)
  category       text not null default 'lainnya'
                 check (category in ('alam','pantai','gunung','kota','budaya',
                                     'kuliner','belanja','hiburan','lainnya')),
  city           text,
  province       text,
  country        text not null default 'Indonesia',
  latitude       numeric(9,6) check (latitude  between -90  and 90),
  longitude      numeric(9,6) check (longitude between -180 and 180),
  image_url      text,                         -- thumbnail (cache Wikipedia)
  place_id       text,                         -- id tempat Maps API (opsional)
  price_estimate numeric(14,2),
  -- identitas & atribusi sumber Wikipedia
  wikipedia_lang    text not null default 'id',
  wikipedia_page_id bigint,
  wikipedia_title   text,
  wikipedia_url     text,                      -- tautan atribusi (CC BY-SA)
  wikidata_id       text,
  fetched_at        timestamptz,               -- kapan terakhir di-refresh
  -- agregat: diisi trigger dari destination_reviews, bukan oleh klien
  rating_avg     numeric(2,1) not null default 0,
  review_count   int not null default 0,
  created_at     timestamptz not null default now(),
  unique (wikipedia_lang, wikipedia_page_id)   -- kunci upsert Edge Function
);

create index if not exists idx_dest_category on public.destinations (category);
create index if not exists idx_dest_rating
  on public.destinations (rating_avg desc, review_count desc);
create index if not exists idx_dest_name_trgm
  on public.destinations using gin (name extensions.gin_trgm_ops);
create index if not exists idx_dest_city_trgm
  on public.destinations using gin (city extensions.gin_trgm_ops);

-- ---------------------------------------------------------------------
-- 3. AI Itinerary
-- ---------------------------------------------------------------------
create table if not exists public.itineraries (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references auth.users (id) on delete cascade,
  trip_name    text not null,
  budget       numeric(14,2),
  currency     text not null default 'IDR',
  ai_generated boolean not null default true,
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);
create index if not exists idx_itineraries_user on public.itineraries (user_id);

drop trigger if exists trg_itineraries_updated on public.itineraries;
create trigger trg_itineraries_updated
  before update on public.itineraries
  for each row execute function public.set_updated_at();

create table if not exists public.itinerary_preferences (
  id               uuid primary key default gen_random_uuid(),
  itinerary_id     uuid not null unique
                   references public.itineraries (id) on delete cascade,
  destination      text not null,
  start_date       date not null,
  end_date         date not null,
  travel_purpose   text,
  people_count     int not null default 1 check (people_count > 0),
  travel_companion text,                       -- solo / couple / family / group
  active_hours     text,                       -- mis. '08.00-21.00'
  extras           jsonb not null default '{}'::jsonb,
                                               -- tempo, makanan, transport, penginapan, with_kids
  created_at       timestamptz not null default now(),
  check (end_date >= start_date)
);

create table if not exists public.itinerary_days (
  id              uuid primary key default gen_random_uuid(),
  itinerary_id    uuid not null references public.itineraries (id) on delete cascade,
  trip_date       date not null,
  sort_order      int not null,
  location        text,
  weather_summary text,                        -- dari Weather API
  created_at      timestamptz not null default now(),
  unique (itinerary_id, sort_order)
);
create index if not exists idx_days_itinerary on public.itinerary_days (itinerary_id);

-- Aktivitas harian (target CRUD). destination_id boleh kosong: tidak semua
-- aktivitas punya halaman Wikipedia (mis. "check-in hotel").
create table if not exists public.itinerary_day_items (
  id             uuid primary key default gen_random_uuid(),
  day_id         uuid not null references public.itinerary_days (id) on delete cascade,
  destination_id uuid references public.destinations (id) on delete set null,
  time_slot      text,
  activity       text not null,
  location       text,
  category       text check (category in
                   ('transport','accommodation','food','activity','other')),
  description    text,
  image_url      text,
  rating         numeric(2,1) check (rating between 0 and 5),
  place_id       text,
  estimated_cost numeric(14,2) not null default 0,
  sort_order     int not null default 0,
  status         text not null default 'planned',
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);
create index if not exists idx_items_day on public.itinerary_day_items (day_id);
create index if not exists idx_items_destination
  on public.itinerary_day_items (destination_id);

drop trigger if exists trg_items_updated on public.itinerary_day_items;
create trigger trg_items_updated
  before update on public.itinerary_day_items
  for each row execute function public.set_updated_at();

create table if not exists public.itinerary_feedback (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references auth.users (id) on delete cascade,
  itinerary_id  uuid not null references public.itineraries (id) on delete cascade,
  rating        smallint not null check (rating between 1 and 5),
  feedback_text text,
  suggestion    text,
  created_at    timestamptz not null default now()
);
create index if not exists idx_feedback_itinerary
  on public.itinerary_feedback (itinerary_id);

-- ---------------------------------------------------------------------
-- 4. Discovery: ulasan & koleksi
-- ---------------------------------------------------------------------
create table if not exists public.destination_reviews (
  id             uuid primary key default gen_random_uuid(),
  destination_id uuid not null references public.destinations (id) on delete cascade,
  user_id        uuid not null references public.profiles (id) on delete cascade,
  rating         smallint not null check (rating between 1 and 5),
  comment        text,
  created_at     timestamptz not null default now(),
  unique (user_id, destination_id)             -- satu ulasan per user per tempat
);
create index if not exists idx_reviews_destination
  on public.destination_reviews (destination_id);

create table if not exists public.destination_bookmarks (
  user_id        uuid not null references public.profiles (id) on delete cascade,
  destination_id uuid not null references public.destinations (id) on delete cascade,
  created_at     timestamptz not null default now(),
  primary key (user_id, destination_id)
);

create or replace function public.refresh_destination_rating()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid;
begin
  if tg_op = 'DELETE' then
    v_id := old.destination_id;
  else
    v_id := new.destination_id;
  end if;

  update public.destinations d
  set rating_avg = coalesce((select round(avg(r.rating)::numeric, 1)
                             from public.destination_reviews r
                             where r.destination_id = v_id), 0),
      review_count = (select count(*)
                      from public.destination_reviews r
                      where r.destination_id = v_id)
  where d.id = v_id;
  return null;
end;
$$;

drop trigger if exists trg_reviews_refresh on public.destination_reviews;
create trigger trg_reviews_refresh
  after insert or update or delete on public.destination_reviews
  for each row execute function public.refresh_destination_rating();

-- ---------------------------------------------------------------------
-- 5. Snapsy (feed video ala reels)
-- Yang disimpan adalah PATH file di Storage, bukan URL penuh.
-- ---------------------------------------------------------------------
create table if not exists public.snaps (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid not null references public.profiles (id) on delete cascade,
  caption          text,
  media_path       text not null,              -- '<user_id>/<nama-file>'
  media_type       text not null default 'video'
                   check (media_type in ('video','image')),
  thumbnail_path   text,
  duration_seconds int check (duration_seconds is null or duration_seconds > 0),
  destination_id   uuid references public.destinations (id) on delete set null,
  like_count       int not null default 0,     -- dijaga trigger
  comment_count    int not null default 0,     -- dijaga trigger
  created_at       timestamptz not null default now()
);
create index if not exists idx_snaps_created on public.snaps (created_at desc);
create index if not exists idx_snaps_user
  on public.snaps (user_id, created_at desc);
create index if not exists idx_snaps_destination on public.snaps (destination_id);

create table if not exists public.snap_likes (
  snap_id    uuid not null references public.snaps (id) on delete cascade,
  user_id    uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (snap_id, user_id)               -- mencegah like ganda
);

create table if not exists public.snap_comments (
  id         uuid primary key default gen_random_uuid(),
  snap_id    uuid not null references public.snaps (id) on delete cascade,
  user_id    uuid not null references public.profiles (id) on delete cascade,
  body       text not null check (char_length(body) between 1 and 1000),
  created_at timestamptz not null default now()
);
create index if not exists idx_comments_snap
  on public.snap_comments (snap_id, created_at);

create or replace function public.bump_like_count()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    update public.snaps set like_count = like_count + 1 where id = new.snap_id;
  elsif tg_op = 'DELETE' then
    update public.snaps set like_count = greatest(like_count - 1, 0)
    where id = old.snap_id;
  end if;
  return null;
end;
$$;

drop trigger if exists trg_like_count on public.snap_likes;
create trigger trg_like_count
  after insert or delete on public.snap_likes
  for each row execute function public.bump_like_count();

create or replace function public.bump_comment_count()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    update public.snaps set comment_count = comment_count + 1 where id = new.snap_id;
  elsif tg_op = 'DELETE' then
    update public.snaps set comment_count = greatest(comment_count - 1, 0)
    where id = old.snap_id;
  end if;
  return null;
end;
$$;

drop trigger if exists trg_comment_count on public.snap_comments;
create trigger trg_comment_count
  after insert or delete on public.snap_comments
  for each row execute function public.bump_comment_count();

-- ---------------------------------------------------------------------
-- 6. PRIVILEGES
-- Hak diberi per KOLOM pada tabel yang punya agregat/counter, supaya
-- klien tidak bisa memalsukan like_count, rating_avg, dsb.
--
-- PENTING: sebagian proyek Supabase memberi ALL otomatis ke anon &
-- authenticated pada setiap tabel baru (default privileges / "Automatically
-- expose new tables"). Hak tingkat tabel itu MEMBATALKAN efek grant per
-- kolom, sehingga user tetap bisa menulis like_count dsb. Karena itu semua
-- hak dicabut dulu, lalu diberikan ulang secara eksplisit di bawah.
-- ---------------------------------------------------------------------
revoke all on
  public.profiles, public.destinations, public.itineraries,
  public.itinerary_preferences, public.itinerary_days,
  public.itinerary_day_items, public.itinerary_feedback,
  public.destination_reviews, public.destination_bookmarks,
  public.snaps, public.snap_likes, public.snap_comments
from anon, authenticated;

-- profiles (publik dibaca; hanya kolom identitas yang boleh ditulis)
grant select on public.profiles to anon, authenticated;
grant insert (id, username, display_name, bio, avatar_url)
  on public.profiles to authenticated;
grant update (username, display_name, bio, avatar_url)
  on public.profiles to authenticated;

-- itinerary & turunannya: privat, hanya authenticated
grant select, insert, update, delete on
  public.itineraries,
  public.itinerary_preferences,
  public.itinerary_days,
  public.itinerary_day_items,
  public.itinerary_feedback
to authenticated;

-- destinations: baca publik; tulis hanya via service_role (Edge Function)
grant select on public.destinations to anon, authenticated;

-- destination_reviews
grant select on public.destination_reviews to anon, authenticated;
grant insert (destination_id, user_id, rating, comment)
  on public.destination_reviews to authenticated;
grant update (rating, comment) on public.destination_reviews to authenticated;
grant delete on public.destination_reviews to authenticated;

-- destination_bookmarks (privat)
grant select, delete on public.destination_bookmarks to authenticated;
grant insert (user_id, destination_id)
  on public.destination_bookmarks to authenticated;

-- snaps
grant select on public.snaps to anon, authenticated;
grant insert (user_id, caption, media_path, media_type, thumbnail_path,
              duration_seconds, destination_id)
  on public.snaps to authenticated;
grant update (caption, destination_id) on public.snaps to authenticated;
grant delete on public.snaps to authenticated;

-- snap_likes (privat: user hanya melihat like miliknya)
grant select, delete on public.snap_likes to authenticated;
grant insert (snap_id, user_id) on public.snap_likes to authenticated;

-- snap_comments
grant select on public.snap_comments to anon, authenticated;
grant insert (snap_id, user_id, body) on public.snap_comments to authenticated;
grant update (body) on public.snap_comments to authenticated;
grant delete on public.snap_comments to authenticated;

-- service_role (dipakai Edge Function): akses penuh ke tabel aplikasi
grant all on
  public.profiles, public.destinations, public.itineraries,
  public.itinerary_preferences, public.itinerary_days,
  public.itinerary_day_items, public.itinerary_feedback,
  public.destination_reviews, public.destination_bookmarks,
  public.snaps, public.snap_likes, public.snap_comments
to service_role;

-- ---------------------------------------------------------------------
-- 7. ROW LEVEL SECURITY
-- ---------------------------------------------------------------------
alter table public.profiles              enable row level security;
alter table public.destinations          enable row level security;
alter table public.itineraries           enable row level security;
alter table public.itinerary_preferences enable row level security;
alter table public.itinerary_days        enable row level security;
alter table public.itinerary_day_items   enable row level security;
alter table public.itinerary_feedback    enable row level security;
alter table public.destination_reviews   enable row level security;
alter table public.destination_bookmarks enable row level security;
alter table public.snaps                 enable row level security;
alter table public.snap_likes            enable row level security;
alter table public.snap_comments         enable row level security;

-- Bersihkan policy lama milik skema ini agar skrip bisa dijalankan ulang
do $$
declare
  r record;
begin
  for r in
    select schemaname, tablename, policyname
    from pg_policies
    where (schemaname = 'public' and tablename in (
            'profiles','destinations','itineraries','itinerary_preferences',
            'itinerary_days','itinerary_day_items','itinerary_feedback',
            'destination_reviews','destination_bookmarks','snaps',
            'snap_likes','snap_comments'))
       or (schemaname = 'storage' and tablename = 'objects'
           and policyname ~ '^(avatars|snaps_files)_')
  loop
    execute format('drop policy %I on %I.%I',
                   r.policyname, r.schemaname, r.tablename);
  end loop;
end
$$;

-- profiles: publik dibaca, ubah hanya profil sendiri
create policy "profiles_select_public" on public.profiles
  for select to anon, authenticated using (true);
create policy "profiles_insert_own" on public.profiles
  for insert to authenticated with check ((select auth.uid()) = id);
create policy "profiles_update_own" on public.profiles
  for update to authenticated
  using ((select auth.uid()) = id) with check ((select auth.uid()) = id);

-- destinations: hanya SELECT. Tanpa policy tulis = klien tidak bisa menulis
create policy "destinations_read_public" on public.destinations
  for select to anon, authenticated using (true);

-- itineraries: CRUD penuh untuk pemilik
create policy "itineraries_owner_all" on public.itineraries
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

-- tabel anak: kepemilikan diperiksa lewat itineraries
create policy "prefs_owner_all" on public.itinerary_preferences
  for all to authenticated
  using (exists (select 1 from public.itineraries i
                 where i.id = itinerary_id and i.user_id = (select auth.uid())))
  with check (exists (select 1 from public.itineraries i
                 where i.id = itinerary_id and i.user_id = (select auth.uid())));

create policy "days_owner_all" on public.itinerary_days
  for all to authenticated
  using (exists (select 1 from public.itineraries i
                 where i.id = itinerary_id and i.user_id = (select auth.uid())))
  with check (exists (select 1 from public.itineraries i
                 where i.id = itinerary_id and i.user_id = (select auth.uid())));

create policy "items_owner_all" on public.itinerary_day_items
  for all to authenticated
  using (exists (select 1
                 from public.itinerary_days d
                 join public.itineraries i on i.id = d.itinerary_id
                 where d.id = day_id and i.user_id = (select auth.uid())))
  with check (exists (select 1
                 from public.itinerary_days d
                 join public.itineraries i on i.id = d.itinerary_id
                 where d.id = day_id and i.user_id = (select auth.uid())));

create policy "feedback_owner_all" on public.itinerary_feedback
  for all to authenticated
  using ((select auth.uid()) = user_id)
  with check ((select auth.uid()) = user_id);

-- destination_reviews
create policy "reviews_read_public" on public.destination_reviews
  for select to anon, authenticated using (true);
create policy "reviews_insert_own" on public.destination_reviews
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "reviews_update_own" on public.destination_reviews
  for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "reviews_delete_own" on public.destination_reviews
  for delete to authenticated using ((select auth.uid()) = user_id);

-- destination_bookmarks
create policy "bookmarks_select_own" on public.destination_bookmarks
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "bookmarks_insert_own" on public.destination_bookmarks
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "bookmarks_delete_own" on public.destination_bookmarks
  for delete to authenticated using ((select auth.uid()) = user_id);

-- snaps: media_path wajib berada di folder milik user
create policy "snaps_read_public" on public.snaps
  for select to anon, authenticated using (true);
create policy "snaps_insert_own" on public.snaps
  for insert to authenticated
  with check ((select auth.uid()) = user_id
              and media_path like (select auth.uid())::text || '/%');
create policy "snaps_update_own" on public.snaps
  for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "snaps_delete_own" on public.snaps
  for delete to authenticated using ((select auth.uid()) = user_id);

-- snap_likes
create policy "likes_select_own" on public.snap_likes
  for select to authenticated using ((select auth.uid()) = user_id);
create policy "likes_insert_own" on public.snap_likes
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "likes_delete_own" on public.snap_likes
  for delete to authenticated using ((select auth.uid()) = user_id);

-- snap_comments
create policy "comments_read_public" on public.snap_comments
  for select to anon, authenticated using (true);
create policy "comments_insert_own" on public.snap_comments
  for insert to authenticated with check ((select auth.uid()) = user_id);
create policy "comments_update_own" on public.snap_comments
  for update to authenticated
  using ((select auth.uid()) = user_id) with check ((select auth.uid()) = user_id);
create policy "comments_delete_own" on public.snap_comments
  for delete to authenticated using ((select auth.uid()) = user_id);

-- ---------------------------------------------------------------------
-- 8. STORAGE: bucket avatars & snaps
-- Konvensi path: '<user_id>/<nama-file>'. Bucket publik: file bisa
-- ditampilkan lewat URL; policy di bawah hanya membatasi PENULISAN.
-- Saran untuk frontend: pakai nama file unik (uuid), hindari upsert.
-- ---------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('avatars', 'avatars', true, 2097152,
     array['image/jpeg','image/png','image/webp']),
  ('snaps',   'snaps',   true, 52428800,
     array['video/mp4','video/quicktime','image/jpeg','image/png','image/webp'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

create policy "avatars_select_own" on storage.objects
  for select to authenticated
  using (bucket_id = 'avatars'
         and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy "avatars_insert_own" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'avatars'
              and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy "avatars_update_own" on storage.objects
  for update to authenticated
  using (bucket_id = 'avatars'
         and (storage.foldername(name))[1] = (select auth.uid())::text)
  with check (bucket_id = 'avatars'
              and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy "avatars_delete_own" on storage.objects
  for delete to authenticated
  using (bucket_id = 'avatars'
         and (storage.foldername(name))[1] = (select auth.uid())::text);

create policy "snaps_files_select_own" on storage.objects
  for select to authenticated
  using (bucket_id = 'snaps'
         and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy "snaps_files_insert_own" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'snaps'
              and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy "snaps_files_update_own" on storage.objects
  for update to authenticated
  using (bucket_id = 'snaps'
         and (storage.foldername(name))[1] = (select auth.uid())::text)
  with check (bucket_id = 'snaps'
              and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy "snaps_files_delete_own" on storage.objects
  for delete to authenticated
  using (bucket_id = 'snaps'
         and (storage.foldername(name))[1] = (select auth.uid())::text);

-- ---------------------------------------------------------------------
-- 9. HOME: satu RPC agregator (tanpa tabel baru)
-- security invoker => RLS tetap berlaku (itinerary hanya milik pemanggil;
-- tamu otomatis mendapat daftar itinerary kosong).
-- Flutter: supabase.rpc('home_feed', params: {'p_limit': 10})
-- ---------------------------------------------------------------------
-- Ditulis dengan plpgsql agar query itinerary HANYA dijalankan untuk user
-- yang login. Tamu (anon) tidak punya hak apa pun atas tabel itineraries,
-- dan hak itu memang tidak diberikan; versi SQL murni akan error untuk tamu
-- karena izin tabel diperiksa saat query dimulai.
create or replace function public.home_feed(p_limit int default 10)
returns jsonb
language plpgsql
stable
security invoker
set search_path = ''
as $$
declare
  v_destinations jsonb;
  v_itineraries  jsonb := '[]'::jsonb;
  v_snaps        jsonb;
begin
  select coalesce(jsonb_agg(x order by x.rating_avg desc, x.review_count desc),
                  '[]'::jsonb)
  into v_destinations
  from (select d.id, d.slug, d.name, d.category, d.city, d.image_url,
               d.rating_avg, d.review_count
        from public.destinations d
        order by d.rating_avg desc, d.review_count desc
        limit p_limit) x;

  if (select auth.uid()) is not null then
    select coalesce(jsonb_agg(x order by x.created_at desc), '[]'::jsonb)
    into v_itineraries
    from (select i.id, i.trip_name, i.budget, i.currency, i.created_at
          from public.itineraries i
          where i.user_id = (select auth.uid())
          order by i.created_at desc
          limit p_limit) x;
  end if;

  select coalesce(jsonb_agg(x order by x.created_at desc), '[]'::jsonb)
  into v_snaps
  from (select s.id, s.user_id, s.caption, s.thumbnail_path,
               s.like_count, s.comment_count, s.created_at
        from public.snaps s
        order by s.created_at desc
        limit p_limit) x;

  return jsonb_build_object(
    'destinations', v_destinations,
    'itineraries',  v_itineraries,
    'snaps',        v_snaps
  );
end;
$$;

grant execute on function public.home_feed(int) to anon, authenticated;

-- ---------------------------------------------------------------------
-- 10. SEED: destinasi contoh untuk cold start Discovery
-- Koordinat perkiraan. Edge Function sebaiknya mencocokkan lewat slug lebih
-- dulu lalu mengisi kolom wikipedia_* agar tidak terjadi duplikat.
-- ---------------------------------------------------------------------
insert into public.destinations
  (slug, name, description, category, city, province, latitude, longitude)
values
  ('pulau-padar', 'Pulau Padar',
   'Pulau di kawasan Taman Nasional Komodo dengan jalur pendakian menuju panorama tiga teluk.',
   'alam', 'Labuan Bajo', 'Nusa Tenggara Timur', -8.654000, 119.581000),
  ('candi-borobudur', 'Candi Borobudur',
   'Candi Buddha abad ke-9 di Magelang, situs warisan dunia UNESCO.',
   'budaya', 'Magelang', 'Jawa Tengah', -7.607900, 110.203800),
  ('gunung-bromo', 'Gunung Bromo',
   'Gunung api aktif di kawasan Bromo Tengger Semeru, populer untuk wisata matahari terbit.',
   'gunung', 'Probolinggo', 'Jawa Timur', -7.942500, 112.953000),
  ('ubud', 'Ubud',
   'Pusat seni dan budaya Bali dengan sawah terasering, galeri, dan pasar seni.',
   'budaya', 'Ubud', 'Bali', -8.506900, 115.262500),
  ('raja-ampat', 'Raja Ampat',
   'Gugusan pulau dengan keanekaragaman hayati laut yang tinggi, tujuan utama menyelam.',
   'pantai', 'Waisai', 'Papua Barat Daya', -0.233000, 130.517000),
  ('kawah-ijen', 'Kawah Ijen',
   'Kawah dengan danau asam berwarna toska dan fenomena api biru.',
   'gunung', 'Banyuwangi', 'Jawa Timur', -8.058000, 114.242000),
  ('malioboro', 'Jalan Malioboro',
   'Kawasan belanja dan kuliner ikonik di jantung Kota Yogyakarta.',
   'belanja', 'Yogyakarta', 'DI Yogyakarta', -7.792800, 110.365800),
  ('danau-toba', 'Danau Toba',
   'Danau vulkanik terbesar di Asia Tenggara dengan Pulau Samosir di tengahnya.',
   'alam', 'Parapat', 'Sumatera Utara', 2.664000, 98.935000)
on conflict (slug) do nothing;
