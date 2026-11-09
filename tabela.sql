CREATE TABLE IF NOT EXISTS aeronave
(
  id             serial   NOT NULL,
  prefixo        char(16) NOT NULL,
  modelo         char(20) NOT NULL,
  fabricante     char(40) NOT NULL,
  ano_fabricacao date     NOT NULL,
  usuario_id     integer  NOT NULL,
  usuario_id_2   integer  NOT NULL,
  
  CONSTRAINT pk_aeronave PRIMARY KEY (id)
);

CREATE TABLE IF NOT EXISTS area_voo
(
  id          serial  NOT NULL,
  aeronave_id integer NOT NULL,
  geom        polygon NOT NULL,
  
  CONSTRAINT pk_areavoo PRIMARY KEY (id),

  CONSTRAINT fk_aeronave
    FOREIGN KEY (aeronave_id)
    REFERENCES aeronave (id)
);

CREATE TABLE IF NOT EXISTS dispositivo
(
  id           serial   NOT NULL,
  modelo       char(20) NOT NULL,
  ano_fabricao date     NOT NULL,
  usuario_id   integer  NOT NULL,
  aeronave_id  integer  NULL    ,
  usuario_id   integer  NOT NULL,
  
  CONSTRAINT pk_dispositivo PRIMARY KEY (id),
  
  CONSTRAINT fk_aeronave
    FOREIGN KEY (aeronave_id)
    REFERENCES aeronave (id),

  CONSTRAINT fk_usuario
    FOREIGN KEY (usuario_id)
    REFERENCES usuario (id)
);

CREATE TABLE IF NOT EXISTS eventos
(
  id             serial8 NOT NULL,
  data           date    NOT NULL,
  aeronave_id    integer NOT NULL,
  dispositivo_id integer NOT NULL,
  
  CONSTRAINT pk_eventos PRIMARY KEY (id),

  CONSTRAINT fk_aeronave
    FOREIGN KEY (aeronave_id)
    REFERENCES aeronave (id),

  CONSTRAINT fk_dispositivo
    FOREIGN KEY (dispositivo_id)
    REFERENCES dispositivo (id)
);

CREATE TABLE IF NOT EXISTS gnss
(
  id             serial        NOT NULL,
  ponto          point         NOT NULL,
  velocidade     decimal(8,2)  NOT NULL,
  altitude       decimal(10,2) NOT NULL,
  aeronave_id    integer       NOT NULL,
  dispositivo_id integer       NOT NULL,
  
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
  id               serial  NOT NULL,
  pacote           json    NOT NULL,
  data_recebimento date    NOT NULL,
  aeronave_id      integer NOT NULL,
  dispositivo_id   integer NOT NULL,
  
  CONSTRAINT pk_telemetria_sensor PRIMARY KEY (id),
  
  CONSTRAINT fk_aeronave
    FOREIGN KEY (aeronave_id)
    REFERENCES aeronave (id),

  CONSTRAINT fk_dispositivo
    FOREIGN KEY (dispositivo_id)
    REFERENCES dispositivo (id)
);

CREATE TABLE IF NOT EXISTS usuario
(
  id       serial    NOT NULL,
  nome     char(120) NOT NULL,
  email    char(40)  NOT NULL,
  telefone char(11)  NOT NULL,

  CONSTRAINT pk_usuario PRIMARY KEY (id)
);