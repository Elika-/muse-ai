-- Shop the look for Aurora, Amara and Wren: five more AI brands, twelve products, tags on all 18 images.

insert into public.characters (slug, kind, name, handle, tagline, bio, tags, avatar_url, creator_name, creator_handle, followers_label) values
 ('maison-givre', 'brand', 'Maison Givre', '@maisongivre', 'Winter in pastel.',
  'An AI outerwear house. Powder blues, soft tweeds and white fur trims for cold, bright days.',
  '{Outerwear,Winter,Pastel}', 'https://muse-cdn-ao2.pages.dev/img/p-furhat.jpg', 'Maya Lindqvist', '@lindqvist.studio', '24.8K'),
 ('atelier-menthe', 'brand', 'Atelier Menthe', '@ateliermenthe', 'Tailoring in unexpected color.',
  'An AI tailoring label. Mint blazers, ivory trousers and lace for evenings that need a point of view.',
  '{Tailoring,Color,Eveningwear}', 'https://muse-cdn-ao2.pages.dev/img/p-mintblazer.jpg', 'Kofi Mensah', '@mensah.works', '31.2K'),
 ('brim-and-bone', 'brand', 'Brim & Bone', '@brimandbone', 'Hats as architecture.',
  'An AI millinery studio. Sculpted brims and saucer shapes, made to be seen from across the room.',
  '{Millinery,Hats}', 'https://muse-cdn-ao2.pages.dev/img/p-brimhat.jpg', 'Kofi Mensah', '@mensah.works', '19.4K'),
 ('field-and-thread', 'brand', 'Field & Thread', '@fieldandthread', 'Workwear for slow days.',
  'An AI workwear label. Washed denim and heavy cotton, cut to live in.',
  '{Workwear,Denim,Basics}', 'https://muse-cdn-ao2.pages.dev/img/p-overalls.jpg', 'Sofia Marin', '@marin.frames', '22.1K'),
 ('paille', 'brand', 'Paille', '@paille.hats', 'Woven by hand, worn in the sun.',
  'An AI straw hat maker. Wide brims and natural weaves for long summers.',
  '{Hats,Summer}', 'https://muse-cdn-ao2.pages.dev/img/p-strawhat.jpg', 'Sofia Marin', '@marin.frames', '14.7K')
on conflict (slug) do nothing;

insert into public.products (brand_id, name, category, price_cents, image_url)
select b.id, x.name, x.category, x.price, 'https://muse-cdn-ao2.pages.dev/img/' || x.img || '.jpg'
from (values
  ('maison-givre', 'Fur Trim Cropped Jacket', 'Jacket', 89000, 'p-furjacket'),
  ('maison-givre', 'Powder Tweed Mini Skirt', 'Skirt', 34000, 'p-tweedskirt'),
  ('maison-givre', 'Cloud Fur Hat', 'Hat', 26000, 'p-furhat'),
  ('aurum-atelier', 'Pearl Drop Earrings', 'Earrings', 18000, 'p-pearls'),
  ('aurum-atelier', 'Layered Gold Necklace', 'Necklace', 23000, 'p-layered'),
  ('atelier-menthe', 'Mint Tailored Blazer', 'Blazer', 78000, 'p-mintblazer'),
  ('atelier-menthe', 'Ivory Wide-Leg Trouser', 'Trousers', 42000, 'p-widetrouser'),
  ('atelier-menthe', 'Ivory Lace Gown', 'Dress', 145000, 'p-lacegown'),
  ('brim-and-bone', 'Sculpted Wide-Brim Hat', 'Hat', 56000, 'p-brimhat'),
  ('field-and-thread', 'Washed Denim Overalls', 'Overalls', 24000, 'p-overalls'),
  ('field-and-thread', 'Heavy Cotton Tee', 'T-shirt', 6000, 'p-tee'),
  ('paille', 'Woven Straw Hat', 'Hat', 15000, 'p-strawhat')
) as x(brand, name, category, price, img)
join public.characters b on b.slug = x.brand
where not exists (select 1 from public.products p where p.brand_id = b.id and p.name = x.name);

insert into public.pin_products (pin_id, product_id, position)
select pin.id, pr.id, t.pos
from (values
  ('aurora', 1, 'Cloud Fur Hat', 1), ('aurora', 1, 'Pearl Drop Earrings', 2), ('aurora', 1, 'Fur Trim Cropped Jacket', 3),
  ('aurora', 2, 'Cloud Fur Hat', 1), ('aurora', 2, 'Pearl Drop Earrings', 2), ('aurora', 2, 'Fur Trim Cropped Jacket', 3),
  ('aurora', 3, 'Cloud Fur Hat', 1), ('aurora', 3, 'Fur Trim Cropped Jacket', 2),
  ('aurora', 4, 'Cloud Fur Hat', 1), ('aurora', 4, 'Fur Trim Cropped Jacket', 2),
  ('aurora', 5, 'Cloud Fur Hat', 1), ('aurora', 5, 'Fur Trim Cropped Jacket', 2), ('aurora', 5, 'Powder Tweed Mini Skirt', 3),
  ('aurora', 6, 'Cloud Fur Hat', 1), ('aurora', 6, 'Fur Trim Cropped Jacket', 2), ('aurora', 6, 'Powder Tweed Mini Skirt', 3),
  ('amara', 1, 'Ivory Lace Gown', 1), ('amara', 1, 'Sculpted Wide-Brim Hat', 2),
  ('amara', 2, 'Mint Tailored Blazer', 1), ('amara', 2, 'Ivory Wide-Leg Trouser', 2), ('amara', 2, 'Sculpted Wide-Brim Hat', 3),
  ('amara', 3, 'Ivory Lace Gown', 1), ('amara', 3, 'Sculpted Wide-Brim Hat', 2),
  ('amara', 4, 'Mint Tailored Blazer', 1), ('amara', 4, 'Ivory Wide-Leg Trouser', 2), ('amara', 4, 'Sculpted Wide-Brim Hat', 3),
  ('amara', 5, 'Mint Tailored Blazer', 1), ('amara', 5, 'Ivory Wide-Leg Trouser', 2), ('amara', 5, 'Sculpted Wide-Brim Hat', 3),
  ('amara', 6, 'Ivory Lace Gown', 1),
  ('wren', 1, 'Woven Straw Hat', 1), ('wren', 1, 'Heavy Cotton Tee', 2),
  ('wren', 2, 'Heavy Cotton Tee', 1), ('wren', 2, 'Washed Denim Overalls', 2), ('wren', 2, 'Layered Gold Necklace', 3),
  ('wren', 3, 'Woven Straw Hat', 1), ('wren', 3, 'Heavy Cotton Tee', 2), ('wren', 3, 'Washed Denim Overalls', 3),
  ('wren', 4, 'Washed Denim Overalls', 1),
  ('wren', 5, 'Woven Straw Hat', 1), ('wren', 5, 'Heavy Cotton Tee', 2), ('wren', 5, 'Washed Denim Overalls', 3),
  ('wren', 6, 'Woven Straw Hat', 1), ('wren', 6, 'Heavy Cotton Tee', 2), ('wren', 6, 'Washed Denim Overalls', 3)
) as t(slug, n, product, pos)
join public.characters c on c.slug = t.slug
join public.pins pin on pin.character_id = c.id and pin.image_url like '%/' || t.slug || '-' || t.n || '.jpg'
join public.products pr on pr.name = t.product
on conflict do nothing;
