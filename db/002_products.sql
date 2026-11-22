-- Shop the look: brands sell products, products are tagged on pins.
-- Brands are rows in public.characters with kind = 'brand' (they get public profiles).

create table if not exists public.products (
  id uuid primary key default gen_random_uuid(),
  brand_id uuid not null references public.characters(id) on delete cascade,
  creator_id uuid references public.creators(id) on delete cascade,
  name text not null,
  category text not null default '',
  price_cents int,
  currency text not null default 'USD',
  image_url text not null,
  product_url text,
  created_at timestamptz not null default now()
);

create table if not exists public.pin_products (
  pin_id uuid not null references public.pins(id) on delete cascade,
  product_id uuid not null references public.products(id) on delete cascade,
  position int not null default 0,
  primary key (pin_id, product_id)
);

create index if not exists products_brand_idx on public.products(brand_id);
create index if not exists pin_products_product_idx on public.pin_products(product_id);

grant select on public.products, public.pin_products to anon, authenticated;
grant insert, update, delete on public.products, public.pin_products to authenticated;

alter table public.products enable row level security;
alter table public.pin_products enable row level security;

drop policy if exists "products readable" on public.products;
create policy "products readable" on public.products for select using (true);
drop policy if exists "brand owners write products" on public.products;
create policy "brand owners write products" on public.products for all
  using (auth.uid() = creator_id)
  with check (auth.uid() = creator_id
    and exists (select 1 from public.characters b where b.id = brand_id and b.creator_id = auth.uid()));

drop policy if exists "tags readable" on public.pin_products;
create policy "tags readable" on public.pin_products for select using (true);
drop policy if exists "pin owners tag products" on public.pin_products;
create policy "pin owners tag products" on public.pin_products for all
  using (exists (select 1 from public.pins p where p.id = pin_id and p.creator_id = auth.uid()))
  with check (exists (select 1 from public.pins p where p.id = pin_id and p.creator_id = auth.uid()));

-- Seed: four AI fashion brands built by Nila's creator
insert into public.characters (slug, kind, name, handle, tagline, bio, tags, avatar_url, creator_name, creator_handle, followers_label) values
 ('maison-ombre', 'brand', 'Maison Ombre', '@maisonombre', 'Eveningwear for after midnight.',
  'An AI couture house. Strapless columns, lace and long gloves, cut for one spotlight.',
  '{Eveningwear,Couture,Lace}', 'https://muse-cdn-ao2.pages.dev/img/p-gown.jpg', 'Daniel Reyes', '@reyes.lab', '42.1K'),
 ('noir-optique', 'brand', 'Noir Optique', '@noiroptique', 'Frames with a point of view.',
  'An AI eyewear label. Sharp cat-eyes and dark lenses, designed for the flash.',
  '{Eyewear,Accessories}', 'https://muse-cdn-ao2.pages.dev/img/p-sunglasses.jpg', 'Daniel Reyes', '@reyes.lab', '18.7K'),
 ('atelier-cuir', 'brand', 'Atelier Cuir', '@ateliercuir', 'Leather that moves.',
  'An AI leather atelier. Trench coats, boots and belts in black, built to be worn hard.',
  '{Leather,Outerwear,Boots}', 'https://muse-cdn-ao2.pages.dev/img/p-trench.jpg', 'Daniel Reyes', '@reyes.lab', '27.3K'),
 ('indigo-hall', 'brand', 'Indigo Hall', '@indigohall', 'Denim, deconstructed.',
  'An AI denim studio. Cropped jackets and raw edges, styled against black.',
  '{Denim,Streetwear}', 'https://muse-cdn-ao2.pages.dev/img/p-denim.jpg', 'Daniel Reyes', '@reyes.lab', '11.9K')
on conflict (slug) do nothing;

insert into public.products (brand_id, name, category, price_cents, image_url)
select b.id, x.name, x.category, x.price, 'https://muse-cdn-ao2.pages.dev/img/' || x.img || '.jpg'
from (values
  ('maison-ombre', 'Column Strapless Gown', 'Dress', 128000, 'p-gown'),
  ('maison-ombre', 'Lace Opera Gloves', 'Gloves', 24000, 'p-gloves'),
  ('maison-ombre', 'Grid Mesh Skirt', 'Skirt', 39000, 'p-skirt'),
  ('noir-optique', 'Vesper Cat-Eye Sunglasses', 'Eyewear', 32000, 'p-sunglasses'),
  ('atelier-cuir', 'Nocturne Leather Trench', 'Coat', 165000, 'p-trench'),
  ('atelier-cuir', 'Field Combat Boot', 'Boots', 54000, 'p-boots'),
  ('atelier-cuir', 'Waist Belt No. 3', 'Belt', 18000, 'p-belt'),
  ('indigo-hall', 'Cropped Raw-Edge Jacket', 'Jacket', 29000, 'p-denim')
) as x(brand, name, category, price, img)
join public.characters b on b.slug = x.brand
where not exists (select 1 from public.products p where p.brand_id = b.id and p.name = x.name);

insert into public.pin_products (pin_id, product_id, position)
select pin.id, pr.id, t.pos
from (values
  (1, 'Column Strapless Gown', 1), (1, 'Lace Opera Gloves', 2), (1, 'Vesper Cat-Eye Sunglasses', 3),
  (2, 'Column Strapless Gown', 1), (2, 'Lace Opera Gloves', 2),
  (3, 'Column Strapless Gown', 1), (3, 'Lace Opera Gloves', 2),
  (4, 'Nocturne Leather Trench', 1), (4, 'Field Combat Boot', 2),
  (5, 'Cropped Raw-Edge Jacket', 1), (5, 'Grid Mesh Skirt', 2), (5, 'Waist Belt No. 3', 3),
  (6, 'Nocturne Leather Trench', 1), (6, 'Field Combat Boot', 2)
) as t(n, product, pos)
join public.characters c on c.slug = 'nila'
join public.pins pin on pin.character_id = c.id and pin.image_url like '%/nila-' || t.n || '.jpg'
join public.products pr on pr.name = t.product
on conflict do nothing;
