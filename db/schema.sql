-- Muse database schema (Supabase / Postgres)
-- Creators (humans) build characters and brands. Each one has pins (images).
-- Pins start as drafts; the creator chooses which go live.

create table if not exists public.creators (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default '',
  handle text unique,
  created_at timestamptz not null default now()
);

create table if not exists public.characters (
  id uuid primary key default gen_random_uuid(),
  slug text unique not null,
  creator_id uuid references public.creators(id) on delete cascade,
  kind text not null default 'character' check (kind in ('character', 'brand')),
  name text not null,
  handle text not null default '',
  tagline text not null default '',
  bio text not null default '',
  tags text[] not null default '{}',
  avatar_url text,
  creator_name text not null default '',
  creator_handle text not null default '',
  followers_label text not null default '0',
  is_public boolean not null default true,
  created_at timestamptz not null default now()
);

create table if not exists public.pins (
  id uuid primary key default gen_random_uuid(),
  character_id uuid not null references public.characters(id) on delete cascade,
  creator_id uuid references public.creators(id) on delete cascade,
  image_url text not null,
  caption text not null default '',
  status text not null default 'draft' check (status in ('draft', 'live')),
  position int not null default 0,
  created_at timestamptz not null default now()
);

create index if not exists pins_character_idx on public.pins(character_id, position);
create index if not exists pins_live_idx on public.pins(status, created_at desc);

-- Auto-create a creator row on sign-up
create or replace function public.handle_new_user() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into public.creators (id, display_name)
  values (new.id, coalesce(split_part(new.email, '@', 1), ''))
  on conflict (id) do nothing;
  return new;
end $$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created after insert on auth.users
  for each row execute function public.handle_new_user();

-- Data API access (row level security below decides which rows)
grant usage on schema public to anon, authenticated;
grant select on public.characters, public.pins to anon, authenticated;
grant insert, update, delete on public.characters, public.pins to authenticated;
grant select, update on public.creators to authenticated;

-- Row level security
alter table public.creators enable row level security;
alter table public.characters enable row level security;
alter table public.pins enable row level security;

drop policy if exists "creators read own" on public.creators;
create policy "creators read own" on public.creators for select using (auth.uid() = id);
drop policy if exists "creators update own" on public.creators;
create policy "creators update own" on public.creators for update using (auth.uid() = id);

drop policy if exists "public characters readable" on public.characters;
create policy "public characters readable" on public.characters for select
  using (is_public or auth.uid() = creator_id);
drop policy if exists "creators insert characters" on public.characters;
create policy "creators insert characters" on public.characters for insert
  with check (auth.uid() = creator_id);
drop policy if exists "creators update characters" on public.characters;
create policy "creators update characters" on public.characters for update
  using (auth.uid() = creator_id);
drop policy if exists "creators delete characters" on public.characters;
create policy "creators delete characters" on public.characters for delete
  using (auth.uid() = creator_id);

drop policy if exists "live pins readable" on public.pins;
create policy "live pins readable" on public.pins for select
  using (status = 'live' or auth.uid() = creator_id);
drop policy if exists "creators insert pins" on public.pins;
create policy "creators insert pins" on public.pins for insert
  with check (auth.uid() = creator_id
    and exists (select 1 from public.characters c where c.id = character_id and c.creator_id = auth.uid()));
drop policy if exists "creators update pins" on public.pins;
create policy "creators update pins" on public.pins for update
  using (auth.uid() = creator_id);
drop policy if exists "creators delete pins" on public.pins;
create policy "creators delete pins" on public.pins for delete
  using (auth.uid() = creator_id);

-- Seed: the 3 launch characters (owned by no creator yet; claimable later)
insert into public.characters (slug, name, handle, tagline, bio, tags, avatar_url, creator_name, creator_handle, followers_label) values
 ('sol', 'Sol', '@sol.studio', 'Warm light, quiet confidence.',
  'A portrait-first AI character built around sepia tones and soft studio light. Sol shares moods, not products.',
  '{Portrait,Studio,Sepia}', 'https://muse-cdn-ao2.pages.dev/img/sol-1.jpg', 'Ama Okafor', '@ama.builds', '128K'),
 ('nila', 'Nila', '@nila.noir', 'Black dress, long gloves, one spotlight.',
  'Nila is a high-fashion AI muse. Monochrome studio, sharp tailoring and old-Hollywood glamour, never off duty.',
  '{"Haute couture",Studio,Noir}', 'https://muse-cdn-ao2.pages.dev/img/nila-1.jpg', 'Daniel Reyes', '@reyes.lab', '184K'),
 ('vera', 'Vera', '@vera.daily', 'City uniform: black, white, polka dot.',
  'A street-style AI brand. Vera tests outfits against architecture and posts the ones that hold up.',
  '{Street,Fashion,Monochrome}', 'https://muse-cdn-ao2.pages.dev/img/vera-1.jpg', 'Lena Marsh', '@northfold', '211K')
on conflict (slug) do nothing;

insert into public.pins (character_id, image_url, caption, status, position)
select c.id, 'https://muse-cdn-ao2.pages.dev/img/' || c.slug || '-' || p.n || '.jpg', p.caption, 'live', p.n
from public.characters c
join (values
  ('sol', 1, 'Golden hour, indoors'), ('sol', 2, 'Hands tell the story'), ('sol', 3, 'Turtleneck season'),
  ('sol', 4, 'A laugh, unposed'), ('sol', 5, 'Low light study'), ('sol', 6, 'Close, closer'),
  ('nila', 1, 'Shades on, lights low'), ('nila', 2, 'Opera gloves'), ('nila', 3, 'The column dress'),
  ('nila', 4, 'Ladder, no. 2'), ('nila', 5, 'White shirt, black lace'), ('nila', 6, 'Last look of the night'),
  ('vera', 1, 'Columns and dots'), ('vera', 2, 'Saturday uniform'), ('vera', 3, 'Chain strap, black bag'),
  ('vera', 4, 'Museum steps'), ('vera', 5, 'Off duty'), ('vera', 6, 'One more take')
) as p(slug, n, caption) on p.slug = c.slug
where not exists (select 1 from public.pins x where x.character_id = c.id);
