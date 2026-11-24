CREATE TABLE IF NOT EXISTS usuario
(
  id       serial    NOT NULL,
  nome     varchar(120) NOT NULL,
  email    varchar(40)  NOT NULL,
  telefone char(11)  NOT NULL,

  CONSTRAINT pk_usuario PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS aeronave
(
  id             serial   NOT NULL,
  prefixo        varchar(16) NOT NULL,
  modelo         varchar(20) NOT NULL,
  fabricante     varchar(40) NOT NULL,
  ano_fabricacao date     NOT NULL,
  usuario_id     integer  NOT NULL,
  
  CONSTRAINT pk_aeronave PRIMARY KEY (id),

  CONSTRAINT fk_usuario
    FOREIGN KEY (usuario_id)
    REFERENCES usuario (id)
);

CREATE TABLE IF NOT EXISTS area_voo
(
  id          serial                  NOT NULL,
  aeronave_id integer                 NOT NULL,
  geom        geometry(Polygon, 4326) NOT NULL,
  
  CONSTRAINT pk_areavoo PRIMARY KEY (id),

  CONSTRAINT fk_aeronave
    FOREIGN KEY (aeronave_id)
    REFERENCES aeronave (id)
);

CREATE TABLE IF NOT EXISTS dispositivo
(
  id              serial      NOT NULL,
  modelo          varchar(20) NOT NULL,
  ano_fabricacao  date   NOT NULL,
  usuario_id      integer     NOT NULL,
  aeronave_id     integer     NULL    ,
  
  CONSTRAINT pk_dispositivo PRIMARY KEY (id),
  
  CONSTRAINT fk_aeronave
    FOREIGN KEY (aeronave_id)
    REFERENCES aeronave (id),

  CONSTRAINT fk_usuario
    FOREIGN KEY (usuario_id)
    REFERENCES usuario (id)
);

CREATE TABLE IF NOT EXISTS voo
(
  id                 serial8                    NOT NULL,
  inicio_voo         timestamp                  NOT NULL,
  final_voo          timestamp                  NULL    ,
  trajeto_percorrido geometry(LineString, 4326) NOT NULL,
  aeronave_id        integer                    NOT NULL,
  dispositivo_id     integer                    NOT NULL,

  CONSTRAINT pk_voo PRIMARY KEY (id),

  CONSTRAINT fk_aeronave
    FOREIGN KEY (aeronave_id)
    REFERENCES aeronave (id),

  CONSTRAINT fk_dispositivo
    FOREIGN KEY (dispositivo_id)
    REFERENCES dispositivo (id)
);

CREATE TABLE IF NOT EXISTS evento
(
  id              serial8       NOT NULL,
  momento_evento  timestamp     NOT NULL,
  evento          varchar(300)  NOT NULL,
  aeronave_id     integer       NOT NULL,
  dispositivo_id  integer       NOT NULL,
  voo_id          int8          NULL,
  
  CONSTRAINT pk_evento PRIMARY KEY (id),

  CONSTRAINT fk_aeronave
    FOREIGN KEY (aeronave_id)
    REFERENCES aeronave (id),

  CONSTRAINT fk_dispositivo
    FOREIGN KEY (dispositivo_id)
    REFERENCES dispositivo (id),

  CONSTRAINT fk_voo
    FOREIGN KEY (voo_id)
    REFERENCES voo (id)
);

CREATE TABLE IF NOT EXISTS gnss
(
  id             serial                 NOT NULL,
  momento_coleta timestamp              NOT NULL,
  ponto          geometry(Point, 4326)  NOT NULL,
  velocidade     decimal(8,2)           NOT NULL,
  altitude       decimal(10,2)          NOT NULL,
  aeronave_id    integer                NOT NULL,
  dispositivo_id integer                NOT NULL,
  
  CONSTRAINT pk_gnss PRIMARY KEY (id),
  
  CONSTRAINT fk_aeronave
    FOREIGN KEY (aeronave_id)
    REFERENCES aeronave (id),

  CONSTRAINT fk_dispositivo
    FOREIGN KEY (dispositivo_id)
    REFERENCES dispositivo (id)
);

CREATE TABLE IF NOT EXISTS telemetria_sensor
(
  id               serial       NOT NULL,
  pacote           json         NOT NULL,
  momento_coleta   timestamp    NOT NULL,
  aeronave_id      integer      NOT NULL,
  dispositivo_id   integer      NOT NULL,
  
  CONSTRAINT pk_telemetria_sensor PRIMARY KEY (id),
  
  CONSTRAINT fk_aeronave
    FOREIGN KEY (aeronave_id)
    REFERENCES aeronave (id),

  CONSTRAINT fk_dispositivo
    FOREIGN KEY (dispositivo_id)
    REFERENCES dispositivo (id)
);