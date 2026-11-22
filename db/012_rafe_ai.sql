-- Rafe is now a generated AI character (consistent face across six looks).

delete from public.pins where character_id = (select id from public.characters where slug = 'rafe');

update public.characters set
  tagline = 'Tailoring, sun and slow mornings.',
  bio = 'A generated AI character. Tailoring from Milan to Lake Como: soft shoulders, open collars, fine knits and warm color.',
  tags = '{Tailoring,"Quiet luxury",Menswear}',
  avatar_url = 'https://muse-cdn-ao2.pages.dev/img/rafe3-6.jpg'
where slug = 'rafe';

insert into public.pins (character_id, image_url, caption, status, position)
select c.id, 'https://muse-cdn-ao2.pages.dev/img/rafe3-' || p.n || '.jpg', p.caption, 'live', p.n
from public.characters c
join (values (1, 'Navy, open collar'), (2, 'Camel coat, Milan'), (3, 'Ivory linen, Amalfi'),
             (4, 'Charcoal, the library'), (5, 'Green blazer, Lake Como'), (6, 'Chocolate and black')) as p(n, caption) on true
where c.slug = 'rafe';

-- Sample pieces until real affiliate products are added in the Studio
insert into public.pin_products (pin_id, product_id, position)
select pin.id, pr.id, t.pos
from (values
  (1, 'Navy Wool Two-Piece', 1), (1, 'Black Calf Oxford', 2),
  (2, 'Cream Merino Turtleneck', 1),
  (3, 'Stone Linen Suit', 1),
  (4, 'Charcoal Three-Piece', 1), (4, 'Field Chronograph', 2), (4, 'Black Calf Oxford', 3),
  (5, 'Heavy Cotton Tee', 1),
  (6, 'Chocolate Flannel Suit', 1), (6, 'Black Merino Turtleneck', 2)
) as t(n, product, pos)
join public.pins pin on pin.image_url like '%/rafe3-' || t.n || '.jpg'
join public.products pr on pr.name = t.product
on conflict do nothing;
