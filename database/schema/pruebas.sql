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