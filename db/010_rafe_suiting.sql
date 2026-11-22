-- Rafe: new suiting shoot (one model, six suits). Remove the old shoot and products only it used.

delete from public.pins where character_id = (select id from public.characters where slug = 'rafe');
delete from public.products where name in ('Heather Grey Tee', 'Dark Rinse Slim Jean');
delete from public.characters where slug in ('ochre-and-co', 'northbound');

update public.characters set
  tagline = 'Six suits, no tie.',
  bio = 'A suiting-first AI character. Sharp tailoring in navy, charcoal, chocolate and stone, worn open-collar with fine knits.',
  tags = '{Tailoring,Suiting,"Quiet luxury"}',
  avatar_url = 'https://muse-cdn-ao2.pages.dev/img/rafe2-1.jpg'
where slug = 'rafe';

insert into public.characters (slug, kind, name, handle, tagline, bio, tags, avatar_url, creator_name, creator_handle, followers_label) values
 ('sartoria-vale', 'brand', 'Sartoria Vale', '@sartoriavale', 'Soft shoulders, sharp lines.',
  'An AI tailoring house. Two- and three-piece suits in wool and flannel, cut close and finished by hand.',
  '{Tailoring,Suits,Menswear}', 'https://muse-cdn-ao2.pages.dev/img/p-navysuit.jpg', 'Leo Hart', '@hart.studio', '36.4K'),
 ('merino-house', 'brand', 'Merino House', '@merinohouse', 'Fine gauge, worn under everything.',
  'An AI knitwear label. Merino turtlenecks and polos made to sit under a jacket.',
  '{Knitwear,Merino}', 'https://muse-cdn-ao2.pages.dev/img/p-creamturtle.jpg', 'Leo Hart', '@hart.studio', '17.8K'),
 ('last-and-sole', 'brand', 'Last & Sole', '@lastandsole', 'Leather shoes, made to last.',
  'An AI shoemaker. Polished oxfords and derbies on classic lasts.',
  '{Shoes,Leather}', 'https://muse-cdn-ao2.pages.dev/img/p-oxfords.jpg', 'Leo Hart', '@hart.studio', '12.9K')
on conflict (slug) do nothing;

insert into public.products (brand_id, name, category, price_cents, image_url)
select b.id, x.name, x.category, x.price, 'https://muse-cdn-ao2.pages.dev/img/' || x.img || '.jpg'
from (values
  ('sartoria-vale', 'Navy Wool Two-Piece', 'Suit', 189000, 'p-navysuit'),
  ('sartoria-vale', 'Chocolate Flannel Suit', 'Suit', 198000, 'p-brownsuit'),
  ('sartoria-vale', 'Charcoal Three-Piece', 'Suit', 224000, 'p-greysuit'),
  ('sartoria-vale', 'Stone Linen Suit', 'Suit', 172000, 'p-beigesuit'),
  ('merino-house', 'Black Merino Turtleneck', 'Knit', 26000, 'p-blackturtle'),
  ('merino-house', 'Cream Merino Turtleneck', 'Knit', 26000, 'p-creamturtle'),
  ('last-and-sole', 'Black Calf Oxford', 'Shoes', 58000, 'p-oxfords')
) as x(brand, name, category, price, img)
join public.characters b on b.slug = x.brand
where not exists (select 1 from public.products p where p.brand_id = b.id and p.name = x.name);

insert into public.pins (character_id, image_url, caption, status, position)
select c.id, 'https://muse-cdn-ao2.pages.dev/img/rafe2-' || p.n || '.jpg', p.caption, 'live', p.n
from public.characters c
join (values (1, 'Navy, open collar'), (2, 'Stone and cream'), (3, 'Chocolate flannel'),
             (4, 'Charcoal three-piece'), (5, 'Black on charcoal'), (6, 'Seated')) as p(n, caption) on true
where c.slug = 'rafe';

insert into public.pin_products (pin_id, product_id, position)
select pin.id, pr.id, t.pos
from (values
  (1, 'Navy Wool Two-Piece', 1), (1, 'Black Calf Oxford', 2),
  (2, 'Stone Linen Suit', 1), (2, 'Cream Merino Turtleneck', 2),
  (3, 'Chocolate Flannel Suit', 1), (3, 'Black Calf Oxford', 2),
  (4, 'Charcoal Three-Piece', 1), (4, 'Field Chronograph', 2), (4, 'Black Calf Oxford', 3),
  (5, 'Charcoal Three-Piece', 1), (5, 'Black Merino Turtleneck', 2),
  (6, 'Charcoal Three-Piece', 1), (6, 'Field Chronograph', 2), (6, 'Black Calf Oxford', 3)
) as t(n, product, pos)
join public.pins pin on pin.image_url like '%/rafe2-' || t.n || '.jpg'
join public.products pr on pr.name = t.product
on conflict do nothing;
