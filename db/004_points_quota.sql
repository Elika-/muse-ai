-- Upload allowance: every creator starts with 5 images; each 10 points unlocks 1 more.
-- allowance = 5 + floor(points / 10). Enforced in the database, not just the UI.

alter table public.creators add column if not exists points int not null default 0 check (points >= 0);

-- Creators can edit their name and handle, never their own points.
revoke update on public.creators from authenticated;
grant update (display_name, handle) on public.creators to authenticated;

create or replace function public.image_allowance(uid uuid) returns int
language sql stable security definer set search_path = public as $$
  select 5 + coalesce((select points from public.creators where id = uid), 0) / 10
$$;

create or replace function public.images_used(uid uuid) returns int
language sql stable security definer set search_path = public as $$
  select count(*)::int from public.pins where creator_id = uid
$$;

create or replace function public.can_add_image() returns boolean
language sql stable security definer set search_path = public as $$
  select auth.uid() is not null and public.images_used(auth.uid()) < public.image_allowance(auth.uid())
$$;

-- One call for the Studio: allowance, used, points.
create or replace function public.my_allowance() returns json
language sql stable security definer set search_path = public as $$
  select json_build_object(
    'points', coalesce((select points from public.creators where id = auth.uid()), 0),
    'allowance', public.image_allowance(auth.uid()),
    'used', public.images_used(auth.uid())
  )
$$;

revoke all on function public.image_allowance(uuid), public.images_used(uuid) from public, anon, authenticated;
grant execute on function public.can_add_image(), public.my_allowance() to authenticated;

drop policy if exists "creators insert pins" on public.pins;
create policy "creators insert pins" on public.pins for insert
  with check (
    auth.uid() = creator_id
    and exists (select 1 from public.characters c where c.id = character_id and c.creator_id = auth.uid())
    and public.can_add_image()
  );
