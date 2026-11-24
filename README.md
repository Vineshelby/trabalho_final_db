# Trabalho Final — Banco de Dados de Telemetria Aeroagrícola

Sistema de banco de dados relacional e geoespacial desenvolvido em **PostgreSQL + PostGIS** para monitoramento de telemetria, rastreamento GNSS, controle de zonas autorizadas de voo (talhões e pista) e geração automatizada de eventos operacionais na aviação agrícola.

---

## 1. Estrutura dos Arquivos

| Arquivo | Descrição |
| :--- | :--- |
| `diagrama.erd` | Diagrama Entidade-Relacionamento (ERD Editor). |
| `tabela.sql` | Criação das tabelas, chaves primárias, chaves estrangeiras e tipos geométricos PostGIS. |
| `trigger.sql` | Função e trigger para construção automática dos voos, trajetos e detecção de eventos. |
| `function.sql` | Funções para cálculo de tempo de voo, distância percorrida (km) e velocidade média (km/h). |
| `procedure.sql` | Procedimentos armazenados para transferência de dispositivos e troca de propriedade de aeronaves. |
| `view.sql` | Views de estatísticas consolidadas por aeronave e histórico detalhado de eventos. |
| `insert.sql` | Carga de dados cadastrais, polígonos de áreas de voo (GeoJSON) e 501 pontos GNSS reais/simulados distribuídos em 5 voos. |
| `select.sql` | Consultas analíticas utilizando as views e funções do banco. |
| `visualizacaoQGIS.qgz` | Projeto do QGIS para visualização espacial dos talhões (`area_voo`) e trajetos (`voo`). |

---

## 2. Modelo de Dados e Tabelas

- **`usuario`**: Cadastro dos proprietários/clientes responsáveis pelas aeronaves e dispositivos vinculados.
- **`aeronave`**: Cadastro das aeronaves agrícolas (`prefixo`, `modelo`, `fabricante`, `ano_fabricacao`, `usuario_id`).
- **`dispositivo`**: Módulos embarcados de telemetria (ex.: `ESP32-GNSS`), vinculados a uma aeronave (`aeronave_id`) e ao usuário responsável (`usuario_id`).
- **`area_voo`**: Polígonos georreferenciados (`geometry(Polygon, 4326)`) que delimitam as zonas autorizadas de operação de cada aeronave (talhões de aplicação e área do aeródromo).
- **`gnss`**: Registros brutos de telemetria GNSS contendo coordenada (`geometry(Point, 4326)`), velocidade, altitude e timestamp (`momento_coleta`).
- **`telemetria_sensor`**: Leituras de sensores embarcados armazenadas em formato `json`.
- **`voo`**: Sessões de voo geradas automaticamente a partir do GNSS, contendo `inicio_voo`, `final_voo` e a geometria completa da rota em `geometry(LineString, 4326)` (`trajeto_percorrido`).
- **`evento`**: Log automático de eventos operacionais vinculados ao voo, aeronave e dispositivo (`DECOLAGEM`, `POUSO`, `DENTRO DE ZONA AUTORIZADA`, `FORA DE ZONA AUTORIZADA`).

---

## 3. Regras de Negócio Implementadas

### 3.1. Propriedade e Preservação de Histórico
- **Responsabilidade de Dispositivos**: O proprietário da aeronave é automaticamente o responsável pelo dispositivo instalado nela. Qualquer troca de dispositivo de aeronave ou venda/transferência de aeronave atualiza o vínculo de usuário de forma atômica via *Stored Procedures*.
- **Histórico Imutável**: As tabelas operacionais (`gnss`, `voo`, `evento`, `telemetria_sensor`) armazenam tanto o `aeronave_id` quanto o `dispositivo_id` do momento da operação. Assim, caso um dispositivo seja movido para outra aeronave no futuro, o histórico de voos passados permanece íntegro.

