-- Points from saves: each save of a creator's image gives that creator 1 point.
-- 10 points = 1 extra image (see 004). One save per person per image; no self-saves.

create table if not exists public.saves (
  user_id uuid not null default auth.uid() references auth.users(id) on delete cascade,
  pin_id uuid not null references public.pins(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (user_id, pin_id)
);

grant select, insert, delete on public.saves to authenticated;
alter table public.saves enable row level security;

drop policy if exists "read own saves" on public.saves;
create policy "read own saves" on public.saves for select using (auth.uid() = user_id);
drop policy if exists "save others' images" on public.saves;
create policy "save others' images" on public.saves for insert
  with check (
    auth.uid() = user_id
    and exists (select 1 from public.pins p where p.id = pin_id and p.status = 'live'
                and p.creator_id is distinct from auth.uid())
  );
drop policy if exists "unsave own saves" on public.saves;
create policy "unsave own saves" on public.saves for delete using (auth.uid() = user_id);

create or replace function public.saves_award_points() returns trigger
language plpgsql security definer set search_path = public as $$
declare owner uuid;
begin
  if tg_op = 'INSERT' then
    select creator_id into owner from public.pins where id = new.pin_id;
    if owner is not null and owner <> new.user_id then
      update public.creators set points = points + 1 where id = owner;
    end if;
    return new;
  else
    select creator_id into owner from public.pins where id = old.pin_id;
    if owner is not null and owner <> old.user_id then
      update public.creators set points = greatest(points - 1, 0) where id = owner;
    end if;
    return old;
  end if;
end $$;

drop trigger if exists saves_points on public.saves;
create trigger saves_points after insert or delete on public.saves
  for each row execute function public.saves_award_points();
