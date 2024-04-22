-- Drop dependent tables first
DROP TABLE IF EXISTS exhibition_exemplar CASCADE;
DROP TABLE IF EXISTS lent_exemplars;
DROP TABLE IF EXISTS exhibitions;
DROP TABLE IF EXISTS exemplars;

DROP TABLE IF EXISTS categories;

DROP TABLE IF EXISTS institutions;
DROP TABLE IF EXISTS zones;

-- Drop types
DROP TYPE IF EXISTS exhibition_status;
DROP TYPE IF EXISTS institution_type;
DROP TYPE IF EXISTS location_status;

CREATE TYPE "location_status" AS ENUM (
  'on_way_to_owner',
  'on_way_to_borrower',
  'in_our_warehouse',
  'in_other_warehouse',
  'is_exhibited'
);

CREATE TYPE "institution_type" AS ENUM (
  'our_museum',
  'other_museum',
  'private_collector',
  'institution'
);

CREATE TYPE "exhibition_status" AS ENUM (
  'closed',
  'preparing',
  'ongoing'
);

CREATE TABLE "institutions" (
  "id" SERIAL PRIMARY KEY,
  "type" institution_type NOT NULL,
  "name" VARCHAR(50) UNIQUE NOT NULL,
  "creation_date" TIMESTAMPTZ NOT NULL
);

CREATE TABLE "exemplars" (
  "id" SERIAL PRIMARY KEY,
  "name" VARCHAR(100) UNIQUE NOT NULL,
  "location_status" location_status NOT NULL DEFAULT 'in_our_warehouse',
  "owner_id" INT NOT NULL,
  "category" INT NOT NULL,
  "collected_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE "lent_exemplars" (
  "id" SERIAL PRIMARY KEY,
  "owner" INT NOT NULL,
  "lent_to" INT NOT NULL,
  "exemplar_id" INT NOT NULL,
  "lent_from" TIMESTAMPTZ NOT NULL,
  "expected_return" DATE NOT NULL,
  "not_lent_anymore" BOOLEAN NOT NULL,
  "validation_started" TIMESTAMPTZ,
  "validation_ended" TIMESTAMPTZ,
  "validated" BOOLEAN
);

CREATE TABLE "categories" (
  "id" SERIAL PRIMARY KEY,
  "name" VARCHAR(20) UNIQUE NOT NULL
);

CREATE TABLE "exhibitions" (
  "id" SERIAL PRIMARY KEY,
  "name" VARCHAR(50) NOT NULL,
  "exhibited_by" INT NOT NULL,
  "start_time" TIMESTAMPTZ NOT NULL,
  "end_time" TIMESTAMPTZ NOT NULL,
  "status" exhibition_status NOT NULL DEFAULT 'preparing'
);

CREATE TABLE "zones" (
  "id" SERIAL PRIMARY KEY,
  "name" VARCHAR(20) UNIQUE NOT NULL
);

CREATE TABLE "exhibition_exemplar" (
  "exhibition_id" INT NOT NULL,
  "exemplar_id" INT NOT NULL,
  "zone_id" INT NOT NULL
);

ALTER TABLE "lent_exemplars" ADD FOREIGN KEY ("owner") REFERENCES "institutions" ("id");

ALTER TABLE "lent_exemplars" ADD FOREIGN KEY ("lent_to") REFERENCES "institutions" ("id");

ALTER TABLE "lent_exemplars" ADD FOREIGN KEY ("exemplar_id") REFERENCES "exemplars" ("id");

ALTER TABLE "exemplars" ADD FOREIGN KEY ("owner_id") REFERENCES "institutions" ("id");

ALTER TABLE "exemplars" ADD FOREIGN KEY ("category") REFERENCES "categories" ("id");

ALTER TABLE "exhibitions" ADD FOREIGN KEY ("exhibited_by") REFERENCES "institutions" ("id");

ALTER TABLE "exhibition_exemplar" ADD FOREIGN KEY ("exemplar_id") REFERENCES "exemplars" ("id");

ALTER TABLE "exhibition_exemplar" ADD FOREIGN KEY ("exhibition_id") REFERENCES "exhibitions" ("id");

