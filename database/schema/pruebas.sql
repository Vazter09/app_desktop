CREATE TABLE IF NOT EXISTS tab_temp_fichas_creadas
 (
    cod_ficha                DECIMAL,
    nom_programa             VARCHAR,
    horas_programa           VARCHAR,
    fec_inicio               DATE,
    fec_fin                  DATE,
    fec_ejecucion            VARCHAR,
    estado_ficha             VARCHAR,
    cantidad_aprendices      DECIMAL,
    cant_aprendices_transito DECIMAL,
    tipo_documento           VARCHAR,
    num_documento            DECIMAL,
    nombre_instructor        VARCHAR,
    apellido_instructor      VARCHAR
 );


-- Actualizar tablas del script de smartcset.

 CREATE TABLE IF NOT EXISTS tab_instructores
(
    id_instructor           DECIMAL(10,0)               NOT NULL CHECK(id_instructor > 10000000),
    id_centro               DECIMAL(4,0)                NOT NULL DEFAULT 9309,
    ind_tipo_contrato       BOOLEAN                     NOT NULL DEFAULT TRUE, --TRUE=Planta / FALSE=Contratista. Si es contratista, se debe consultar el vigente en la tabla tab_contratos_instructor
    ind_contratado_actual   BOOLEAN                     NOT NULL DEFAULT TRUE, --TRUE=Contratado actualmente / FALSE=No Contratado. Si está contratado debe consultarse el contrato en la tabla hija
    ind_est_civil           DECIMAL(1,0)                NOT NULL CHECK(ind_est_civil >= 0 AND ind_est_civil <=9) DEFAULT 0,--1=Casado 2=Soltero 3=Unión Libre', 3=Viudo, 4=Divorciado, 0=Otro
    id_red                  DECIMAL(2,0)                NOT NULL DEFAULT 99,
    ind_disponibilidad      BOOLEAN                     NOT NULL DEFAULT TRUE, -- TRUE=Disponible / FALSE=No Disponible (Ocupado con tiempo completo)
    ind_estado              DECIMAL(1,0)                NOT NULL CHECK(ind_estado >= 0 AND ind_estado <= 9) DEFAULT 0, -- 0=Activo,2=Suspendido,3=Bloqueado,9=Inactivo;
    usr_insert              VARCHAR(50)                 NOT NULL CHECK(LENGTH(TRIM(usr_insert)) >= 3),
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR(50)                          CHECK(LENGTH(TRIM(usr_update)) >= 3),
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_instructor),
    FOREIGN KEY(id_instructor)    REFERENCES tab_personas(id_persona),
    FOREIGN KEY(id_centro)        REFERENCES tab_centros(id_centro),
    FOREIGN KEY(id_nivel_estudio) REFERENCES tab_niveles_estudio(id_nivel_estudio),
    FOREIGN KEY(id_profesion)     REFERENCES tab_profesiones(id_profesion),
    FOREIGN KEY(id_red)           REFERENCES tab_redes(id_red)
);

CREATE TABLE IF NOT EXISTS tab_temp_df14A
(
  fecha_reporte     DATE,
  cod_regional      DECIMAL(2,0),
  nom_regional      VARCHAR,
  cod_centro        DECIMAL(4,0),
  nom_centro        VARCHAR,
  cod_programa      DECIMAL(8,0),
  cod_ver_programa  DECIMAL(3,0),
  nom_programa      VARCHAR,
  niv_formacion     VARCHAR,
  dur_maxima        DECIMAL,
  dur_eta_lectiva   VARCHAR,
  dur_eta_productiv VARCHAR,
  id_ficha          DECIMAL(8,0),
  fec_ini_ficha     DATE,
  fec_fin_ficha     DATE,
  num_cupo          DECIMAL(4,0),
  estado_ficha      VARCHAR,
  tipo_respuesta    VARCHAR,
  programa_especial VARCHAR,
  cod_convenio      DECIMAL(1,0),
  ind_cobertura     VARCHAR,
  nom_convenio      VARCHAR,
  tip_docum_empresa VARCHAR,
  num_docum_empresa DECIMAL(10,0),
  nom_empresa       VARCHAR,
  en_transito       VARCHAR,
  ind_induccion     DECIMAL(2,0),
  ind_formacion     DECIMAL(2,0),
  ind_condicionado  DECIMAL(2,0),
  ind_aplazado      DECIMAL(2,0),
  ind_retiro_volun  DECIMAL(2,0),
  ind_canc_virtual  DECIMAL(2,0),
  ind_deser_virtual DECIMAL(2,0),
  ind_cancelado     DECIMAL(2,0),
  ind_por_certif    DECIMAL(2,0),
  ind_certificado   DECIMAL(2,0),
  ind_traslado      DECIMAL(2,0),
  ind_otros         DECIMAL(2,0)
);

