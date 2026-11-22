CREATE OR REPLACE FUNCTION calcular_tempo_voo(inicio_voo TIMESTAMP, fim_voo TIMESTAMP)
RETURNS INTERVAL
LANGUAGE plpgsql
AS $$

DECLARE 
    tempo_voo INTERVAL;
BEGIN
    IF inicio_voo IS NULL THEN
        tempo_voo := '0 seconds';
    ELSIF fim_voo IS NULL THEN
        tempo_voo := NOW() - inicio_voo;
        RAISE NOTICE 'Voo ainda em progresso';
    ELSE
        tempo_voo := fim_voo - inicio_voo;
    END IF;

    RETURN tempo_voo;
END;
$$;

CREATE OR REPLACE FUNCTION calcular_distancia_percorrida(trajeto geometry)
RETURNS DECIMAL(10,3)
LANGUAGE plpgsql
AS $$
BEGIN
    IF trajeto IS NULL THEN
        RETURN 0;
    END IF;
    RETURN ST_Length(trajeto::geography)/1000;
END;
$$;