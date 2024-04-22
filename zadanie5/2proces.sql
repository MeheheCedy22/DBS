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