CREATE TABLE IF NOT EXISTS tab_temp_df49
(
  fecha_reporte     DATE,
  cod_regional      DECIMAL(2,0),
  nom_regional      VARCHAR,
  cod_centro        DECIMAL(4,0),
  nom_centro        VARCHAR,
  id_ficha          DECIMAL(7,0),
  fec_inicial       VARCHAR,
  fec_final         VARCHAR,
  ind_estado        VARCHAR,
  id_programa       DECIMAL(8,0),
  id_version        DECIMAL(4,0),
  nom_programa      VARCHAR,
  ind_nivel         VARCHAR,
  num_aprend_matric DECIMAL(3,0),
  num_aprend_certif DECIMAL(3,0),
  num_aprend_sincer DECIMAL(3,0),
  num_aprend_sinjui DECIMAL(3,0),
  num_aprend_noapro DECIMAL(3,0),
  id_convenio       DECIMAL(1,0),
  nom_convenio      VARCHAR,
  ind_cobertura     VARCHAR,
  id_prog_especial  DECIMAL(6,0),
  nom_prog_especial VARCHAR 
);

-- ESTO FALTA CORREGIR


CREATE TABLE tab_asistencia_aprendiz
(
    id_aprendiz             DECIMAL(10,0)               NOT NULL,
    fec_asistencia          DATE                        NOT NULL,
    hora_asistencia         TIME                        NOT NULL,
    minutos_retraso         INT                         NOT NULL DEFAULT 0,
    ind_estado              TIPO_ESTADO_ASISTENCIA GENERATED ALWAYS AS
    (
        (CASE
            WHEN minutos_retraso <= 5 THEN 'Presente'
            WHEN minutos_retraso > 5 AND minutos_retraso <= 15 THEN 'Tarde'
            ELSE 'Ausente' 
        END)::TIPO_ESTADO_ASISTENCIA
    ) STORED,
    usr_insert              VARCHAR(50)                 NOT NULL CHECK(LENGTH(TRIM(usr_insert)) >= 3),
    -- Optimización: Dejar que la base de datos ponga la fecha de creación automáticamente
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR(50)                 CHECK(LENGTH(TRIM(usr_update)) >= 3),
    fec_update              TIMESTAMP WITHOUT TIME ZONE,    
    PRIMARY KEY(id_aprendiz, fec_asistencia),
    FOREIGN KEY(id_aprendiz) REFERENCES tab_aprendices(id_aprendiz)
);

-- TABLA DE TAB_AUSENCIAS_APRENDIZ
-- __________________________________________________________________________________________________________________________
-- | Columna        | Tipo             | Restricción                            | Descripción                                   |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | id_aprendiz    | DECIMAL(10,0)    | NOT NULL                               |                                               |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | fec_ausencia   | DATE             | NOT NULL DEFAULT '1900-01-01' CHECK (fec_ausencia <= CURRENT_DATE) | Fecha/hora.                                   |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | val_motivo     | TEXT             | NOT NULL DEFAULT 'Sin Motivo Ausencia Aprendiz' |                                               |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | ind_evidencia_excusa | BOOLEAN          | NOT NULL DEFAULT TRUE                  | Indicador booleano.                           |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | val_ruta_excusa | VARCHAR          | NOT NULL DEFAULT 'Sin ruta evidencia Aprendiz' |                                               |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | usr_insert     | VARCHAR          | NOT NULL                               | Usuario que creó/actualizó el registro.       |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | fec_insert     | TIMESTAMP WITHOUT TIME ZONE | NOT NULL                               | Fecha/hora.                                   |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | usr_update     | VARCHAR          |                                        | Usuario que creó/actualizó el registro.       |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | fec_update     | TIMESTAMP WITHOUT TIME ZONE |                                        | Fecha/hora.                                   |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+

CREATE TABLE IF NOT EXISTS tab_ausencias_aprendiz
(
    id_aprendiz             DECIMAL(10,0)               NOT NULL,
    fec_ausencia            DATE                        NOT NULL DEFAULT '1900-01-01' CHECK (fec_ausencia <= CURRENT_DATE),
    val_motivo              TEXT                        NOT NULL DEFAULT 'Sin Motivo Ausencia Aprendiz',
    ind_evidencia_excusa    BOOLEAN                     NOT NULL DEFAULT TRUE,   -- TRUE=Hay evidencia / FALSE=Nol hay evidencia
    val_ruta_excusa         VARCHAR                     NOT NULL DEFAULT 'Sin ruta evidencia Aprendiz',
    usr_insert              VARCHAR(50)                 NOT NULL CHECK(LENGTH(TRIM(usr_insert)) >= 3),
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR(50)                          CHECK(LENGTH(TRIM(usr_update)) >= 3),
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_aprendiz,fec_ausencia),
    FOREIGN KEY(id_aprendiz)                REFERENCES tab_aprendices(id_aprendiz)
);

