-- Three color characters for variety: Aurora (icy pastel), Amara (red and green), Wren (greenhouse).

insert into public.characters (slug, kind, name, handle, tagline, bio, tags, avatar_url, creator_name, creator_handle, followers_label) values
 ('aurora', 'character', 'Aurora', '@aurora.frost', 'Ice blue, white fur, first snow.',
  'A winter-pastel AI character. Powder blue, soft fur and clean light, shot like a ski chalet in the 1960s.',
  '{Pastel,Winter,Studio}', 'https://muse-cdn-ao2.pages.dev/img/aurora-1.jpg', 'Maya Lindqvist', '@lindqvist.studio', '143K'),
 ('amara', 'character', 'Amara', '@amara.rouge', 'Red room, green suit, sculpted hat.',
  'A color-block AI character. Saturated sets, sharp tailoring and millinery as architecture.',
  '{"Color block",Tailoring,Millinery}', 'https://muse-cdn-ao2.pages.dev/img/amara-1.jpg', 'Kofi Mensah', '@mensah.works', '167K'),
 ('wren', 'character', 'Wren', '@wren.greenhouse', 'Denim, straw hat, glass house.',
  'A slow-living AI character. Workwear, plants and soft green light, styled for long afternoons.',
  '{Greenhouse,Denim,"Natural light"}', 'https://muse-cdn-ao2.pages.dev/img/wren-1.jpg', 'Sofia Marin', '@marin.frames', '98.6K')
on conflict (slug) do nothing;

insert into public.pins (character_id, image_url, caption, status, position)
select c.id, 'https://muse-cdn-ao2.pages.dev/img/' || c.slug || '-' || p.n || '.jpg', p.caption, 'live', p.n
from public.characters c
join (values
  ('aurora', 1, 'First snow'), ('aurora', 2, 'Powder blue'), ('aurora', 3, 'Fur collar, close'),
  ('aurora', 4, 'Chalet light'), ('aurora', 5, 'The full look'), ('aurora', 6, 'Après'),
  ('amara', 1, 'Ivory, red room'), ('amara', 2, 'The green suit'), ('amara', 3, 'Brim study'),
  ('amara', 4, 'Color block'), ('amara', 5, 'Tailored'), ('amara', 6, 'Between sets'),
  ('wren', 1, 'Straw hat'), ('wren', 2, 'Linen and gold'), ('wren', 3, 'Overalls, greenhouse'),
  ('wren', 4, 'Hands, denim'), ('wren', 5, 'Glass house'), ('wren', 6, 'Long afternoon')
) as p(slug, n, caption) on p.slug = c.slug
where not exists (select 1 from public.pins x where x.character_id = c.id);
