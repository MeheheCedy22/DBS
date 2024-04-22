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