-- TABLA DE LLAMADOS DE ATENCIÓN

-- TABLA DE TAB_LLAMADOS_ATENCION
-- ______________________________________________________________________________________________________________________________
-- |     Columna      |        Tipo       |             Restricción              | Descripción                                   |
-- +------------------+-------------------+--------------------------------------+-----------------------------------------------+
-- | id_llamado       | SERIAL            | PRIMARY KEY                          | Número identificador del llamado de atención. |
-- |                  |                   | NOT NULL                             |                                               |
-- +------------------+-------------------+--------------------------------------+-----------------------------------------------+
-- | ind_tipo         | BOOLEAN           | NOT NULL                             | Indicador de tipo de llamado de atención.     |
-- |                  |                   |                                      | TRUE=Académico, FALSE=Disciplinario.          |
-- +------------------+-------------------+--------------------------------------+-----------------------------------------------+
-- | id_tercero       | DECIMAL(10,0)     | NOT NULL                             | Identificador del tercero.                    |
-- +------------------+-------------------+--------------------------------------+-----------------------------------------------+
-- | ind_tipo_tercero | BOOLEAN           | NOT NULL                             | Indicador de tipo de tercero asociado.        |
-- |                  |                   |                                      | TRUE=Aprendiz, FALSE=No es aprendiz.          |
-- +------------------+-------------------+--------------------------------------+-----------------------------------------------+
-- | fec_llamado      | DATE              | NOT NULL                             | Fecha del llamado de atención.                |
-- +------------------+-------------------+--------------------------------------+-----------------------------------------------+
-- | usr_insert       | VARCHAR(50)       | NOT NULL                             | Usuario que creó el registro.                 |
-- |                  |                   | CHECK(LENGTH(TRIM(usr_insert)) >= 3) |                                               |
-- +------------------+-------------------+--------------------------------------+-----------------------------------------------+
-- | fec_insert       | TIMESTAMP         | NOT NULL                             | Fecha/hora de creación del registro.          |
-- |                  | WITHOUT TIME ZONE |                                      |                                               |
-- +------------------+-------------------+--------------------------------------+-----------------------------------------------+
-- | usr_update       | VARCHAR(50)       | CHECK(LENGTH(TRIM(usr_update)) >= 3) | Usuario que actualizó el registro.            |
-- +------------------+-------------------+--------------------------------------+-----------------------------------------------+
-- | fec_update       | TIMESTAMP         |                                      | Fecha/hora de actualización del registro.     |
-- |                  | WITHOUT TIME ZONE |                                      |                                               |
-- +------------------+-------------------+--------------------------------------+-----------------------------------------------+

CREATE TABLE IF NOT EXISTS tab_llamados_atencion
(
    id_llamado              SERIAL                      NOT NULL,
    ind_tipo                BOOLEAN                     NOT NULL,   -- TRUE=Académico / FALSE=Disciplinario
    id_tercero              DECIMAL(10,0)               NOT NULL,
    ind_tipo_tercero        BOOLEAN                     NOT NULL,   -- TRUE=Aprendiz / FALSE=No es aprendiz
    fec_llamado             DATE                        NOT NULL,
    usr_insert              VARCHAR(50)                 NOT NULL CHECK(LENGTH(TRIM(usr_insert)) >= 3),
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR(50)                          CHECK(LENGTH(TRIM(usr_update)) >= 3),
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_llamado)
);

-- TABLA DE OFERTAS TRIMESTRALES

