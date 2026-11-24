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
SELECT 
    v.id AS voo_id,
    a.prefixo,
    a.modelo,
    v.inicio_voo,
    v.final_voo,
    calcular_tempo_voo(v.inicio_voo, v.final_voo) AS tempo_voo,
    calcular_distancia_percorrida(v.trajeto_percorrido) AS distancia_km
FROM voo v
INNER JOIN aeronave a ON a.id = v.aeronave_id
WHERE a.usuario_id = 1
ORDER BY v.inicio_voo DESC;

-- Consultar aeronaves do usuário ordenadas pela data de fabricação
SELECT id, prefixo, modelo, fabricante, ano_fabricacao
FROM aeronave
WHERE usuario_id = 1
ORDER BY ano_fabricacao ASC;

-- Consultar dispositivos do usuário ordenados pela data de fabricação
SELECT d.id, d.modelo, d.ano_fabricacao, a.prefixo AS aeronave_instalada
FROM dispositivo d
LEFT JOIN aeronave a ON a.id = d.aeronave_id
WHERE d.usuario_id = 1
ORDER BY d.ano_fabricacao ASC;

-- Consultar leituras do sensor de acelerômetro acima de 2G direto no JSON
SELECT id, aeronave_id, momento_coleta, (pacote->>'modulo_acel')::NUMERIC AS modulo_acel_g
FROM telemetria_sensor
WHERE (pacote->>'modulo_acel')::NUMERIC > 2;