-- Real products with affiliate links.
-- Existing products are illustrative samples until real links replace them.

alter table public.products alter column brand_id drop not null;
alter table public.products add column if not exists brand_name text;
alter table public.products add column if not exists merchant text;
alter table public.products add column if not exists affiliate_url text check (affiliate_url is null or affiliate_url ~* '^https://');
alter table public.products add column if not exists is_sample boolean not null default false;

update public.products set is_sample = true where affiliate_url is null;

-- Creators add real products to their own images: product rows they own, tagged on their own pins.
drop policy if exists "brand owners write products" on public.products;
drop policy if exists "creators write own products" on public.products;
create policy "creators write own products" on public.products for all
  using (auth.uid() = creator_id)
  with check (
    auth.uid() = creator_id
    and (brand_id is null or exists (select 1 from public.characters b where b.id = brand_id and b.creator_id = auth.uid()))
  );

-- Admins (the site owner) manage every character and have no image limit.
alter table public.creators add column if not exists is_admin boolean not null default false;
revoke update on public.creators from authenticated;
grant update (display_name, handle) on public.creators to authenticated;

create or replace function public.image_allowance(uid uuid) returns int
language sql stable security definer set search_path = public as $$
  select case when coalesce((select is_admin from public.creators where id = uid), false) then 100000
              else 5 + coalesce((select points from public.creators where id = uid), 0) / 10 end
$$;
revoke all on function public.image_allowance(uuid) from public, anon, authenticated;