-- TABLA DE TAB_OFERTAS
-- _________________________________________________________________________________________________________________________
-- |     Columna     |        Tipo       |              Restricción             |                 Descripción               |
-- +---------------- +-------------------+--------------------------------------+-------------------------------------------+
-- | id_oferta       | SMALLINT          | PRIMARY KEY                          | Número identificador de la oferta.        |
-- |                 |                   | NOT NULL                             |                                           |
-- +---------------- +-------------------+--------------------------------------+-------------------------------------------+
-- | ano_oferta      | DECIMAL(4,0)      | NOT NULL                             | Año de la oferta.                         |
-- +---------------- +-------------------+--------------------------------------+-------------------------------------------+
-- | trim_oferta     | DECIMAL(1,0)      | NOT NULL                             | Trimestre de la oferta.                   |
-- +---------------- +-------------------+--------------------------------------+-------------------------------------------+
-- | num_oferta      | DECIMAL(1,0)      | NOT NULL                             | Número de la oferta.                      |
-- +---------------- +-------------------+--------------------------------------+-------------------------------------------+
-- | ind_tipo_oferta | BOOLEAN           | NOT NULL DEFAULT TRUE                | Tipo de oferta.                           |
-- |                 |                   |                                      | TRUE=Presencial, FALSE=Virtual.           |
-- +---------------- +-------------------+--------------------------------------+-------------------------------------------+
-- | usr_insert      | VARCHAR(50)       | NOT NULL                             | Usuario que creó el registro.             |
-- |                 |                   | CHECK(LENGTH(TRIM(usr_insert)) >= 3) |                                           |
-- +---------------- +-------------------+--------------------------------------+-------------------------------------------+
-- | fec_insert      | TIMESTAMP         | NOT NULL                             | Fecha/hora de creación del registro.      |
-- |                 | WITHOUT TIME ZONE |                                      |                                           |
-- +---------------- +-------------------+--------------------------------------+-------------------------------------------+
-- | usr_update      | VARCHAR(50)       | CHECK(LENGTH(TRIM(usr_update)) >= 3) | Usuario que actualizó el registro.        |
-- +---------------- +-------------------+--------------------------------------+-------------------------------------------+
-- | fec_update      | TIMESTAMP         |                                      | Fecha/hora de actualización del registro. |
-- |                 | WITHOUT TIME ZONE |                                      |                                           |
-- +---------------- +-------------------+--------------------------------------+-------------------------------------------+

CREATE TABLE IF NOT EXISTS tab_ofertas
(
    id_oferta               SMALLINT                    NOT NULL,
    ano_oferta              DECIMAL(4,0)                NOT NULL,
    trim_oferta             DECIMAL(1,0)                NOT NULL,
    num_oferta              DECIMAL(1,0)                NOT NULL,
    ind_tipo_oferta         BOOLEAN                     NOT NULL DEFAULT TRUE,  --TRUE=Presencial / FALSE=Virtual)
    usr_insert              VARCHAR(50)                 NOT NULL CHECK(LENGTH(TRIM(usr_insert)) >= 3),
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR(50)                          CHECK(LENGTH(TRIM(usr_update)) >= 3),
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_oferta)
);

-- Tabla de competencias por Ficha

-- TABLA DE TAB_COMPETENCIAS_FICHA
-- _______________________________________________________________________________________________________________________________
-- | Columna         |      Tipo         |                  Restricción               |                Descripción                |
-- +-----------------+-------------------+--------------------------------------------+-------------------------------------------+
-- | id_ficha        | DECIMAL(10,0)     | PRIMARY KEY                                | Número identificador de la ficha.         |
-- |                 |                   | FOREIGN KEY                                |                                           |
-- |                 |                   | NOT NULL                                   |                                           |
-- +-----------------+-------------------+--------------------------------------------+-------------------------------------------+
-- | id_competencia  | DECIMAL(10,0)     | PRIMARY KEY                                | Número identificador de la competencia.   |
-- |                 |                   | FOREIGN KEY                                |                                           |
-- |                 |                   | NOT NULL                                   |                                           |
-- +-----------------+-------------------+--------------------------------------------+-------------------------------------------+
-- | ind_estado      | DECIMAL(1,0)      | NOT NULL                                   | Estado de la competencia en la ficha.     |
-- |                 |                   | CHECK(ind_estado >= 0 AND ind_estado <= 3) | 0=No vista, 1=En curso, 2=Vista           |
-- +-----------------+-------------------+--------------------------------------------+-------------------------------------------+
-- | usr_insert      | VARCHAR(50)       | NOT NULL                                   | Usuario que creó el registro.             |
-- |                 |                   | CHECK(LENGTH(TRIM(usr_insert)) >= 3)       |                                           |
-- +-----------------+-------------------+--------------------------------------------+-------------------------------------------+
-- | fec_insert      | TIMESTAMP         | NOT NULL                                   | Fecha/hora de creación del registro.      |
-- |                 | WITHOUT TIME ZONE |                                            |                                           |
-- +-----------------+-------------------+--------------------------------------------+-------------------------------------------+
-- | usr_update      | VARCHAR(50)       | CHECK(LENGTH(TRIM(usr_update)) >= 3)       | Usuario que actualizó el registro.        |
-- +-----------------+-------------------+--------------------------------------------+-------------------------------------------+
-- | fec_update      | TIMESTAMP         |                                            | Fecha/hora de actualización del registro. |
-- |                 | WITHOUT TIME ZONE |                                            |                                           |
-- +-----------------+-------------------+--------------------------------------------+-------------------------------------------+

