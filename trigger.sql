CREATE OR REPLACE FUNCTION atualizar_voo()
RETURNS trigger AS $usuario_trigger$
DECLARE 
    voo_id_att INT8;
    decolou BOOLEAN;
BEGIN
    SELECT id INTO voo_id_att
    FROM voo
    WHERE aeronave_id = NEW.aeronave_id AND final_voo IS NULL
    ORDER BY inicio_voo DESC LIMIT 1;

    IF voo_id_att IS NULL THEN
        IF NEW.velocidade > 0 THEN -- Para não criar voo com avião parado
            INSERT INTO voo(aeronave_id, dispositivo_id, inicio_voo, trajeto_percorrido)
            VALUES (NEW.aeronave_id, NEW.dispositivo_id, NEW.momento_coleta, ST_MakeLine(NEW.ponto, NEW.ponto))
            RETURNING id INTO voo_id_att;
        ELSE
            RETURN NEW; 
        END IF;
    ELSE
        UPDATE voo
            SET trajeto_percorrido = ST_AddPoint(trajeto_percorrido, NEW.ponto)
            WHERE id = voo_id_att;
    END IF;

    --==========================================================================================================
    
    SELECT EXISTS(
        SELECT 1
        FROM evento
        WHERE voo_id = voo_id_att AND evento = 'DECOLAGEM'
    ) INTO decolou;

    IF NEW.velocidade = 0 THEN
        IF decolou IS TRUE THEN
            INSERT INTO evento (momento_evento, evento, aeronave_id, dispositivo_id, voo_id)
            VALUES(NEW.momento_coleta, 'POUSO', NEW.aeronave_id, NEW.dispositivo_id, voo_id_att);

            UPDATE voo
                SET final_voo = NEW.momento_coleta
                WHERE id = voo_id_att;
        END IF;
    ELSIF NEW.velocidade >= 100 THEN
        IF decolou IS FALSE THEN
            INSERT INTO evento (momento_evento, evento, aeronave_id, dispositivo_id, voo_id)
            VALUES(NEW.momento_coleta, 'DECOLAGEM', NEW.aeronave_id, NEW.dispositivo_id, voo_id_att);
        END IF; 
    END IF;

    RETURN NEW;
END;
$usuario_trigger$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_constroi_voo
AFTER INSERT ON gnss
FOR EACH ROW
EXECUTE PROCEDURE atualizar_voo();




