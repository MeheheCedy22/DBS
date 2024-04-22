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