CREATE TABLE IF NOT EXISTS tab_competencias_ficha
(
    id_ficha                DECIMAL(10,0)               NOT NULL,
    id_competencia          DECIMAL(10,0)               NOT NULL,
    ind_estado              DECIMAL(1,0)                NOT NULL CHECK(ind_estado >= 0 AND ind_estado <= 3), --0=No vista / 1=En curso / 2=Vista
    usr_insert              VARCHAR(50)                 NOT NULL CHECK(LENGTH(TRIM(usr_insert)) >= 3),
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR(50)                          CHECK(LENGTH(TRIM(usr_update)) >= 3),
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_ficha,id_competencia),
    FOREIGN KEY(id_ficha)               REFERENCES tab_fichas(id_ficha),
    FOREIGN KEY(id_competencia)         REFERENCES tab_competencias(id_competencia)
);

-- Tabla de rutas de formación. Se le asociará un CRUD específico y trato especial
-- Tabla de rutas

-- TABLA DE TAB_RUTAS
-- _________________________________________________________________________________________________________________________
-- |     Columna     |       Tipo        |              Restricción             | Descripción                               |
-- +-----------------+-------------------+--------------------------------------+-------------------------------------------+
-- | id_ruta         | DECIMAL(8,0)      | PRIMARY KEY                          | Número identificador de la ruta.          |
-- |                 |                   | NOT NULL                             |                                           |
-- +-----------------+-------------------+--------------------------------------+-------------------------------------------+
-- | id_ficha        | DECIMAL(10,0)     | FOREIGN KEY                          | Número identificador de la ficha.         |
-- |                 |                   | NOT NULL                             |                                           |
-- +-----------------+-------------------+--------------------------------------+-------------------------------------------+
-- | nom_ruta        | VARCHAR           | NOT NULL                             | Nombre de la ruta.                        |
-- |                 |                   | CHECK(LENGTH(nom_ruta) >= 5)         |                                           |
-- +-----------------+-------------------+--------------------------------------+-------------------------------------------+
-- | usr_insert      | VARCHAR(50)       | NOT NULL                             | Usuario que creó el registro.             |
-- |                 |                   | CHECK(LENGTH(TRIM(usr_insert)) >= 3) |                                           |
-- +-----------------+-------------------+--------------------------------------+-------------------------------------------+
-- | fec_insert      | TIMESTAMP         | NOT NULL                             | Fecha/hora de creación del registro.      |
-- |                 | WITHOUT TIME ZONE |                                      |                                           |
-- +-----------------+-------------------+--------------------------------------+-------------------------------------------+
-- | usr_update      | VARCHAR(50)       | CHECK(LENGTH(TRIM(usr_update)) >= 3) | Usuario que actualizó el registro.        |
-- +-----------------+-------------------+--------------------------------------+-------------------------------------------+
-- | fec_update      | TIMESTAMP         |                                      | Fecha/hora de actualización del registro. |
-- |                 | WITHOUT TIME ZONE |                                      |                                           |
-- +-----------------+-------------------+--------------------------------------+-------------------------------------------+
CREATE TABLE IF NOT EXISTS tab_rutas
(
    id_ruta                 DECIMAL(8,0)                NOT NULL,
    id_ficha                DECIMAL(10,0)               NOT NULL,
    nom_ruta                VARCHAR                     NOT NULL CHECK(LENGTH(nom_ruta) >= 5),
    usr_insert              VARCHAR(50)                 NOT NULL CHECK(LENGTH(TRIM(usr_insert)) >= 3),
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR(50)                          CHECK(LENGTH(TRIM(usr_update)) >= 3),
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_ruta),
    FOREIGN KEY(id_ficha)                   REFERENCES tab_fichas(id_ficha)
);

-- Tabla de programación de instructores de acuerdo con la ficha, la ruta, el ambiente y la jornada
-- Se considera la principal estructura dentro del modelo, dadas las transacciones que generará a través de un algoritmo que sea automático.
-- El algoritmo tendrá componentes matemáticos que generarán una programación sugerida para un instructor, teniendo en cuenta su objeto contractual (160 hrs/mes)
-- Los ambientes de foración, las rutas, la planeación formativa, la jornada y una ficha.
-- Los instructores transversales no son líderes de ficha, por lo cual deben ser asignadaos a competneicas que duran entre 40 y 60 horas.
-- Esta tabla entonces, será el eje para la construcción del algoritmo de lógica avanzada que debe contemplar todas las tablas como componente de IA

