CREATE OR REPLACE VIEW vw_estatatisticas_aeronave AS
SELECT 
    a.id AS aeronave_id,
    a.prefixo,
    a.modelo,
    COUNT (v.id) AS total_voos,
    AVG(calcular_tempo_voo(v.inicio_voo, v.final_voo)) AS tempo_medio_hh_mm_ss,
    SUM(calcular_tempo_voo(v.inicio_voo, v.final_voo)) AS tempo_toal_hh_mm_ss,
    AVG(calcular_distancia_percorrida(v.trajeto_percorrido))::NUMERIC(10, 3) AS distancia_media_km,
    SUM(calcular_distancia_percorrida(v.trajeto_percorrido))::NUMERIC(10, 3) AS distancia_total_km
FROM aeronave a 
LEFT JOIN voo v ON v.aeronave_id = a.id
GROUP BY a.id, a.prefixo, a.modelo;


CREATE OR REPLACE VIEW vw_eventos_aeronave AS
SELECT 
    e.id AS evento_id,
    e.momento_evento,
    e.evento,
    e.aeronave_id,
    a.prefixo AS aeronave,
    d.modelo AS dispositivo
FROM evento e
INNER JOIN aeronave a ON a.id = e.aeronave_id
INNER JOIN dispositivo d ON d.id = e.dispositivo_id
ORDER BY e.momento_evento DESC, e.id DESC;