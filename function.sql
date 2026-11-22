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

CREATE OR REPLACE FUNCTION calcular_velocidade_media(trajeto geometry, inicio_voo TIMESTAMP, fim_voo TIMESTAMP)
RETURNS DECIMAL(10,3)
LANGUAGE plpgsql
AS $$
DECLARE
    distancia_km DECIMAL(10,3);
    tempo_horas NUMERIC;
BEGIN
    distancia_km := calcular_distancia_percorrida(trajeto);
    tempo_horas := EXTRACT(EPOCH FROM calcular_tempo_voo(inicio_voo, fim_voo)) / 3600.0;
    
    IF tempo_horas IS NULL OR tempo_horas = 0 THEN
        RETURN 0;
    END IF;

    RETURN ROUND(distancia_km / tempo_horas,3);
END;
$$;