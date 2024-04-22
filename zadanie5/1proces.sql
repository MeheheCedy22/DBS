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