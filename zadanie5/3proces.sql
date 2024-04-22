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