-- TABLA DE TAB_PROGRAMACION
-- __________________________________________________________________________________________________________________________________________________________
-- | Columna         |      Tipo         |                 Restricción                  |                           Descripción                              |
-- +-----------------+-----------------------------+-----------------------------------------------+---------------------------------------------------------+
-- | id_ruta         | DECIMAL(8,0)      | PRIMARY KEY                                  | Número identificador de la ruta de formación.                      |
-- |                 |                   | NOT NULL                                     |                                                                    |
-- +-----------------+-----------------------------+-----------------------------------------------+---------------------------------------------------------+
-- | id_ficha        | DECIMAL(10,0)     | PRIMARY KEY                                  | Número identificador de la ficha.                                  |
-- |                 |                   | FOREIGN KEY                                  |                                                                    |
-- |                 |                   | NOT NULL                                     |                                                                    |
-- +-----------------+-----------------------------+-----------------------------------------------+---------------------------------------------------------+
-- | id_fase         | DECIMAL(1,0)      | NOT NULL                                     | Fase de la formación.                                              |
-- |                 |                   |                                              | 1=Inducción, 2=Planeación, 3=Análisis, 4= Ejecución, 5=Evaluación. |
-- +-----------------+-----------------------------+-----------------------------------------------+---------------------------------------------------------+
-- | id_competencia  | DECIMAL(8,0)      | PRIMARY KEY                                  | Número identificador de la competencia.                            |
-- |                 |                   | FOREIGN KEY                                  |                                                                    |
-- |                 |                   | NOT NULL                                     |                                                                    |
-- +-----------------+-----------------------------+-----------------------------------------------+---------------------------------------------------------+
-- | id_instructor   | DECIMAL(10,0)     | PRIMARY KEY                                  | Identificador del instructor.                                      |
-- |                 |                   | FOREIGN KEY                                  |                                                                    |
-- |                 |                   | NOT NULL                                     |                                                                    |
-- +-----------------+-----------------------------+-----------------------------------------------+---------------------------------------------------------+
-- | ind_jornada     | DECIMAL(1,0)      | NOT NULL                                     | Jornada asignada.                                                  |
-- |                 |                   | CHECK(ind_jornada >= 1 AND ind_jornada <= 3) | 1=Mañana, 2=Tarde, 3=Noche.                                        |
-- +-----------------+-----------------------------+-----------------------------------------------+---------------------------------------------------------+
-- | fec_inicial     | DATE              | NOT NULL                                     | Fecha inicial de la programación.                                  |
-- +-----------------+-----------------------------+-----------------------------------------------+---------------------------------------------------------+
-- | fec_final       | DATE              | NOT NULL                                     | Fecha final de la programación.                                    |
-- +-----------------+-----------------------------+-----------------------------------------------+---------------------------------------------------------+
-- | usr_insert      | VARCHAR(50)       | NOT NULL                                     | Usuario que creó el registro.                                      |
-- |                 |                   | CHECK(LENGTH(TRIM(usr_insert)) >= 3)         |                                                                    |
-- +-----------------+-----------------------------+-----------------------------------------------+---------------------------------------------------------+
-- | fec_insert      | TIMESTAMP         | NOT NULL                                     | Fecha/hora de creación del registro.                               |
-- |                 | WITHOUT TIME ZONE |                                              |                                                                    |
-- +-----------------+-----------------------------+-----------------------------------------------+---------------------------------------------------------+
-- | usr_update      | VARCHAR(50)       | CHECK(LENGTH(TRIM(usr_update)) >= 3)         | Usuario que actualizó el registro.                                 |
-- +-----------------+-----------------------------+-----------------------------------------------+---------------------------------------------------------+
-- | fec_update      | TIMESTAMP         |                                              | Fecha/hora de actualización del registro.                          |
-- |                 | WITHOUT TIME ZONE |                                              |                                                                    |
-- +-----------------+-----------------------------+-----------------------------------------------+---------------------------------------------------------+

