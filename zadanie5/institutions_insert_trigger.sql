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