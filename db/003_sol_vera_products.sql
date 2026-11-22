-- Shop the look for Sol and Vera: six more AI brands, ten products, tags on all 12 images.

insert into public.characters (slug, kind, name, handle, tagline, bio, tags, avatar_url, creator_name, creator_handle, followers_label) values
 ('sable-knit', 'brand', 'Sable Knit', '@sableknit', 'Knitwear in one color: black.',
  'An AI knitwear label. Mock-necks and ribbed turtlenecks, cut close and built for studio light.',
  '{Knitwear,Essentials}', 'https://muse-cdn-ao2.pages.dev/img/p-mockneck.jpg', 'Ama Okafor', '@ama.builds', '33.4K'),
 ('aurum-atelier', 'brand', 'Aurum Atelier', '@aurumatelier', 'Warm gold, worn every day.',
  'An AI jewelry house. Hoops, fine chains and bracelets in recycled gold tones.',
  '{Jewelry,Gold}', 'https://muse-cdn-ao2.pages.dev/img/p-hoops.jpg', 'Ama Okafor', '@ama.builds', '51.8K'),
 ('halo-curl', 'brand', 'Halo Curl', '@halocurl', 'Definition without weight.',
  'An AI beauty brand for curls and coils. Creams and oils made for volume that holds.',
  '{Beauty,Hair}', 'https://muse-cdn-ao2.pages.dev/img/p-curl.jpg', 'Ama Okafor', '@ama.builds', '76.2K'),
 ('studio-pois', 'brand', 'Studio Pois', '@studiopois', 'Black, white, and dotted.',
  'An AI ready-to-wear label. Crepe blouses and polka-dot shorts for city days.',
  '{Ready-to-wear,Prints}', 'https://muse-cdn-ao2.pages.dev/img/p-dots.jpg', 'Lena Marsh', '@northfold', '29.5K'),
 ('maison-clasp', 'brand', 'Maison Clasp', '@maisonclasp', 'Small bags, long chains.',
  'An AI leather goods brand. Structured crossbody bags with chain straps.',
  '{Bags,Leather}', 'https://muse-cdn-ao2.pages.dev/img/p-bag.jpg', 'Lena Marsh', '@northfold', '38.0K'),
 ('talon-noir', 'brand', 'Talon Noir', '@talonnoir', 'One strap, one heel, done.',
  'An AI shoe brand. Minimal strappy sandals on a slim heel.',
  '{Shoes,Heels}', 'https://muse-cdn-ao2.pages.dev/img/p-heels.jpg', 'Lena Marsh', '@northfold', '22.6K')
on conflict (slug) do nothing;

insert into public.products (brand_id, name, category, price_cents, image_url)
select b.id, x.name, x.category, x.price, 'https://muse-cdn-ao2.pages.dev/img/' || x.img || '.jpg'
from (values
  ('sable-knit', 'Sleeveless Mock-Neck Knit', 'Top', 18500, 'p-mockneck'),
  ('sable-knit', 'Ribbed Turtleneck', 'Sweater', 22000, 'p-turtleneck'),
  ('aurum-atelier', 'Sculpted Gold Hoops', 'Earrings', 14000, 'p-hoops'),
  ('aurum-atelier', 'Fine Link Chain', 'Necklace', 16500, 'p-chain'),
  ('aurum-atelier', 'Chunky Link Bracelet', 'Bracelet', 21000, 'p-bracelet'),
  ('halo-curl', 'Cloud Curl Defining Cream', 'Hair care', 3400, 'p-curl'),
  ('studio-pois', 'Sheer Crepe Blouse', 'Blouse', 26000, 'p-blouse'),
  ('studio-pois', 'Polka Dot Mini Shorts', 'Shorts', 17500, 'p-dots'),
  ('maison-clasp', 'Chain Strap Crossbody', 'Bag', 68000, 'p-bag'),
  ('talon-noir', 'Strappy Heel Sandal', 'Shoes', 49000, 'p-heels')
) as x(brand, name, category, price, img)
join public.characters b on b.slug = x.brand
where not exists (select 1 from public.products p where p.brand_id = b.id and p.name = x.name);

insert into public.pin_products (pin_id, product_id, position)
select pin.id, pr.id, t.pos
from (values
  ('sol', 1, 'Sleeveless Mock-Neck Knit', 1), ('sol', 1, 'Cloud Curl Defining Cream', 2),
  ('sol', 2, 'Ribbed Turtleneck', 1), ('sol', 2, 'Cloud Curl Defining Cream', 2),
  ('sol', 3, 'Ribbed Turtleneck', 1), ('sol', 3, 'Cloud Curl Defining Cream', 2),
  ('sol', 4, 'Sculpted Gold Hoops', 1), ('sol', 4, 'Fine Link Chain', 2), ('sol', 4, 'Cloud Curl Defining Cream', 3),
  ('sol', 5, 'Ribbed Turtleneck', 1), ('sol', 5, 'Cloud Curl Defining Cream', 2),
  ('sol', 6, 'Sleeveless Mock-Neck Knit', 1), ('sol', 6, 'Cloud Curl Defining Cream', 2),
  ('vera', 1, 'Sheer Crepe Blouse', 1), ('vera', 1, 'Polka Dot Mini Shorts', 2), ('vera', 1, 'Chain Strap Crossbody', 3),
  ('vera', 2, 'Polka Dot Mini Shorts', 1), ('vera', 2, 'Chain Strap Crossbody', 2), ('vera', 2, 'Strappy Heel Sandal', 3),
  ('vera', 3, 'Sheer Crepe Blouse', 1), ('vera', 3, 'Polka Dot Mini Shorts', 2), ('vera', 3, 'Chain Strap Crossbody', 3), ('vera', 3, 'Strappy Heel Sandal', 4),
  ('vera', 4, 'Sheer Crepe Blouse', 1), ('vera', 4, 'Polka Dot Mini Shorts', 2), ('vera', 4, 'Chain Strap Crossbody', 3), ('vera', 4, 'Strappy Heel Sandal', 4),
  ('vera', 5, 'Polka Dot Mini Shorts', 1), ('vera', 5, 'Strappy Heel Sandal', 2),
  ('vera', 6, 'Sheer Crepe Blouse', 1), ('vera', 6, 'Polka Dot Mini Shorts', 2), ('vera', 6, 'Chain Strap Crossbody', 3), ('vera', 6, 'Chunky Link Bracelet', 4)
) as t(slug, n, product, pos)
join public.characters c on c.slug = t.slug
join public.pins pin on pin.character_id = c.id and pin.image_url like '%/' || t.slug || '-' || t.n || '.jpg'
join public.products pr on pr.name = t.product
on conflict do nothing;