CREATE TABLE IF NOT EXISTS tab_programacion
(
    id_ruta                 DECIMAL(8,0)                NOT NULL,
    id_ficha                DECIMAL(10,0)               NOT NULL,
    id_fase                 DECIMAL(1,0)                NOT NULL, -- 1=Inducción, 2=Planeación, 3=Análisis, 4= Ejecución, 5=Evaluación
    id_competencia          DECIMAL(8,0)                NOT NULL,
    id_instructor           DECIMAL(10,0)               NOT NULL,
    ind_jornada             DECIMAL(1,0)                NOT NULL CHECK(ind_jornada >= 1 AND ind_jornada <= 3), -- 1=Mañana / 2=Tarde /3=Noche
    fec_inicial             DATE                        NOT NULL,
    fec_final               DATE                        NOT NULL,
    usr_insert              VARCHAR(50)                 NOT NULL CHECK(LENGTH(TRIM(usr_insert)) >= 3),
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR(50)                          CHECK(LENGTH(TRIM(usr_update)) >= 3),
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_ruta,id_ficha,id_competencia,id_instructor),
    FOREIGN KEY(id_ficha)                   REFERENCES tab_fichas(id_ficha),
    FOREIGN KEY(id_competencia)             REFERENCES tab_competencias(id_competencia),
    FOREIGN KEY(id_instructor)              REFERENCES tab_instructores(id_instructor)
);

-- Tabla de transacciones de una ruta, por competencia

-- TABLA DE TAB_PROG_COMPETENCIA
-- ________________________________________________________________________________________________________________________
-- |     Columna    |       Tipo        |            Restricción               |                Descripción                |
-- +----------------+-------------------+--------------------------------------+-------------------------------------------+
-- | id_ruta        | DECIMAL(8,0)      | PRIMARY KEY                          | Número identificador de la ruta.          |
-- |                |                   | FOREIGN KEY                          |                                           |
-- |                |                   | NOT NULL                             |                                           |
-- +----------------+-------------------+--------------------------------------+-------------------------------------------+
-- | id_ficha       | DECIMAL(10,0)     | PRIMARY KEY                          | Número identificador de la ficha.         |
-- |                |                   | FOREIGN KEY                          |                                           |
-- |                |                   | NOT NULL                             |                                           |
-- +----------------+-------------------+--------------------------------------+-------------------------------------------+
-- | id_fase        | DECIMAL(1,0)      | PRIMARY KEY                          | Número identificador de la fase.          |
-- |                |                   | FOREIGN KEY                          |                                           |
-- |                |                   | NOT NULL                             |                                           |
-- +----------------+-------------------+--------------------------------------+-------------------------------------------+
-- | id_competencia | DECIMAL(8,0)      | PRIMARY KEY                          | Número identificador de la competencia.   |
-- |                |                   | FOREIGN KEY                          |                                           |
-- |                |                   | NOT NULL                             |                                           |
-- +----------------+-------------------+--------------------------------------+-------------------------------------------+
-- | id_instructor  | DECIMAL(10,0)     | PRIMARY KEY                          | Número identificador del instructor.      |
-- |                |                   | FOREIGN KEY                          |                                           |
-- |                |                   | NOT NULL                             |                                           |
-- +----------------+-------------------+--------------------------------------+-------------------------------------------+
-- | id_actividad   | DECIMAL(10,0)     | PRIMARY KEY                          | Número identificador de la actividad.     |
-- |                |                   | FOREIGN KEY                          |                                           |
-- |                |                   | NOT NULL                             |                                           |
-- +----------------+-------------------+--------------------------------------+-------------------------------------------+
-- | id_rap         | DECIMAL(10,0)     | PRIMARY KEY                          | Número identificador del rap.             |
-- |                |                   | NOT NULL                             |                                           |
-- +----------------+-------------------+--------------------------------------+-------------------------------------------+
-- | val_dias       | DECIMAL(2,0)      | NOT NULL                             | Número de días.                           |
-- |                |                   | DEFAULT 6                            |                                           |
-- +----------------+-------------------+--------------------------------------+-------------------------------------------+
-- | fec_inicio     | DATE              | NOT NULL                             | Fecha/hora de inicio.                     |
-- +----------------+-------------------+--------------------------------------+-------------------------------------------+
-- | fec_final      | DATE              | NOT NULL                             | Fecha/hora de finalización.               |
-- +----------------+-------------------+--------------------------------------+-------------------------------------------+
-- | usr_insert     | VARCHAR(50)       | NOT NULL                             | Usuario que creó el registro.             |
-- |                |                   | CHECK(LENGTH(TRIM(usr_insert)) >= 3) |                                           |
-- +----------------+-------------------+--------------------------------------+-------------------------------------------+
-- | fec_insert     | TIMESTAMP         | NOT NULL                             | Fecha/hora de creación del registro.      |
-- |                | WITHOUT TIME ZONE |                                      |                                           |
-- +----------------+-------------------+--------------------------------------+-------------------------------------------+
-- | usr_update     | VARCHAR(50)       | CHECK(LENGTH(TRIM(usr_update)) >= 3) | Usuario que actualizó el registro.        |
-- +----------------+-------------------+----------------------------------------------------------------------------------+
-- | fec_update     | TIMESTAMP         |                                      | Fecha/hora de actualización del registro. |
-- |                | WITHOUT TIME ZONE |                                      |                                           |
-- +----------------+----------------+--------------------------------------+----------------------------------------------+