ALTER TABLE "exhibition_exemplar" ADD FOREIGN KEY ("zone_id") REFERENCES "zones" ("id");
-- Naplánovanie expozície
-- Predpokladom je že máme v tabuľkách `institution` a `exemplar` uložené nejaké inštitúcie a exempláre. Taktiež v tabuľke `zones` máme uložené zóny, kde sa môžu expozície nachádzať a v tabuľke `categories` máme uložené kategórie, kam môžu exempláre patriť. Následne môžeme naplánovať expozíciu. Zadáme jej meno, kto ju organizuje, id exemplára ktorý je súčasťou expozície, id zóny kde sa expozícia nachádza, časový záznam začiatku a konca expozície. Stav expozície je defaultne nastavený na `preparing`, kedže ju plánujeme.

CREATE OR REPLACE PROCEDURE plan_exhibition(local_name VARCHAR(50), local_exhibited_by INT, local_start_time TIMESTAMPTZ, local_end_time TIMESTAMPTZ)
LANGUAGE plpgsql
AS $$
DECLARE
    local_status exhibition_status;
BEGIN
    -- allow to have the same name for the exhibition but not in the same time because maybe we want to have the same exhibition once a year or something like that

    -- select the status of the exhibition with the same name
    SELECT status INTO local_status FROM exhibitions WHERE name = local_name;

    -- check if the exhibition is already planned
    IF EXISTS (SELECT 1 FROM exhibitions WHERE name = local_name) AND local_status != 'closed'
    THEN
        RAISE EXCEPTION 'Exhibition with name % is already being displayed or it is preparing.', local_name;
    END IF;

    -- when in preparing state, there does not need to be exxemplar assigned, but it is in the phase of assigning the exemplar/s

    INSERT INTO exhibitions (name, exhibited_by, start_time, end_time)
    VALUES (local_name, local_exhibited_by, local_start_time, local_end_time);
END;
$$;

-- call example
-- CALL plan_exhibition('Testing', 1, NOW() + INTERVAL '1 month', NOW() + INTERVAL '5 month');
-- Vkladanie nového exempláru (do nasej zbierky)
-- Predpokladom je že máme v tabuľke `categories` uložené kategórie, kam môžu exempláre patriť a v tabuľke `institutions` uložené inštitúcie, ktoré môžu byť vlastníkmi exemplárov. Následne môžeme vložiť nový exemplár. Zadáme jeho názov, id vlastníka a id kategórie. Časový záznam pridania exempláru do databázy sa nastaví automaticky po pridaní. Stav kde sa nachádza sa nastaví na `in_our_warehouse` automaticky kedže ide predovšetkým o náše múzeum.

-- adding new exemplar to our collection
CREATE OR REPLACE PROCEDURE add_exemplar(local_name VARCHAR(100), local_owner_id INT, local_category INT)
LANGUAGE plpgsql
AS $$
BEGIN
    -- does not need to add the location status because it has default, the collected_at is set to current timestamp
    INSERT INTO exemplars (name, owner_id, category)
    VALUES (local_name, local_owner_id, local_category);
END;
$$;

-- call example
-- CALL add_exemplar('Dzabede Nesta', 1, 2);

-- adding new exemplar to exhibition
CREATE OR REPLACE PROCEDURE add_exemplar_to_exhibition(local_exhibition_id INT, local_exemplar_id INT, local_zone INT)
LANGUAGE plpgsql
AS $$
DECLARE
    local_location_status location_status;
    local_exhibition_status exhibition_status;
BEGIN
    -- select the location status of the exemplar
    SELECT location_status INTO local_location_status FROM exemplars WHERE id = local_exemplar_id;

    -- check if the exemplar is in our warehouse
    IF local_location_status != 'in_our_warehouse'
    THEN
        RAISE EXCEPTION 'Exemplar with id % is not in our warehouse, cannot be added to exhibition.', local_exemplar_id;
    END IF;

    -- select the status of the exhibition
    SELECT status INTO local_exhibition_status FROM exhibitions WHERE id = local_exhibition_id;

    -- check if the exhibition is already closed
    IF local_exhibition_status != 'preparing'
    THEN
        RAISE EXCEPTION 'Exhibition with id % is already closed or ongoing, cannot add exemplar.', local_exhibition_id;
    END IF;

    -- v jedenj zone a expozicii moze byt viacej exemplarov ale iba jedna expozicia, takze netreba osetrovat

    INSERT INTO exhibition_exemplar (exhibition_id, exemplar_id, zone_id)
    VALUES (local_exhibition_id, local_exemplar_id, local_zone);
