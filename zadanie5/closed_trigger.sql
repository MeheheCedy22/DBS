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