CREATE TABLE IF NOT EXISTS tab_prog_competencia
(
    id_ruta                 DECIMAL(8,0)                NOT NULL,
    id_ficha                DECIMAL(10,0)               NOT NULL,
    id_fase                 DECIMAL(1,0)                NOT NULL,
    id_competencia          DECIMAL(8,0)                NOT NULL,
    id_instructor           DECIMAL(10,0)               NOT NULL,
    id_actividad            DECIMAL(10,0)  	            NOT NULL,
    id_rap                  DECIMAL(10,0)               NOT NULL,
    val_dias                DECIMAL(2,0)                NOT NULL DEFAULT 6,
    fec_inicio              DATE                        NOT NULL,
    fec_final               DATE                        NOT NULL,
    usr_insert              VARCHAR(50)                 NOT NULL CHECK(LENGTH(TRIM(usr_insert)) >= 3),
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR(50)                          CHECK(LENGTH(TRIM(usr_update)) >= 3),
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_ruta,id_ficha,id_fase,id_competencia,id_instructor,id_actividad,id_rap),
    FOREIGN KEY(id_ruta)                REFERENCES tab_rutas(id_ruta),
    FOREIGN KEY(id_ficha)               REFERENCES tab_fichas(id_ficha),
    FOREIGN KEY(id_competencia)         REFERENCES tab_competencias(id_competencia),
    FOREIGN KEY(id_actividad)           REFERENCES tab_activ_proyecto(id_actividad),
    FOREIGN KEY(id_instructor)          REFERENCES tab_instructores(id_instructor)
);

-- ******************************************************************
-- * TRIGGERS Y STORED PROCEDURES PARA TRANSACCIONES Y AUDITORÍA    *
-- ******************************************************************
-- Tabla de registro de filas borradas

-- TABLA DE TAB_BORRADOS
-- _____________________________________________________________________________________________________________________
-- |   Columna    |       Tipo        |             Restricción              |              Descripción                 |
-- +--------------+-------------------+--------------------------------------+------------------------------------------+
-- | id_consec    | INTEGER           | PRIMARY KEY                          | Número consecutivo de la tabla borraods. |
-- |              |                   | NOT NULL                             |                                          |
-- +--------------+-------------------+--------------------------------------+------------------------------------------+
-- | nom_tabla    | VARCHAR           | NOT NULL                             | Nombre de la tabla borrada.              |
-- |              |                   | CHECK(LENGTH(nom_tabla) >= 5)        |                                          |
-- +--------------+-------------------+--------------------------------------+------------------------------------------+
-- | nom_registro | JSONB             | NOT NULL                             | Nombre del registro borrado.             |
-- +--------------+-------------------+--------------------------------------+------------------------------------------+
-- | usr_insert   | VARCHAR(50)       | NOT NULL                             | Usuario que creó/actualizó el registro.  |
-- |              |                   | CHECK(LENGTH(TRIM(usr_insert)) >= 3) |                                          |
-- +--------------+-------------------+--------------------------------------+------------------------------------------+
-- | fec_insert   | TIMESTAMP         | NOT NULL                             | Fecha/hora de creación del registro.     |
-- |              | WITHOUT TIME ZONE |                                      |                                          |
-- +--------------+-------------------+--------------------------------------+------------------------------------------+

CREATE TABLE IF NOT EXISTS tab_borrados
(
    id_consec               INTEGER                     NOT NULL,
    nom_tabla               VARCHAR                     NOT NULL CHECK(LENGTH(nom_tabla) >= 5),
    nom_registro            JSONB                       NOT NULL,
    usr_insert              VARCHAR(50)                 NOT NULL CHECK(LENGTH(TRIM(usr_insert)) >= 3),
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    PRIMARY KEY(id_consec)
);

-- TABLA DE BITÁCORA DIARIA
-- Se usa para que los encargados diligencien los eventos que consideren importantes en el día
-- Similar al libro de la vigilancia
CREATE TABLE IF NOT EXISTS tab_bitacora
(
    id_consecutivo          BIGSERIAL                   NOT NULL,
    fec_bitacora            DATETIME                    NOT NULL,
    texto_evento            TEXT                        NOT NULL,
    nom_encargado           VARCHAR                     NOT NULL,
    usr_insert              VARCHAR(50)                 NOT NULL CHECK(LENGTH(TRIM(usr_insert)) >= 3),
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    PRIMARY KEY(id_consecutivo)
);