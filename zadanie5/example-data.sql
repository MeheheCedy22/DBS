INSERT INTO institutions (type, name, creation_date) VALUES
('our_museum', 'Our Museum - National Museum', NOW()),
('other_museum', 'Scientific Museum', NOW()),
('private_collector', 'John Lee', NOW()),
('institution', 'MIT', NOW()),
('other_museum', 'Slovak Museum', NOW());

INSERT INTO categories (name) VALUES
('science'),
('art'),
('history'),
('technology'),
('nature');

INSERT INTO exemplars (name, owner_id, category, collected_at) VALUES
('Atom Model', 1, 1, NOW()),
('Mona Lisa', 1, 2, NOW()),
('Bible', 1, 3, NOW()),
('iPhone 4', 1, 4, NOW()),
('Maple leaf', 1, 5, NOW()),
('The Starry Night', 2, 2, NOW()),
('The Last Supper', 2, 2, NOW());


INSERT INTO zones (name) VALUES
('Zone A'),
('Zone B'),
('Zone C'),
('Zone D'),
('Zone E'),
('Zone F'),
('Zone G'),
('Zone H');

INSERT INTO exhibitions (name, exhibited_by, start_time, end_time) VALUES
('Exhibition 1', 1, NOW() + INTERVAL '1 month', NOW() + INTERVAL '5 month'),
('Exhibition 2', 1, NOW() + INTERVAL '2 month', NOW() + INTERVAL '6 month'),
('Exhibition 3', 1, NOW() + INTERVAL '3 month', NOW() + INTERVAL '7 month'),
('Exhibition 4', 1, NOW() + INTERVAL '4 month', NOW() + INTERVAL '8 month'),
('Exhibition 5', 1, NOW() + INTERVAL '5 month', NOW() + INTERVAL '9 month');

INSERT INTO exhibition_exemplar (exhibition_id, exemplar_id, zone_id) VALUES
(1, 1, 1),
(2, 2, 2),
(3, 3, 3),
(4, 4, 4);

INSERT INTO lent_exemplars (owner, lent_to, exemplar_id, lent_from, expected_return, not_lent_anymore) VALUES
(1, 5, 5, NOW(), NOW() + INTERVAL '1 month', FALSE);