END;
$$;

-- call example
-- CALL add_exemplar_to_exhibition(1, 6, 1);
-- Presun exempláru do inej zóny
-- Ak pôjde o presun iba z jednej zóny do druhej tak aktualizujeme záznam. Ak pôjde o rozšírenie do ďalšej zóny tak vytvoríme nový záznam s novým id zóny a časovým záznamom pridania.


-- zone updating, changing the zone of the exemplar in the exhibition
CREATE OR REPLACE PROCEDURE update_exemplar_zone(local_exhibition_id INT, local_exemplar_id INT, local_updated_zone INT)
LANGUAGE plpgsql
AS $$
DECLARE
    local_status exhibition_status;
BEGIN

    -- select the status of the exhibition
    SELECT status INTO local_status FROM exhibitions WHERE id = local_exhibition_id;

    -- check if the zone is already assigned to another exhibition and if the exhibition is closed, then we can't update the zone, else we can update the zone
    IF EXISTS (SELECT 1 FROM exhibition_exemplar WHERE zone_id = local_updated_zone) AND local_status != 'closed'
    THEN
        RAISE EXCEPTION 'Zone with id % is already occupied', local_updated_zone;
    END IF;

    UPDATE exhibition_exemplar
    SET zone_id = local_updated_zone
    WHERE exhibition_id = local_exhibition_id AND exemplar_id = local_exemplar_id;
END;
$$;

-- call example
-- CALL update_exemplar_zone(1, 1, 5);

-- zone extension, adding new zone to the exhibition
CREATE OR REPLACE PROCEDURE extend_zone(local_exhibition_id INT, local_exemplar_id INT, local_new_zone INT)
LANGUAGE plpgsql
AS $$
DECLARE
    local_status exhibition_status;
BEGIN
    -- select the status of the exhibition
    SELECT status INTO local_status FROM exhibitions WHERE id = local_exhibition_id;

    -- check if the zone is already assigned to another exhibition and if the exhibition is closed, then we can't extend the zone, else we can extend the zone
    IF EXISTS (SELECT 1 FROM exhibition_exemplar WHERE zone_id = local_new_zone) AND local_status != 'closed'
    THEN
        RAISE EXCEPTION 'Zone with id % is already occupied', local_new_zone;
    END IF;

    INSERT INTO exhibition_exemplar (exhibition_id, exemplar_id, zone_id)
    VALUES (local_exhibition_id, local_exemplar_id, local_new_zone);
END;
$$;

-- call example
-- CALL extend_zone(1, 1, 7);
-- Prevzatie exempláru z inej inštitúcie (dostavame späť exemplár, ktorý sme požičali)
-- Ak mame v tabuľke `lent_exemplars` záznam o požičanom exemplári tak ak ku nam pride tak zmenime `location_status` exemplára na `in_our_warehouse`. Následne nastavíme `not_lent_anymore` na `true` a začneme validačný proces.

CREATE OR REPLACE PROCEDURE receive_lent_exemplar(local_exemplar_id INT)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Update the location_status of the exemplar
    UPDATE exemplars
    SET location_status = 'in_our_warehouse'
    WHERE id = local_exemplar_id AND expected_return <= NOW();

    -- Update the not_lent_anymore flag of the lent_exemplar
    UPDATE lent_exemplars
    SET not_lent_anymore = TRUE, validation_started = NOW()
    WHERE exemplar_id = local_exemplar_id AND expected_return <= NOW();
END;
$$;

-- call example
-- CALL receive_lent_exemplar(5);
-- Zapožičanie exempláru z inej inštitúcie (požičiavame si exemplár)
-- Ak chceme požičať exemplár tak vytvoríme nový záznam v tabuľke `lent_exemplars`. Zadáme id vlastníka exemplára to znamena inštitúcie, ktorá nam ho poziciava, nase ID, id exemplára, časový záznam požičania, dátum očakávaného vrátenia a nastavíme `not_lent_anymore` na `false`.