### 3.2. Processamento Automático de Voo e Eventos (`trigger.sql`)
A trigger `trigger_constroi_voo` (`AFTER INSERT ON gnss`) executa a função `atualizar_voo()` a cada ponto GNSS recebido:
1. **Validação de Vínculo**: Verifica se o `dispositivo_id` recebido está realmente instalado na `aeronave_id` informada; caso contrário, aborta a inserção com `RAISE EXCEPTION`.
2. **Abertura e Construção do Trajeto (`voo`)**:
   - Se não houver voo em aberto (`final_voo IS NULL`) para a aeronave e a velocidade for maior que zero (`NEW.velocidade > 0`), cria um novo registro na tabela `voo` inicializando o `trajeto_percorrido` com `ST_MakeLine`.
   - Para os pontos subsequentes do mesmo voo, concatena o novo vértice à `LineString` existente com `ST_AddPoint`.
3. **Detecção de Decolagem e Pouso (`evento`)**:
   - **`DECOLAGEM`**: Registrada na tabela `evento` assim que a aeronave atinge `velocidade >= 100` km/h pela primeira vez no voo atual.
   - **`POUSO`**: Registrado quando a aeronave desacelera até `velocidade = 0` após já ter decolado, preenchendo automaticamente o `final_voo` na tabela `voo`.
4. **Monitoramento de Geofencing / Zona Autorizada (`area_voo`)**:
   - Utiliza `ST_Intersects` para verificar se o ponto atual e o último ponto do trajeto (`ST_EndPoint`) estão contidos nos polígonos autorizados da aeronave.
   - Registra o estado inicial no primeiro ponto do voo e gera novos eventos **`DENTRO DE ZONA AUTORIZADA`** ou **`FORA DE ZONA AUTORIZADA`** sempre que a aeronave cruza a fronteira de um talhão ou aeródromo.
5. **Monitoramento de Sensores via JSON (`trigger_telemetria_sensor` / `verificar_telemetria_sensor()`)**:
   - Ao inserir um pacote JSON em `telemetria_sensor`, extrai o módulo do acelerômetro (`(NEW.pacote->>'modulo_acel')::NUMERIC`).
   - Se o valor for superior a `2` ($> 2\text{G}$), registra um evento **`IMPACTO DETECTADO`**.
   - Caso exista um voo em aberto (`final_voo IS NULL`) para a aeronave no momento da leitura, vincula o evento ao `voo_id` atual; caso a aeronave esteja em solo (sem voo aberto), grava `voo_id = NULL`.

### 3.3. Procedures (`procedure.sql`)
- **`alterar_aeronave_dispositivo(id_dispositivo_troca, id_nova_aeronave)`**: Move um dispositivo para outra aeronave e sincroniza automaticamente o `usuario_id` do dispositivo com o dono da nova aeronave.
- **`alterar_dono_aeronave(id_aeronave_alteracao, id_novo_dono)`**: Transfere a propriedade de uma aeronave para um novo usuário e atualiza em cascata todos os dispositivos alocados nela (emitindo um `RAISE NOTICE` caso a aeronave não possua dispositivos no momento).

### 3.4. Functions (`function.sql`)
- **`calcular_tempo_voo(inicio_voo, fim_voo)`**: Retorna o `INTERVAL` de duração do voo (ou o tempo decorrido até `NOW()` com aviso caso o voo ainda esteja em andamento).
- **`calcular_distancia_percorrida(trajeto)`**: Calcula a distância real percorrida em quilômetros convertendo a `LineString` para `geography` (`ST_Length(trajeto::geography) / 1000`).
- **`calcular_velocidade_media(trajeto, inicio_voo, fim_voo)`**: Calcula a velocidade média do voo em `km/h` reutilizando as funções de distância e tempo.

### 3.5. Views (`view.sql`)
- **`vw_estatatisticas_aeronave`**: Consolida por aeronave o total de voos, tempo médio, tempo total, distância média (km) e distância total (km).
- **`vw_eventos_aeronave`**: Lista o histórico de eventos ordenado do mais recente para o mais antigo com prefixo da aeronave e modelo do dispositivo.

---

## 4. Ordem de Execução e Comandos

