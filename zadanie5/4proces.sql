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