CREATE OR REPLACE PROCEDURE borrow_exemplar(local_owner_id INT, local_exemplar_id INT, local_lent_from TIMESTAMPTZ, local_expected_return DATE)
LANGUAGE plpgsql
AS $$
DECLARE
    our_musem_id INT;
BEGIN
    -- select our museum id
    SELECT id INTO our_musem_id FROM institutions WHERE type = 'our_museum';

    -- check whether owner is real owner of the exemplar
    IF NOT EXISTS (SELECT 1 FROM exemplars WHERE id = local_exemplar_id AND owner_id = local_owner_id)
    THEN
        RAISE EXCEPTION 'Institution with id % is not the owner of the exemplar with id %.', local_owner_id, local_exemplar_id;
    END IF;

    INSERT INTO lent_exemplars (owner, lent_to, exemplar_id, lent_from, expected_return, not_lent_anymore)
    VALUES (local_owner_id, our_musem_id, local_exemplar_id, local_lent_from, local_expected_return, false);
END;
$$;

-- call example
-- CALL borrow_exemplar(2, 7, NOW(), CAST(NOW() + INTERVAL '1 month' AS DATE));
-- function and trigger for checking if there is already an institution of type 'our_museum'
-- because there can be only one institution of type 'our_museum'

CREATE OR REPLACE FUNCTION check_our_museum()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.type = 'our_museum' AND EXISTS (SELECT 1 FROM institutions WHERE type = 'our_museum') THEN
        RAISE EXCEPTION 'An institution of type "our_museum" already exists.';
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER check_our_museum_trigger
BEFORE INSERT ON institutions
FOR EACH ROW
EXECUTE FUNCTION check_our_museum();
-- trigger that will change the exhibition status to ongoing when the start time is reached

CREATE OR REPLACE FUNCTION update_exhibition_status_ongoing()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE exhibitions
    SET status = 'ongoing'
    WHERE id = NEW.id AND start_time <= NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER exhibition_status_update_ongoing
BEFORE UPDATE ON exhibitions
FOR EACH ROW EXECUTE FUNCTION update_exhibition_status_ongoing();

-- trigger that when the status of the exhibition changes to ongoing from preparing, all exemplars that belong to it will set the location status to is_exhibited

CREATE OR REPLACE FUNCTION update_exemplar_status_is_exhibited()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'ongoing' AND OLD.status = 'preparing' THEN
        UPDATE exemplars SET location_status = 'is_exhibited'
        WHERE id IN (SELECT exemplar_id FROM exhibition_exemplar WHERE exhibition_id = NEW.id);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER exemplar_status_update_is_exhibited
AFTER UPDATE OF status ON exhibitions
FOR EACH ROW
WHEN (OLD.status IS DISTINCT FROM NEW.status)
EXECUTE FUNCTION update_exemplar_status_is_exhibited();
-- trigger for changing the exhibition status to closed when the end time is reached

CREATE OR REPLACE FUNCTION update_exhibition_status_closed() RETURNS TRIGGER AS $$
BEGIN
    UPDATE exhibitions
    SET status = 'closed'
    WHERE id = NEW.id AND end_time <= NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER exhibition_status_update_closed
BEFORE UPDATE ON exhibitions
FOR EACH ROW
EXECUTE FUNCTION update_exhibition_status_closed();

-- trigger for changing the location status of the exemplars when the exhibition is closed

CREATE OR REPLACE FUNCTION update_exemplar_status_in_our_warehouse() RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'closed' AND OLD.status = 'ongoing' THEN
        UPDATE exemplars SET location_status = 'in_our_warehouse'
        WHERE id IN (SELECT exemplar_id FROM exhibition_exemplar WHERE exhibition_id = NEW.id);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER exemplar_status_update_in_our_warehouse
AFTER UPDATE OF status ON exhibitions
FOR EACH ROW
WHEN (OLD.status IS DISTINCT FROM NEW.status)
EXECUTE FUNCTION update_exemplar_status_in_our_warehouse();
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