> **Importante:** A `trigger.sql` deve ser executada **antes** do `insert.sql` para que a inserção dos pontos GNSS popule automaticamente as tabelas `voo` e `evento`. O `function.sql` deve ser executado **antes** do `view.sql`, pois as views utilizam as funções de cálculo.

### Passo 1 — Subir o banco PostgreSQL + PostGIS via Docker
```bash
docker run -d --name postgis -e POSTGRES_PASSWORD=senha -p 5433:5432 postgis/postgis
```

Para acessar o banco pelo terminal (`psql`):
```bash
psql -h localhost -p 5433 -U postgres -d postgres
```

### Passo 2 — Habilitar a extensão PostGIS e executar os scripts SQL na ordem correta

Dentro do console interativo do `psql`:
```sql
CREATE EXTENSION IF NOT EXISTS postgis;
\i tabela.sql
\i trigger.sql
\i function.sql
\i procedure.sql
\i view.sql
\i insert.sql
\i select.sql
```

---

## 5. Exemplos de Consultas e Comandos Úteis (`select.sql`)

### Consultar Views (Eventos e Estatísticas)
```sql
-- Consultar os últimos 10 eventos de uma aeronave
SELECT * FROM vw_eventos_aeronave
WHERE aeronave_id = 2
LIMIT 10;

-- Consultar todos os eventos de uma aeronave
SELECT * FROM vw_eventos_aeronave
WHERE aeronave_id = 2;

-- Consultar os eventos apenas do último voo de uma aeronave
SELECT id AS evento_id, momento_evento, evento, aeronave_id, voo_id
FROM evento
WHERE voo_id = (
    SELECT id
    FROM voo
    WHERE aeronave_id = 2
    ORDER BY inicio_voo DESC, id DESC
    LIMIT 1
)
ORDER BY momento_evento ASC, id ASC;

-- Consultar estatísticas consolidadas de uma aeronave
SELECT * FROM vw_estatatisticas_aeronave
WHERE aeronave_id = 2;
```

### Consultas Analíticas com Functions (Distância, Tempo e Velocidade)
```sql
-- Consultar os máximos e mínimos de tempo e distância da aeronave
SELECT 
    MAX(calcular_distancia_percorrida(trajeto_percorrido))::NUMERIC(10, 3) AS maior_distancia_km,
    MIN(calcular_distancia_percorrida(trajeto_percorrido))::NUMERIC(10, 3) AS menor_distancia_km,
    MAX(calcular_tempo_voo(inicio_voo, final_voo)) AS maior_tempo_voo_hh_mm_ss,
    MIN(calcular_tempo_voo(inicio_voo, final_voo)) AS menor_tempo_voo_hh_mm_ss
FROM voo
WHERE aeronave_id = 2;

-- Consultar velocidade média dos voos de uma aeronave
SELECT 
    id AS voo_id,
    calcular_velocidade_media(trajeto_percorrido, inicio_voo, final_voo) AS velocidade_media_km_por_h
FROM voo
WHERE aeronave_id = 2;

-- Consultar os últimos voos de um usuário
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

-- Consultar aeronaves e dispositivos do usuário ordenados pela data de fabricação
SELECT id, prefixo, modelo, fabricante, ano_fabricacao
FROM aeronave
WHERE usuario_id = 1
ORDER BY ano_fabricacao ASC;

SELECT d.id, d.modelo, d.ano_fabricacao, a.prefixo AS aeronave_instalada
FROM dispositivo d
LEFT JOIN aeronave a ON a.id = d.aeronave_id
WHERE d.usuario_id = 1
ORDER BY d.ano_fabricacao ASC;
```

### Chamar as Procedures
```sql
-- Transferir o dispositivo 1 para a aeronave 2
CALL alterar_aeronave_dispositivo(1, 2);

-- Transferir a aeronave 1 (e seus dispositivos) para o usuário 1
CALL alterar_dono_aeronave(1, 1);
```

### Visualizar Trajetos e Polígonos
- **No QGIS**: Abra o arquivo `visualizacaoQGIS.qgz` conectado ao banco PostGIS na porta `5433`.
