-- Sol gets a new colorful casual-chic shoot (six poses, one close-up).
-- Rafe: a casual-luxury menswear character. Products tagged on every image.

-- Sol: retire the studio close-ups and the brands made only for them
delete from public.pins where character_id = (select id from public.characters where slug = 'sol');
delete from public.characters where slug in ('sable-knit', 'halo-curl');
delete from public.products where name = 'Fine Link Chain';

update public.characters set
  tagline = 'Print, silk and sunlight.',
  bio = 'A casual-chic AI character. Printed shirts, washed denim and silk scarves, shot against murals and open water.',
  tags = '{"Casual chic",Print,Color}',
  avatar_url = 'https://muse-cdn-ao2.pages.dev/img/sol2-1.jpg'
where slug = 'sol';

insert into public.pins (character_id, image_url, caption, status, position)
select c.id, 'https://muse-cdn-ao2.pages.dev/img/sol2-' || p.n || '.jpg', p.caption, 'live', p.n
from public.characters c
join (values (1, 'Waterfront, noon'), (2, 'Against the mural'), (3, 'Over the shoulder'),
             (4, 'The full look'), (5, 'Walking away'), (6, 'Rings and print')) as p(n, caption) on true
where c.slug = 'sol';

-- Rafe
insert into public.characters (slug, kind, name, handle, tagline, bio, tags, avatar_url, creator_name, creator_handle, followers_label) values
 ('rafe', 'character', 'Rafe', '@rafe.hart', 'Mustard, navy, nothing forced.',
  'A casual-luxury AI character. Good shirts, one strong jacket and dark denim, worn like he forgot he was dressed up.',
  '{Menswear,"Casual luxury",Shirting}', 'https://muse-cdn-ao2.pages.dev/img/rafe-6.jpg', 'Leo Hart', '@hart.studio', '121K'),
 ('riviera-print', 'brand', 'Riviera Print', '@rivieraprint', 'Prints made for the sun.',
  'An AI resort label. Camp-collar shirts and silk scarves in loud, happy prints.',
  '{Prints,Resort,Silk}', 'https://muse-cdn-ao2.pages.dev/img/p-campshirt.jpg', 'Ama Okafor', '@ama.builds', '27.9K'),
 ('ochre-and-co', 'brand', 'Ochre & Co', '@ochreandco', 'Outerwear in one good color.',
  'An AI outerwear brand. Harrington jackets and overshirts in ochre, olive and rust.',
  '{Outerwear,Menswear}', 'https://muse-cdn-ao2.pages.dev/img/p-mustard.jpg', 'Leo Hart', '@hart.studio', '18.3K'),
 ('northbound', 'brand', 'Northbound', '@northbound.shirts', 'Shirts that hold their shape.',
  'An AI shirting label. Oxford cloth and poplin, cut slim and finished by hand.',
  '{Shirting,Menswear}', 'https://muse-cdn-ao2.pages.dev/img/p-navyshirt.jpg', 'Leo Hart', '@hart.studio', '15.6K'),
 ('meridian', 'brand', 'Meridian', '@meridian.time', 'Time, plainly told.',
  'An AI watch brand. Field chronographs with clean dials and steel cases.',
  '{Watches,Accessories}', 'https://muse-cdn-ao2.pages.dev/img/p-watch.jpg', 'Leo Hart', '@hart.studio', '21.0K')
on conflict (slug) do nothing;

