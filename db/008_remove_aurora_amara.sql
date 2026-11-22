-- Remove Aurora and Amara, the brands made only for them, and products only they wore.
-- Pins, saves and tags go with them (on delete cascade).

delete from public.products where name = 'Pearl Drop Earrings';
delete from public.characters where slug in ('aurora', 'amara', 'maison-givre', 'atelier-menthe', 'brim-and-bone');
