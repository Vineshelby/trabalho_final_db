-- Consultar ultimos 10 eventos aeronave
SELECT * FROM vw_eventos_aeronave 
WHERE aeronave_id = 2 
LIMIT 10;

-- Consultar estatísticas aeronave
SELECT * FROM vw_estatatisticas_aeronave 
WHERE aeronave_id = 2;

-- Consultar os máximos e mínimos de tempo e distancia da aeronave
SELECT 
    MAX(calcular_distancia_percorrida(trajeto_percorrido))::NUMERIC(10, 3) AS maior_distancia_km,
    MIN(calcular_distancia_percorrida(trajeto_percorrido))::NUMERIC(10, 3) AS menor_distancia_km,
    MAX(calcular_tempo_voo(inicio_voo, final_voo)) AS maior_tempo_voo_hh_mm_ss,
    MIN(calcular_tempo_voo(inicio_voo, final_voo)) AS menor_tempo_voo_hh_mm_ss
FROM voo
WHERE aeronave_id = 2;

-- Consultar velocidade média voo
SELECT 
id AS voo_id,
calcular_velocidade_media(trajeto_percorrido, inicio_voo, final_voo) AS velocidade_media_km_por_h
FROM voo
WHERE aeronave_id = 2;

-- Consultar ultimos voos usuário 
SELECT id, inicio_voo, final_voo AS voo_id
FROM voo
WHERE usuario_id = 2;