insert into public.products (brand_id, name, category, price_cents, image_url)
select b.id, x.name, x.category, x.price, 'https://muse-cdn-ao2.pages.dev/img/' || x.img || '.jpg'
from (values
  ('riviera-print', 'Printed Camp Shirt', 'Shirt', 21000, 'p-campshirt'),
  ('riviera-print', 'Silk Print Headscarf', 'Scarf', 14000, 'p-silkscarf'),
  ('indigo-hall', 'Light Wash Straight Jean', 'Jeans', 19000, 'p-lightjeans'),
  ('indigo-hall', 'Dark Rinse Slim Jean', 'Jeans', 21000, 'p-darkjeans'),
  ('ochre-and-co', 'Mustard Harrington Jacket', 'Jacket', 62000, 'p-mustard'),
  ('northbound', 'Navy Oxford Shirt', 'Shirt', 18500, 'p-navyshirt'),
  ('northbound', 'Black Poplin Shirt', 'Shirt', 17500, 'p-blackshirt'),
  ('field-and-thread', 'Heather Grey Tee', 'T-shirt', 6500, 'p-greytee'),
  ('meridian', 'Field Chronograph', 'Watch', 39000, 'p-watch')
) as x(brand, name, category, price, img)
join public.characters b on b.slug = x.brand
where not exists (select 1 from public.products p where p.brand_id = b.id and p.name = x.name);

insert into public.pins (character_id, image_url, caption, status, position)
select c.id, 'https://muse-cdn-ao2.pages.dev/img/rafe-' || p.n || '.jpg', p.caption, 'live', p.n
from public.characters c
join (values (1, 'Mustard and grey'), (2, 'Navy, seated'), (3, 'The jacket stays on'),
             (4, 'Black shirt study'), (5, 'Jacket off'), (6, 'Easy')) as p(n, caption) on true
where c.slug = 'rafe'
  and not exists (select 1 from public.pins x where x.character_id = c.id);

insert into public.pin_products (pin_id, product_id, position)
select pin.id, pr.id, t.pos
from (values
  ('sol2', 1, 'Printed Camp Shirt', 1), ('sol2', 1, 'Light Wash Straight Jean', 2), ('sol2', 1, 'Silk Print Headscarf', 3),
  ('sol2', 2, 'Printed Camp Shirt', 1), ('sol2', 2, 'Silk Print Headscarf', 2),
  ('sol2', 3, 'Printed Camp Shirt', 1), ('sol2', 3, 'Light Wash Straight Jean', 2), ('sol2', 3, 'Silk Print Headscarf', 3),
  ('sol2', 4, 'Printed Camp Shirt', 1), ('sol2', 4, 'Light Wash Straight Jean', 2), ('sol2', 4, 'Silk Print Headscarf', 3),
  ('sol2', 5, 'Printed Camp Shirt', 1), ('sol2', 5, 'Light Wash Straight Jean', 2), ('sol2', 5, 'Silk Print Headscarf', 3),
  ('sol2', 6, 'Printed Camp Shirt', 1), ('sol2', 6, 'Sculpted Gold Hoops', 2),
  ('rafe', 1, 'Mustard Harrington Jacket', 1), ('rafe', 1, 'Heather Grey Tee', 2), ('rafe', 1, 'Dark Rinse Slim Jean', 3),
  ('rafe', 2, 'Navy Oxford Shirt', 1), ('rafe', 2, 'Dark Rinse Slim Jean', 2), ('rafe', 2, 'Field Chronograph', 3),
  ('rafe', 3, 'Mustard Harrington Jacket', 1), ('rafe', 3, 'Navy Oxford Shirt', 2), ('rafe', 3, 'Dark Rinse Slim Jean', 3),
  ('rafe', 4, 'Black Poplin Shirt', 1), ('rafe', 4, 'Field Chronograph', 2),
  ('rafe', 5, 'Navy Oxford Shirt', 1), ('rafe', 5, 'Mustard Harrington Jacket', 2), ('rafe', 5, 'Dark Rinse Slim Jean', 3),
  ('rafe', 6, 'Heather Grey Tee', 1), ('rafe', 6, 'Field Chronograph', 2)
) as t(file, n, product, pos)
join public.pins pin on pin.image_url like '%/' || t.file || '-' || t.n || '.jpg'
join public.products pr on pr.name = t.product
on conflict do nothing;
