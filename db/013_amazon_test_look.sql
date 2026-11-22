-- Test look: Rafe wearing five real Amazon products.
-- Images load from Amazon's CDN; links go to the product page (add the Associates tag once the account exists).

insert into public.products (brand_name, name, category, price_cents, currency, image_url, affiliate_url, merchant, is_sample)
select x.brand, x.name, x.category, x.price, 'EUR', x.img, 'https://www.amazon.com/dp/' || x.asin, 'Amazon', false
from (values
  ('Hawcay', 'Slim Fit Linen Blazer, Navy', 'Blazer', 4439, 'https://m.media-amazon.com/images/I/716p8ke-6DL._AC_SL1200_.jpg', 'B0FCG42MRB'),
  ('Nautica', 'Long Sleeve Solid Linen Shirt, White', 'Shirt', 2763, 'https://m.media-amazon.com/images/I/71OLYFa9KbL._AC_SL1200_.jpg', 'B0DPLNT3M2'),
  ('Puimentiua', 'Cotton Linen Drawstring Trousers, Beige', 'Trousers', 1471, 'https://m.media-amazon.com/images/I/61fpb6ZIsmL._AC_SL1200_.jpg', 'B0DSFDCKY9'),
  ('Bruno Marc', 'Suede Penny Loafers, Tan', 'Shoes', 5202, 'https://m.media-amazon.com/images/I/71zKVqt3+tL._AC_SL1200_.jpg', 'B0G65C28VW'),
  ('Timex', 'Easy Reader 38mm, Leather Strap', 'Watch', 4465, 'https://m.media-amazon.com/images/I/71mCiiNRwPL._AC_SL1200_.jpg', 'B00YTY4ABI')
) as x(brand, name, category, price, img, asin)
where not exists (select 1 from public.products p where p.affiliate_url = 'https://www.amazon.com/dp/' || x.asin);

insert into public.pins (character_id, image_url, caption, status, position)
select c.id, 'https://muse-cdn-ao2.pages.dev/img/rafe3-' || p.n || '.jpg', p.caption, 'live', p.pos
from public.characters c
join (values (7, 'Riviera linen', 0), (8, 'Espresso, Portofino', 1)) as p(n, caption, pos) on true
where c.slug = 'rafe'
  and not exists (select 1 from public.pins x where x.image_url like '%/rafe3-' || p.n || '.jpg');

insert into public.pin_products (pin_id, product_id, position)
select pin.id, pr.id, x.pos
from public.pins pin
join (values ('B0FCG42MRB', 1), ('B0DPLNT3M2', 2), ('B0DSFDCKY9', 3), ('B0G65C28VW', 4), ('B00YTY4ABI', 5)) as x(asin, pos) on true
join public.products pr on pr.affiliate_url = 'https://www.amazon.com/dp/' || x.asin
where pin.image_url like '%/rafe3-7.jpg' or pin.image_url like '%/rafe3-8.jpg'
on conflict do nothing;
