-- *******************************************************************************************
-- * SERVICIO NACIONAL DE APRENDIZAJE - SENA                                                 *
-- * SISTEMA INTEGRADO PARA LA GESTIÓN DE PLATAFORMA TECNOLÓGICA CSET                        *
-- * SCRIPT DE INSTALACIÓN DEL SISTEMA. INCLUYE LA CREACIÓN DE ESTRUCTURAS Y LAS INSERCIONES *
-- * CORRESPONDIENTES A LOS DATOS BÁSICOS PARA CARGA DE TABLAS MAESTRAS                      *
-- * Autores: CARLOS EDUARDO PEREZ RUEDA                                                     *
-- * Fecha: Abril de 2026                                                                    *
-- * Versión: 1.1                                                                            *
-- * Revisión: Mayo de 2026                                                                 *
-- * Derechos Reservados de los Autores.                                                     *
-- * Cualquier modificación, comercialización y/o uso sin la autorización de los autores se  *
-- * considerará DELITO, de acuerdo con las leyes vigentes para el caso en COLOMBIA          * 
-- *******************************************************************************************

DROP TABLE IF EXISTS tab_borrados;
DROP TABLE IF EXISTS tab_prog_competencia;
DROP TABLE IF EXISTS tab_programacion;
DROP TABLE IF EXISTS tab_rutas;
DROP TABLE IF EXISTS tab_competencias_ficha;
DROP TABLE IF EXISTS tab_ofertas;
DROP TABLE IF EXISTS tab_llamados_atencion;
DROP TABLE IF EXISTS tab_ausencias_aprendiz;
DROP TABLE IF EXISTS tab_aprendices_fichas;
DROP TABLE IF EXISTS tab_aprendices;
DROP TABLE IF EXISTS tab_fichas;
DROP TABLE IF EXISTS tab_prog_especiales;
DROP TABLE IF EXISTS tab_ocupaciones;
DROP TABLE IF EXISTS tab_sectores;
DROP TABLE IF EXISTS tab_ambientes;
DROP TYPE IF EXISTS inv_ambiente;
DROP TABLE IF EXISTS tab_proyectos;
DROP TYPE IF EXISTS valoracion_productiva;
DROP TYPE IF EXISTS innovacion_proyectos;
DROP TABLE IF EXISTS tab_log_ingresos;
DROP TABLE IF EXISTS tab_vehiculos;
DROP TABLE IF EXISTS tab_metodos_aut;
DROP TABLE IF EXISTS tab_juicios_eval;
DROP TABLE IF EXISTS tab_evidenciasXrap;
DROP TABLE IF EXISTS tab_evidencias;
DROP TABLE IF EXISTS tab_raps;
DROP TABLE IF EXISTS tab_activ_proyecto;
DROP TABLE IF EXISTS tab_compet_instructor;
DROP TABLE IF EXISTS tab_competencias;
DROP TABLE IF EXISTS tab_programas;
DROP TABLE IF EXISTS tab_certificados;
DROP TABLE IF EXISTS tab_horas_instructor;
DROP TABLE IF EXISTS tab_adicion_contratos;
DROP TABLE IF EXISTS tab_contratos_instructor;
DROP TABLE IF EXISTS tab_instructores;
DROP TYPE IF EXISTS datos_personales_aprendiz;
DROP TABLE IF EXISTS tab_funcionarios;
DROP TABLE IF EXISTS tab_personas;
DROP TABLE IF EXISTS tab_tipos_persona;
DROP TABLE IF EXISTS tab_niveles_estudio;
DROP TABLE IF EXISTS tab_profesiones;
DROP TABLE IF EXISTS tab_empresas;
DROP TABLE IF EXISTS tab_tipos_docum;
DROP TABLE IF EXISTS tab_pmtros_grales;
DROP TABLE IF EXISTS tab_redes;
DROP TABLE IF EXISTS tab_entradas_centro;
DROP TABLE IF EXISTS tab_areas;
DROP TABLE IF EXISTS tab_cargos;
DROP TABLE IF EXISTS tab_sedes;
DROP TABLE IF EXISTS tab_centros;
DROP TABLE IF EXISTS tab_regionales;
DROP TABLE IF EXISTS tab_ciudades;
DROP TABLE IF EXISTS tab_dptos;
DROP TABLE IF EXISTS tab_menu_usuarios;
DROP TABLE IF EXISTS tab_menus;
DROP TABLE IF EXISTS tab_sesiones;
DROP TABLE IF EXISTS tab_config_sistema;
DROP TABLE IF EXISTS tab_usuarios;
DROP DOMAIN IF EXISTS mail_personal;
DROP TABLE IF EXISTS tab_temp_pe04;
DROP TABLE IF EXISTS tab_temp_ofertas;
DROP TABLE IF EXISTS tab_temp_inscritos;
DROP TABLE IF EXISTS tab_temp_matriculados;
DROP TABLE IF EXISTS tab_temp_egresados;
DROP TABLE IF EXISTS tab_temp_df49;
DROP TABLE IF EXISTS tab_temp_df14A;
DROP TABLE IF EXISTS tab_temp_df53;
DROP TABLE IF EXISTS tab_temp_df51;
DROP TABLE IF EXISTS tab_temp_df03;
DROP TABLE IF EXISTS tab_temp_df14;
DROP TABLE IF EXISTS tab_temp_juicios;

--**********************************************************
-- 0-TABLAS TEMPORALES PARA EL PARSING DE ARCHIVOS EN EXCEL
-- *********************************************************
CREATE TABLE IF NOT EXISTS tab_temp_juicios
(
  fecha_reporte     DATE,
  id_ficha          DECIMAL(10,0),
  id_programa       DECIMAL(8,0),
  id_version        DECIMAL(2,0),
  nom_ficha         VARCHAR,
  ind_estado        VARCHAR,
  fec_inicio        DATE,
  fec_fin           DATE,
  id_modalidad      VARCHAR,
  nom_regional      VARCHAR,
  nom_centro        VARCHAR,
-- Hasta acá el encabezado
  id_tipodoc        VARCHAR,
  num_docume        DECIMAL(10,0),
  nom_aprendiz      VARCHAR,
  ape_aprendiz      VARCHAR,
  ind_est_aprendiz  VARCHAR,
  nom_competencia   TEXT,
  nom_rap           TEXT,
  val_juicio        VARCHAR,
  fec_juicio        VARCHAR,
  nom_instructor    VARCHAR
);

CREATE TABLE IF NOT EXISTS tab_temp_df49
(
  fecha_reporte     DATE,
  cod_regional      DECIMAL(2,0),
  nom_regional      VARCHAR,
  cod_centro        DECIMAL(4,0),
  nom_centro        VARCHAR,
  id_ficha          DECIMAL(7,0),
  fec_inicial       DATE,
  fec_final         DATE,
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

CREATE TABLE IF NOT EXISTS tab_temp_pe04
(
  fecha_reporte     DATE,
  cod_regional      DECIMAL(2,0),
  nom_regional      VARCHAR,
  cod_centro        DECIMAL(4,0),
  nom_centro        VARCHAR,
  id_ficha          DECIMAL(7,0),
  id_unico_ficha    DECIMAL(8,0),
  ind_estado_curso  VARCHAR,
  id_nivel_forma    DECIMAL(2,0),
  nom_nivel_forma   VARCHAR,
  id_jornada        DECIMAL(1,0),
  nom_jornada       VARCHAR,
  ind_tipo_forma    VARCHAR,
  fec_inicio_ficha  DATE,
  fec_fin_ficha     DATE,
  val_etapa_ficha   VARCHAR,
  val_modalidad     VARCHAR,
  nom_responsable   VARCHAR,
  id_empresa        DECIMAL(10,0),
  id_tipodoc_emp    VARCHAR,
  nom_empresa       VARCHAR,
  id_sector_prog    DECIMAL(1,0),
  nom_sector_prog   VARCHAR,
  id_ocupacion      DECIMAL(4,0),
  nom_ocupacion     VARCHAR,
  id_programa       DECIMAL(8,0),
  id_version        SMALLINT,
  nom_programa      VARCHAR,
  id_pais           DECIMAL(2,0),
  nom_pais          VARCHAR,
  id_depto          DECIMAL(2,0),
  nom_depto         VARCHAR,
  id_municipio      DECIMAL(5,0),
  nom_municipio     VARCHAR,
  id_convenio       DECIMAL(1,0),
  nom_convenio      VARCHAR,
  ind_cobertura     VARCHAR,
  id_prog_especial  DECIMAL(6,0),
  nom_prog_especial VARCHAR,
  num_cursos        DECIMAL(2,0),
  num_aprend_masc   DECIMAL(3,0),
  num_aprend_fem    DECIMAL(3,0),
  num_aprend_nobin  DECIMAL(3,0),
  num_tot_aprend    DECIMAL(4,0),
  val_hrs_planta    INTERVAL,
  val_hrs_contrat   INTERVAL,
  val_hrs_context   INTERVAL,
  val_hrs_monitor   INTERVAL,
  val_hrs_instemp   INTERVAL,
  val_total_hrs     INTERVAL,
  val_total_apr_act DECIMAL(4,0),
  val_duracion_prog DECIMAL(4,0),
  nom_nuevo_sector  VARCHAR DEFAULT 'NA'
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
  dur_maxima        DECIMAL(2,0),
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

CREATE TABLE IF NOT EXISTS tab_temp_df51
(
  fecha_reporte             DATE,
  cod_regional              DECIMAL(2,0),
  nom_regional              VARCHAR,
  cod_centro                DECIMAL(4,0),
  nom_centro                VARCHAR,
  id_ficha                  DECIMAL(8,0),
  id_version_programa       SMALLINT,
  tipo_formacion            VARCHAR,
  tipo_respuesta            VARCHAR,
  fecha_inicial             DATE,
  fecha_final               DATE,
  estado_ficha              VARCHAR,
  num_cupo                  SMALLINT,
  aprendices_activos        SMALLINT,
  activos_con_ruta          SMALLINT,
  activos_sin_ruta          SMALLINT, 
  apren_con_ruta_y_noved    SMALLINT,
  apren_sin_ruta_con_noved  SMALLINT
 );

CREATE TABLE IF NOT EXISTS tab_temp_df53
(
  fecha_reporte             DATE,
  cod_regional              DECIMAL(2,0),
  nom_regional              VARCHAR,
  cod_centro                DECIMAL(4,0),
  nom_centro                VARCHAR,
  id_ficha                  DECIMAL(8,0),
  nombre_programa           VARCHAR,
  id_version_programa       SMALLINT,
  tipo_formacion            VARCHAR,
  tipo_respuesta            VARCHAR,
  fecha_inicial             DATE,
  fecha_final               DATE,
  estado_ficha              VARCHAR,
  aprendices_activos        DECIMAL(2,0),
  programada                VARCHAR,
  cod_programa_especial     DECIMAL(4,0),
  nom_programa_especial     VARCHAR,
  cod_convenio              VARCHAR,
  ampliacion_cobertura      VARCHAR,
  nom_convenio              VARCHAR,
  tipo_docum_empresa        VARCHAR,
  num_docum_empresa         DECIMAL(10,0),
  nombre_empresa            VARCHAR,
  tipo_ficha                VARCHAR
 );

 CREATE TABLE IF NOT EXISTS tab_temp_aprendices (
    id_ficha                VARCHAR,
    nom_ficha               VARCHAR,
    ind_estado_ficha        VARCHAR,
    fecha_reporte           DATE,
    id_tipodoc              VARCHAR,
    num_documento           VARCHAR,
    nom_aprendiz            VARCHAR,
    ape_aprendiz            VARCHAR,
    nom_movil               VARCHAR,
    val_correo              VARCHAR,
    ind_estado_aprendiz     VARCHAR
 );


--***********************************************************************
-- FIN SECCIÓN DE TABLAS TEMPORALES PARA EL PARSING DE ARCHIVOS EN EXCEL
-- **********************************************************************

CREATE DOMAIN mail_personal AS VARCHAR(255) CHECK (VALUE ~* '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$');
CREATE DOMAIN mail_institucional AS VARCHAR(255) CHECK (VALUE ~* '^[a-z0-9._%-]+@[a-z0-9.-]+\.[a-z]{2,}$');
CREATE DOMAIN nombre_geografico AS VARCHAR(50) CHECK (LENGTH(VALUE) >= 3 AND VALUE ~ '^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ .-]+$');
CREATE DOMAIN telefono_fijo AS DECIMAL(10,0) CHECK (VALUE BETWEEN 6010000000 AND 6089999999);
CREATE DOMAIN telefono_movil AS DECIMAL(10,0) CHECK (VALUE BETWEEN 3000000000 AND 3519999999);
CREATE DOMAIN extension AS DECIMAL(8,0) CHECK (VALUE >= 0);

-- ***************************************************************************
-- 1. TABLAS DE SEGURIDAD Y ACCESOS AL SISTEMA DE GESTIÓN DE USUARIOS Y MENÚS
-- ***************************************************************************

-- TABLA DE USUARIOS
--  __________________________________________________________________________________________________________________________
-- |    Columna   |        Tipo       |            Restricción                |                  Descripción                  |
-- +--------------+-------------------+---------------------------------------+-----------------------------------------------+
-- | id_usuario   | VARCHAR(20)       | PRIMARY KEY                           | Número identificador del usuario.             |
-- |              |                   | NOT NULL                              |                                               |
-- |              |                   | CHECK (LENGTH(TRIM(usr_insert)) >= 3) |                                               |
-- +--------------+-------------------+---------------------------------------+-----------------------------------------------+
-- | nom_usuario  | VARCHAR(50)       | NOT NULL                              | Nombre de usuario para login.                 |
-- |              |                   | CHECK (LENGTH(TRIM(nom_usuario)) >= 3)|                                               |
-- +--------------+-------------------+---------------------------------------+-----------------------------------------------+
-- | pass_usuario | VARCHAR           | NOT NULL                              | Contraseña hasheada del usuario.              |
-- |              |                   | CHECK(LENGTH(pass_usuario) >= 60)     |                                               |
-- +--------------+-------------------+---------------------------------------+-----------------------------------------------+
-- | mail_usuario | mail_personal     | NOT NULL                              | Correo personal válido.                       |
-- +--------------+-------------------+---------------------------------------+-----------------------------------------------+
-- | ind_usuario  | BOOLEAN           | NOT NULL                              | TRUE = administrador, FALSE = usuario normal. |
-- |              |                   | DEFAULT FALSE                         | Indicador de rol.                             |
-- +--------------+-------------------+---------------------------------------+-----------------------------------------------+
-- | ind_estado   | BOOLEAN           | NOT NULL                              | TRUE = activo, FALSE = inactivo.              |
-- |              |                   | DEFAULT TRUE                          | Indicador de estado.                          |
-- +--------------+-------------------+---------------------------------------+-----------------------------------------------+
-- | usr_insert   | VARCHAR(50)       | NOT NULL                              | Usuario que creó el registro.                 |
-- |              |                   | CHECK (LENGTH(TRIM(usr_insert)) >= 3) |                                               |
-- +--------------+-------------------+---------------------------------------+-----------------------------------------------+
-- | fec_insert   | TIMESTAMP         | NOT NULL                              | Fecha/hora de creación del registro.          |
-- +--------------+-------------------+---------------------------------------+-----------------------------------------------+
-- | usr_update   | VARCHAR(50)       | CHECK (LENGTH(TRIM(usr_update)) >= 3) | Usuario que actualizó el registro.            |
-- |              |                   |                                       |                                               |
-- +--------------+-------------------+---------------------------------------+-----------------------------------------------+
-- | fec_update   | TIMESTAMP         |                                       | Fecha/hora de última actualización.           |
-- |              | WITHOUT TIME ZONE |                                       |                                               |
-- +--------------+-------------------+---------------------------------------+-----------------------------------------------+

CREATE TABLE IF NOT EXISTS tab_usuarios
(
    id_usuario              VARCHAR(20)                     NOT NULL CHECK(LENGTH(id_usuario) >= 3),
    nom_usuario             VARCHAR(50)                     NOT NULL CHECK(LENGTH(TRIM(nom_usuario)) >= 3),
    pass_usuario            VARCHAR                         NOT NULL CHECK(LENGTH(pass_usuario) >= 60),
    mail_usuario            mail_personal                   NOT NULL,
    ind_usuario             BOOLEAN                         NOT NULL DEFAULT FALSE,
    ind_estado              BOOLEAN                         NOT NULL DEFAULT TRUE,
    usr_insert              VARCHAR(50)                     NOT NULL CHECK(LENGTH(TRIM(usr_insert)) >= 3),
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR(50)                              CHECK(LENGTH(TRIM(usr_update)) >= 3),
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_usuario)
);

-- TABLA DE SESIONES DE APLICACIÓN (módulo acceso / login)
CREATE TABLE IF NOT EXISTS tab_sesiones
(
    id_usuario      VARCHAR(20)                 NOT NULL PRIMARY KEY,
    fec_inicio      TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ult_actividad   TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_usuario) REFERENCES tab_usuarios (id_usuario)
);

-- TABLA DE MENÚS
--  _________________________________________________________________________________________________________________
-- |   Columna    |       Tipo        |              Restricción              |              Descripción             |
-- +--------------+-------------------+---------------------------------------+--------------------------------------+
-- | id_menu      | VARCHAR(20)       | PRIMARY KEY                           | Número identificador del menú.       |
-- |              |                   | NOT NULL                              |                                      |
-- |              |                   | CHECK(LENGTH(nom_menu) >= 2)          |                                      |
-- +--------------+-------------------+---------------------------------------+--------------------------------------+
-- | nom_menu     | VARCHAR(25)       | NOT NULL                              | Nombre del menú.                     |
-- |              |                   | CHECK(LENGTH(nom_menu) >= 3)          |                                      |
-- +--------------+-------------------+---------------------------------------+--------------------------------------+
-- | ind_id_padre | VARCHAR(20)       | NOT NULL                              | Número identificador del menú padre. |
-- |              |                   | CHECK(LENGTH(ind_id_padre) >= 2)      |                                      |
-- +--------------+-------------------+---------------------------------------+--------------------------------------+
-- | nom_programa | VARCHAR(255)      | NOT NULL                              | Ruta PHP del programa (desde raíz).  |
-- |              |                   | DEFAULT 'no_aplica'                   |                                      |
-- +--------------+-------------------+---------------------------------------+--------------------------------------+
-- | usr_insert   | VARCHAR(50)       | NOT NULL                              | Usuario que creó el registro.        |
-- |              |                   | CHECK (LENGTH(TRIM(usr_insert)) >= 3) |                                      |
-- +--------------+-------------------+---------------------------------------+--------------------------------------+
-- | fec_insert   | TIMESTAMP         | NOT NULL                              | Fecha/hora de creación del registro. |
-- |              | WITHOUT TIME ZONE |                                       |                                      |
-- +--------------+-------------------+---------------------------------------+--------------------------------------+
-- | usr_update   | VARCHAR(50)       | CHECK (LENGTH(TRIM(usr_update)) >= 3) | Usuario que actualizó el registro.   |
-- |              |                   |                                       |                                      |
-- +--------------+-------------------+---------------------------------------+--------------------------------------+
-- | fec_update   | TIMESTAMP         |                                       | Fecha/hora de última actualización.  |
-- |              | WITHOUT TIME ZONE |                                       |                                      |
-- +--------------+-------------------+---------------------------------------+--------------------------------------+

CREATE TABLE IF NOT EXISTS tab_menus
(
    id_menu              VARCHAR(20)                     NOT NULL CHECK(LENGTH(id_menu) >= 2),
    nom_menu             VARCHAR(25)                     NOT NULL CHECK(LENGTH(nom_menu) >= 3),
    ind_id_padre         VARCHAR(20)                     NOT NULL CHECK(LENGTH(ind_id_padre) >= 2),
    nom_programa         VARCHAR(255)                    NOT NULL DEFAULT 'no_aplica',
    usr_insert           VARCHAR(50)                     NOT NULL CHECK(LENGTH(TRIM(usr_insert)) >= 3),
    fec_insert           TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update           VARCHAR(50)                              CHECK(LENGTH(TRIM(usr_update)) >= 3),
    fec_update           TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_menu)
);

-- TABLA DE MENÚS DE USUARIOS
-- _______________________________________________________________________________________________________________
-- |  Columna   |       Tipo        |              Restricción             |              Descripción             |
-- +------------+-------------------+--------------------------------------+--------------------------------------+
-- | id_usuario | VARCHAR(20)       | PRIMARY KEY                          | Número identificador del usuario.    |
-- |            |                   | FOREIGN KEY                          |                                      |
-- |            |                   | NOT NULL                             |                                      |
-- |            |                   | CHECK(LENGTH(id_usuario) >= 5)       |                                      |
-- +------------+-------------------+--------------------------------------+--------------------------------------+
-- | id_menu    | VARCHAR(20)       | PRIMARY KEY                          | Número identificador del menú.       |
-- |            |                   | FOREIGN KEY                          |                                      |
-- |            |                   | NOT NULL                             |                                      |
-- |            |                   | CHECK(LENGTH(id_menu) >= 2)          |                                      |
-- +------------+-------------------+--------------------------------------+--------------------------------------+
-- | usr_insert | VARCHAR(50)       | NOT NULL                             | Usuario que creó el registro.        |
-- |            |                   | CHECK(LENGTH(TRIM(usr_insert)) >= 3) |                                      |
-- +------------+-------------------+--------------------------------------+--------------------------------------+
-- | fec_insert | TIMESTAMP         | NOT NULL                             | Fecha/hora de creación del registro. |
-- |            | WITHOUT TIME ZONE |                                      |                                      |
-- +------------+-------------------+--------------------------------------+--------------------------------------+
-- | usr_update | VARCHAR(50)       | CHECK(LENGTH(TRIM(usr_update)) >= 3) | Usuario que actualizó el registro.   |
-- +------------+-------------------+--------------------------------------+--------------------------------------+
-- | fec_update | TIMESTAMP         |                                      | Fecha/hora de última actualización.  |
-- |            | WITHOUT TIME ZONE |                                      |                                      |
-- +------------+-------------------+--------------------------------------+--------------------------------------+

CREATE TABLE IF NOT EXISTS tab_menu_usuarios
(
    id_usuario                  VARCHAR(20)                 NOT NULL CHECK(LENGTH(id_usuario) >= 5),
    id_menu                     VARCHAR(20)                 NOT NULL CHECK(LENGTH(id_menu) >= 2),
    usr_insert                  VARCHAR(50)                 NOT NULL CHECK(LENGTH(TRIM(usr_insert)) >= 3),
    fec_insert                  TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update                  VARCHAR(50)                          CHECK(LENGTH(TRIM(usr_update)) >= 3),
    fec_update                  TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_usuario,id_menu),
    FOREIGN KEY(id_usuario) REFERENCES tab_usuarios(id_usuario),
    FOREIGN KEY(id_menu)    REFERENCES tab_menus(id_menu)
);

-- TABLA DE CONFIGURACIÓN DEL SISTEMA (colores, logo, tema, módulo registro)
-- Una fila por instalación (id_config = 1). Ver database/migrations/add_tab_config_sistema.sql
CREATE TABLE IF NOT EXISTS tab_config_sistema
(
    id_config                     SMALLINT PRIMARY KEY DEFAULT 1 CHECK (id_config = 1),
    ind_modulo_registro           BOOLEAN NOT NULL DEFAULT TRUE,
    ind_login_registro_standalone BOOLEAN NOT NULL DEFAULT FALSE,
    nom_sistema                   VARCHAR(80) NOT NULL DEFAULT 'SmartCSET',
    path_logo                     VARCHAR(255) NOT NULL DEFAULT 'public/uploads/logos/logo.png',
    color_primario                VARCHAR(7) NOT NULL DEFAULT '#2E4731',
    color_secundario              VARCHAR(7) NOT NULL DEFAULT '#6B8E23',
    theme_bg_deep                 VARCHAR(32) NOT NULL DEFAULT '#020917',
    theme_bg_card                 VARCHAR(32) NOT NULL DEFAULT '#060f24',
    theme_bg_panel                VARCHAR(64) NOT NULL DEFAULT 'rgba(6, 15, 36, 0.85)',
    theme_accent                  VARCHAR(32) NOT NULL DEFAULT '#00e5b0',
    theme_accent_dim              VARCHAR(64) NOT NULL DEFAULT 'rgba(0, 245, 255, 0.15)',
    theme_blue                    VARCHAR(32) NOT NULL DEFAULT '#4a9eff',
    theme_purple                  VARCHAR(32) NOT NULL DEFAULT '#9b6dff',
    theme_orange                  VARCHAR(32) NOT NULL DEFAULT '#ff7b2e',
    theme_text_primary            VARCHAR(32) NOT NULL DEFAULT '#e8f4ff',
    theme_text_muted              VARCHAR(128) NOT NULL DEFAULT 'rgba(150,180,220,0.7)',
    theme_border                  VARCHAR(64) NOT NULL DEFAULT 'rgba(0,245,255,0.2)',
    theme_error                   VARCHAR(32) NOT NULL DEFAULT '#ff3c6e',
    theme_success                 VARCHAR(32) NOT NULL DEFAULT '#00e5b0',
    theme_font_display            VARCHAR(120) NOT NULL DEFAULT 'Orbitron',
    theme_font_body               VARCHAR(120) NOT NULL DEFAULT 'Rajdhani',
    theme_light_bg_deep           VARCHAR(32) NOT NULL DEFAULT '#f5f7fb',
    theme_light_bg_card           VARCHAR(32) NOT NULL DEFAULT '#ffffff',
    theme_light_accent            VARCHAR(32) NOT NULL DEFAULT '#0b74c7',
    theme_light_text_primary      VARCHAR(32) NOT NULL DEFAULT '#111827',
    theme_light_text_muted        VARCHAR(128) NOT NULL DEFAULT 'rgba(55,65,81,0.8)',
    usr_registro                  VARCHAR(40),
    pass_registro_hash            VARCHAR(255),
    usr_insert                    VARCHAR(50) NOT NULL DEFAULT 'migration',
    fec_insert                    TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
    usr_update                    VARCHAR(50),
    fec_update                    TIMESTAMP WITHOUT TIME ZONE
);

-- **************************
-- 2. TABLAS INSTITUCIONALES
-- **************************
-- TABLA DE DEPARTAMENTOS DE COLOMBIA SEGÚN DANE

-- TABLA DE TAB_DPTOS
-- ____________________________________________________________________________________________________________________
-- |  Columna   |            Tipo   |              Restricción             |                Descripción                |
-- +------------+-------------------+--------------------------------------+-------------------------------------------+
-- | id_dpto    | VARCHAR(2)        | PRIMARY KEY                          | Número identificador del departamento.    |
-- |            |                   | NOT NULL                             |                                           |
-- +------------+-------------------+--------------------------------------+-------------------------------------------+
-- | nom_dpto   | nombre_geografico | NOT NULL                             | Nombre del departamento.                  |
-- +------------+-------------------+--------------------------------------+-------------------------------------------+
-- | usr_insert | VARCHAR(50)       | NOT NULL                             | Usuario que creó el registro.             |
-- |            |                   | CHECK(LENGTH(TRIM(usr_insert)) >= 3) |                                           |
-- +------------+-------------------+--------------------------------------+-------------------------------------------+
-- | fec_insert | TIMESTAMP WITHOUT | NOT NULL                             | Fecha/hora de creación del registro.      |
-- |            | WITHOUT TIME ZONE |                                      |                                           |
-- +------------+-------------------+--------------------------------------+-------------------------------------------+
-- | usr_update | VARCHAR(50)       | CHECK(LENGTH(TRIM(usr_update)) >= 3) | Usuario que actualizó el registro.        |
-- +------------+-------------------+--------------------------------------+-------------------------------------------+
-- | fec_update | TIMESTAMP WITHOUT |                                      | Fecha/hora de actualización del registro. |
-- |            | WITHOUT TIME ZONE |                                      |                                           |
-- +------------+-------------------+--------------------------------------+-------------------------------------------+

CREATE TABLE IF NOT EXISTS tab_dptos
(
    id_dpto                     VARCHAR(2)                  NOT NULL,
    nom_dpto                    nombre_geografico           NOT NULL,
    usr_insert                  VARCHAR(50)                 NOT NULL CHECK(LENGTH(TRIM(usr_insert)) >= 3),
    fec_insert                  TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update                  VARCHAR(50)                          CHECK(LENGTH(TRIM(usr_update)) >= 3),
    fec_update                  TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_dpto)
);

-- TABLA DE CIUDADES CON DEPATARMENTO SEGÚN DANE

-- TABLA DE TAB_CIUDADES
-- _____________________________________________________________________________________________________________________
-- |   Columna   |       Tipo        |              Restricción             |                Descripción                |
-- +-------------+-------------------+--------------------------------------+-------------------------------------------+
-- | id_ciudad   | VARCHAR(5)        | PRIMARI KEY                          | Número identificador de la ciudad.        |
-- |             |                   | NOT NULL                             |                                           |
-- +-------------+-------------------+--------------------------------------+-------------------------------------------+
-- | nom_ciudad  | nombre_geografico | NOT NULL                             | Nombre de la ciudad.                      |
-- +-------------+-------------------+--------------------------------------+-------------------------------------------+
-- | id_dpto     | VARCHAR(2)        | FOREING KEY                          | Número identificador del depatamento.     |
-- |             |                   | NOT NULL                             |                                           |
-- +-------------+-------------------+--------------------------------------+-------------------------------------------+
-- | ind_capital | BOOLEAN           | NOT NULL                             | TRUE = Es capital, FALSE = No es capital. |
-- |             |                   | DEFAULT FALSE                        | Indicador para la ciudad si es capital.   |
-- +-------------+-------------------+--------------------------------------+-------------------------------------------+
-- | usr_insert  | VARCHAR(50)       | NOT NULL                             | Usuario que creó el registro.             |
-- |             |                   | CHECK(LENGTH(TRIM(usr_insert)) >= 3) |                                           |
-- +-------------+-------------------+--------------------------------------+-------------------------------------------+
-- | fec_insert  | TIMESTAMP         | NOT NULL                             | Fecha/hora de creación del registro.      |
-- |             | WITHOUT TIME ZONE |                                      |                                           |
-- +-------------+-------------------+--------------------------------------+-------------------------------------------+
-- | usr_update  | VARCHAR(50)       | CHECK(LENGTH(TRIM(usr_update)) >= 3) | Usuario que actualizó el registro.        |
-- +-------------+-------------------+--------------------------------------+-------------------------------------------+
-- | fec_update  | TIMESTAMP         |                                      | Fecha/hora de actualización del registro. |
-- |             | WITHOUT TIME ZONE |                                      |                                           |
-- +-------------+-------------------+--------------------------------------+-------------------------------------------+

CREATE TABLE IF NOT EXISTS tab_ciudades
(
    id_ciudad                   VARCHAR(5)                  NOT NULL,
    nom_ciudad                  nombre_geografico           NOT NULL,
    id_dpto                     VARCHAR(2)                  NOT NULL,
    ind_capital                 BOOLEAN                     NOT NULL DEFAULT FALSE,
    usr_insert                  VARCHAR(50)                 NOT NULL CHECK(LENGTH(TRIM(usr_insert)) >= 3),
    fec_insert                  TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update                  VARCHAR(50)                          CHECK(LENGTH(TRIM(usr_update)) >= 3),
    fec_update                  TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_ciudad),
    FOREIGN KEY(id_dpto) REFERENCES tab_dptos(id_dpto)
);

-- TABLA DE REGIONALES DEL SENA

-- TABLA DE TAB_REGIONALES
-- ______________________________________________________________________________________________________________________________________
-- |      Columna      |       Tipo        |                 Restricción              |                   Descripción                    |
-- +-------------------+-------------------+------------------------------------------+--------------------------------------------------+
-- | id_regional       | VARCHAR(2)        | PRIMARY KEY                              | Número identificador de la regional.             |
-- |                   |                   | NOT NULL                                 |                                                  |
-- +-------------------+-------------------+------------------------------------------+--------------------------------------------------+
-- | nom_regional      | VARCHAR(50)       | NOT NULL                                 | Nombre de la regional.                           |
-- |                   |                   | CHECK (LENGTH(TRIM(nom_regional)) >= 10) |                                                  |
-- +-------------------+-------------------+------------------------------------------+--------------------------------------------------+
-- | dir_regional      | VARCHAR(100)      | NOT NULL                                 | Dirección de la regional.                        |
-- |                   |                   | CHECK (LENGTH(TRIM(dir_regional)) >= 10) |                                                  |
-- +-------------------+-------------------+------------------------------------------+--------------------------------------------------+
-- | id_dpto           | VARCHAR(2)        | FOREING KEY                              | Número identificador del departamento.           |
-- |                   |                   | NOT NULL                                 |                                                  |
-- +-------------------+-------------------+------------------------------------------+--------------------------------------------------+
-- | tel_regional      | telefono_fijo     | NOT NULL                                 | Número de teléfono de la regional.               |
-- +-------------------+-------------------+------------------------------------------+--------------------------------------------------+
-- | num_extension_tel | extension         | NOT NULL                                 | Número de extensión del teléfono de la regional. |
-- +-------------------+-------------------+------------------------------------------+--------------------------------------------------+
-- | nom_director      | VARCHAR(80)       | NOT NULL                                 | Nombre del director de la regional.              |
-- |                   |                   | CHECK (LENGTH(TRIM(nom_director)) >= 3)  |                                                  |
-- +-------------------+-------------------+------------------------------------------+--------------------------------------------------+
-- | usr_insert        | VARCHAR(50)       | NOT NULL                                 | Usuario que creó el registro.                    |
-- |                   |                   | CHECK (LENGTH(TRIM(usr_insert)) >= 3)    |                                                  |
-- +-------------------+-------------------+------------------------------------------+--------------------------------------------------+
-- | fec_insert        | TIMESTAMP         | NOT NULL                                 | Fecha/hora de creación del registro.             |
-- |                   | WITHOUT TIME ZONE |                                          |                                                  |
-- +-------------------+-------------------+------------------------------------------+--------------------------------------------------+
-- | usr_update        | VARCHAR(50)       | CHECK (LENGTH(TRIM(usr_update)) >= 3)    | Usuario que actualizó el registro.               |
-- +-------------------+-------------------+------------------------------------------+--------------------------------------------------+
-- | fec_update        | TIMESTAMP         |                                          | Fecha/hora de actualización del registro.        |
-- |                   | WITHOUT TIME ZONE |                                          |                                                  |
-- +-------------------+-------------------+------------------------------------------+--------------------------------------------------+

CREATE TABLE IF NOT EXISTS tab_regionales
(
    id_regional                 DECIMAL(2)                  NOT NULL,
    nom_regional                VARCHAR(50)                 NOT NULL CHECK(LENGTH(nom_regional) >= 10),
    dir_regional                VARCHAR(100)                NOT NULL CHECK(LENGTH(dir_regional) >= 10) DEFAULT 'Sin dirección',
    id_dpto                     VARCHAR(2)                  NOT NULL,
    tel_regional                telefono_fijo               NOT NULL DEFAULT 6010000000,
    num_extension_tel           extension                   NOT NULL DEFAULT 11111, 
    nom_director                VARCHAR(80)                 NOT NULL CHECK(LENGTH(nom_director) >= 3) DEFAULT 'Sin Datos',
    usr_insert                  VARCHAR(50)                 NOT NULL CHECK (LENGTH(TRIM(usr_insert)) >= 3),
    fec_insert                  TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update                  VARCHAR(50)                          CHECK (LENGTH(TRIM(usr_update)) >= 3),
    fec_update                  TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_regional),
    FOREIGN KEY(id_dpto) REFERENCES tab_dptos(id_dpto)
);

-- TABLA DE CENTROS DE UNA REGIONAL DEL SENA

-- TABLA DE TAB_CENTROS
-- ______________________________________________________________________________________________________________________________
-- |     Columna       |        Tipo       |                Restricción           |               Descripción                    |
-- +-------------------+-------------------+--------------------------------------+----------------------------------------------+
-- | id_centro         | DECIMAL(4,0)      | PRIMARY KEY                          | Número identificador del centro.             |
-- |                   |                   | NOT NULL                             |                                              |
-- +-------------------+-------------------+--------------------------------------+----------------------------------------------+
-- | nom_centro        | VARCHAR(100)      | NOT NULL                             | Nombre del centro.                           |
-- |                   |                   | CHECK(LENGTH(nom_centro) >= 3)       |                                              |
-- +-------------------+-------------------+--------------------------------------+----------------------------------------------+
-- | dir_centro        | VARCHAR(100)      | NOT NULL                             | Dirección del centro.                        |
-- |                   |                   | CHECK(LENGTH(dir_centro) >= 10)      |                                              |
-- +-------------------+-------------------+--------------------------------------+----------------------------------------------+
-- | tel_centro        | telefono_fijo     | NOT NULL                             | Número de teléfono del centro.               |
-- +-------------------+-------------------+--------------------------------------+----------------------------------------------+
-- | num_extension_tel | extension         | NOT NULL                             | Número de extensión del teléfono del centro. |
-- +-------------------+-------------------+--------------------------------------+----------------------------------------------+
-- | nom_subdirector   | VARCHAR(80)       | NOT NULL                             | Nombre del subdirector del centro.           |
-- |                   |                   | CHECK(LENGTH(nom_subdirector) >= 3)  |                                              |
-- +-------------------+-------------------+--------------------------------------+----------------------------------------------+
-- | id_regional       | DECIMAL(2,0)      | FOREIGN KEY                          | Número identificador de la regional.         |
-- |                   |                   | NOT NULL                             |                                              |
-- +-------------------+-------------------+--------------------------------------+----------------------------------------------+
-- | usr_insert        | VARCHAR(50)       | NOT NULL                             | Usuario que creó el registro.                |
-- +-------------------+-------------------+--------------------------------------+----------------------------------------------+
-- | fec_insert        | TIMESTAMP         | NOT NULL                             | Fecha/hora de creación del registro.         |
-- |                   | WITHOUT TIME ZONE |                                      |                                              |
-- +-------------------+-------------------+--------------------------------------+----------------------------------------------+
-- | usr_update        | VARCHAR(50)       | CHECK(LENGTH(TRIM(usr_update)) >= 3) | Usuario que actualizó el registro.           |
-- +-------------------+-------------------+--------------------------------------+----------------------------------------------+
-- | fec_update        | TIMESTAMP         |                                      | Fecha/hora de actualización del registro.    |
-- +-------------------+-------------------+--------------------------------------+----------------------------------------------+

CREATE TABLE IF NOT EXISTS tab_centros
(
    id_centro                   DECIMAL(4,0)                NOT NULL,
    nom_centro                  VARCHAR(100)                NOT NULL CHECK(LENGTH(nom_centro) >= 3),
    dir_centro                  VARCHAR(100)                NOT NULL CHECK(LENGTH(dir_centro) >= 10) DEFAULT 'Sin dirección',
    tel_centro                  telefono_fijo               NOT NULL DEFAULT 6010000000,
    num_extension_tel           extension                   NOT NULL DEFAULT 11111,
    nom_subdirector             VARCHAR(80)                 NOT NULL CHECK(LENGTH(nom_subdirector) >= 3),
    id_regional                 DECIMAL(2,0)                NOT NULL,
    usr_insert                  VARCHAR(50)                 NOT NULL CHECK (LENGTH(TRIM(usr_insert)) >= 3),
    fec_insert                  TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update                  VARCHAR(50)                          CHECK (LENGTH(TRIM(usr_update)) >= 3),
    fec_update                  TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_centro),
    FOREIGN KEY(id_regional) REFERENCES tab_regionales(id_regional)
);
 
-- TABLA DE SEDES DE UN CENTRO

-- TABLA DE TAB_SEDES
-- ________________________________________________________________________________________________________________________
-- |    Columna    |       Tipo        |                Restricción            |               Descripción                 |
-- +---------------+-------------------+---------------------------------------+-------------------------------------------+
-- | id_centro     | DECIMAL(4,0)      | PRIMARY KEY                           | Número identificador del centro.          |
-- |               |                   | FOREIGN KEY                           |                                           |
-- +---------------+-------------------+---------------------------------------+-------------------------------------------+
-- | id_sede       | DECIMAL(1,0)      | PRIMARY KEY                           | Número identificador de la sede.          |
-- |               |                   | NOT NULL                              |                                           |
-- +---------------+-------------------+---------------------------------------+-------------------------------------------+
-- | nom_sede      | VARCHAR(100)      | NOT NULL                              | Nombre de la sede.                        |
-- |               |                   | CHECK(LENGTH(nom_sede) >= 4)          |                                           |
-- +---------------+-------------------+---------------------------------------+-------------------------------------------+
-- | dir_sede      | VARCHAR(100)      | NOT NULL                              | Dirección de la sede.                     |
-- |               |                   | CHECK(LENGTH(dir_sede) >= 10)         |                                           |
-- +---------------+-------------------+---------------------------------------+-------------------------------------------+
-- | nom_encargado | VARCHAR(80)       | NOT NULL                              | Nombre del encargado.                     |
-- |               |                   | CHECK(LENGTH(nom_encargado) >= 3)     |                                           |
-- +---------------+-------------------+---------------------------------------+-------------------------------------------+
-- | tel_sede      | telefono_fijo     | NOT NULL                              | Número de teléfono de la sede.            |
-- +---------------+-------------------+---------------------------------------+-------------------------------------------+
-- | usr_insert    | VARCHAR(50)       | NOT NULL                              | Usuario que creó el registro.             |
-- |               |                   | CHECK (LENGTH(TRIM(usr_insert)) >= 3) |                                           |
-- +---------------+-------------------+---------------------------------------+-------------------------------------------+
-- | fec_insert    | TIMESTAMP         | NOT NULL                              | Fecha/hora de creación del registro.      |
-- |               | WITHOUT TIME ZONE |                                       |                                           |
-- +---------------+-------------------+---------------------------------------+-------------------------------------------+
-- | usr_update    | VARCHAR(50)       | CHECK (LENGTH(TRIM(usr_update)) >= 3) | Usuario que actualizó el registro.        |
-- +---------------+-------------------+---------------------------------------+-------------------------------------------+
-- | fec_update    | TIMESTAMP         |                                       | Fecha/hora de actualización del registro. |
-- |               | WITHOUT TIME ZONE |                                       |                                           |
-- +---------------+-------------------+---------------------------------------+-------------------------------------------+

CREATE TABLE IF NOT EXISTS tab_sedes
(
    id_centro               DECIMAL(4,0),
    id_sede                 DECIMAL(1,0)                NOT NULL,
    nom_sede                VARCHAR(100)                NOT NULL CHECK(LENGTH(nom_sede) >= 4),
    dir_sede                VARCHAR(100)                NOT NULL CHECK(LENGTH(dir_sede) >= 10),
    nom_encargado           VARCHAR(80)                 NOT NULL CHECK(LENGTH(nom_encargado) >= 3),
    tel_sede                telefono_fijo               NOT NULL,
    usr_insert              VARCHAR(50)                 NOT NULL CHECK (LENGTH(TRIM(usr_insert)) >= 3),
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR(50)                          CHECK (LENGTH(TRIM(usr_update)) >= 3),
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_centro,id_sede),
    FOREIGN KEY(id_centro) REFERENCES tab_centros(id_centro)
);

-- TABLA DE ÁREAS DE UN CENTRO

-- TABLA DE TAB_AREAS
-- ________________________________________________________________________________________________________________________
-- |    Columna    |       Tipo        |               Restricción             |                 Descripción               |
-- +---------------+-------------------+---------------------------------------+-------------------------------------------+
-- | id_area       | DECIMAL(2,0)      | PRIMARY KEY                           | Número identificador del área.            |
-- |               |                   | NOT NULL                              |                                           |
-- +---------------+-------------------+---------------------------------------+-------------------------------------------+
-- | nom_area      | VARCHAR(80)       | NOT NULL                              | Nombre del área.                          |
-- |               |                   | CHECK(LENGTH(nom_area) >= 3)          |                                           |
-- +---------------+-------------------+---------------------------------------+-------------------------------------------+
-- | id_centro     | DECIMAL(4,0)      | FOREIGN KEY                           | Número identificador del centro.          |
-- |               |                   | NOT NULL                              |                                           |
-- +---------------+-------------------+---------------------------------------+-------------------------------------------+
-- | nom_encargado | VARCHAR(80)       | NOT NULL                              | Nombre del encargado.                     |
-- |               |                   | CHECK(LENGTH(nom_encargado) >= 3)     |                                           |
-- +---------------+-------------------+---------------------------------------+-------------------------------------------+
-- | tel_area      | telefono_fijo     | NOT NULL                              | Número de teléfono del área.              |
-- +---------------+-------------------+---------------------------------------+-------------------------------------------+
-- | usr_insert    | VARCHAR(50)       | NOT NULL                              | Usuario que creó el registro.             |
-- |               |                   | CHECK (LENGTH(TRIM(usr_insert)) >= 3) |                                           |
-- +---------------+-------------------+---------------------------------------+-------------------------------------------+
-- | fec_insert    | TIMESTAMP         | NOT NULL                              | Fecha/hora de creación del registro.      |
-- |               | WITHOUT TIME ZONE |                                       |                                           |
-- +---------------+-------------------+---------------------------------------+-------------------------------------------+
-- | usr_update    | VARCHAR(50)       | CHECK (LENGTH(TRIM(usr_update)) >= 3) | Usuario que actualizó el registro.        |
-- +---------------+-------------------+---------------------------------------+-------------------------------------------+
-- | fec_update    | TIMESTAMP         |                                       | Fecha/hora de actualización del registro. |
-- |               | WITHOUT TIME ZONE |                                       |                                           |
-- +---------------+-------------------+---------------------------------------+-------------------------------------------+

CREATE TABLE IF NOT EXISTS tab_areas
(
    id_area                 DECIMAL(2,0)                NOT NULL,
    nom_area                VARCHAR(80)                 NOT NULL CHECK(LENGTH(nom_area) >= 3),
    id_centro               DECIMAL(4,0)                NOT NULL,
    nom_encargado           VARCHAR(80)                 NOT NULL CHECK(LENGTH(nom_encargado) >= 3),
    tel_area                telefono_fijo               NOT NULL,
    usr_insert              VARCHAR(50)                 NOT NULL CHECK (LENGTH(TRIM(usr_insert)) >= 3),
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR(50)                          CHECK (LENGTH(TRIM(usr_update)) >= 3),
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_area),
    FOREIGN KEY(id_centro) REFERENCES tab_centros(id_centro)
);

-- TABLA DE CARGOS DE FUNCIONARIOS DE UN CENTRO

-- TABLA DE TAB_CARGOS
-- ___________________________________________________________________________________________________________________________________
-- |    Columna     |            Tipo             |               Restricción             |                Descripción                |
-- +----------------+-----------------------------+--------------------------------------+-------------------------------------------+
-- | id_cargo       | DECIMAL(2,0)                | PRIMARY KEY                          | Número identificador del cargo.           |
-- |                |                             | NOT NULL                             |                                           |
-- +----------------+-----------------------------+--------------------------------------+-------------------------------------------+
-- | nom_cargo      | VARCHAR(90)                 | NOT NULL                             | Nombre del cargo.                         |
-- |                |                             | CHECK(LENGTH(nom_cargo) >= 3)        |                                           |
-- +----------------+-----------------------------+--------------------------------------+-------------------------------------------+
-- | usr_insert     | VARCHAR(50)                 | NOT NULL                             | Usuario que creó el registro.             |
-- |                |                             | CHECK (LENGTH(TRIM(usr_insert)) >= 3)|                                           |
-- +----------------+-----------------------------+--------------------------------------+-------------------------------------------+
-- | fec_insert     | TIMESTAMP WITHOUT TIME ZONE | NOT NULL                             | Fecha/hora de creación del registro.      |
-- +----------------+-----------------------------+--------------------------------------+-------------------------------------------+
-- | usr_update     | VARCHAR(50)                 | CHECK (LENGTH(TRIM(usr_update)) >= 3)| Usuario que actualizó el registro.        |
-- +----------------+-----------------------------+--------------------------------------+-------------------------------------------+
-- | fec_update     | TIMESTAMP WITHOUT TIME ZONE |                                      | Fecha/hora de actualización del registro. |
-- +----------------+-----------------------------+--------------------------------------+-------------------------------------------+

CREATE TABLE IF NOT EXISTS tab_cargos
(
    id_cargo                DECIMAL(2,0)                NOT NULL,
    nom_cargo               VARCHAR(90)                 NOT NULL CHECK(LENGTH(nom_cargo) >= 3),
    usr_insert              VARCHAR(50)                 NOT NULL CHECK (LENGTH(TRIM(usr_insert)) >= 3),
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR(50)                          CHECK (LENGTH(TRIM(usr_update)) >= 3),
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_cargo)
);

-- TAVBLE DE CENTRADAS DE UN CENTRO PARA CONTROL DE INGRESO

-- TABLA DE TAB_ENTRADAS_CENTRO
-- ______________________________________________________________________________________________________________________________
-- |       Columna      |      Tipo         |               Restricción              |                Descripción                |
-- +--------------------+-------------------+----------------------------------------+-------------------------------------------+
-- | id_entrada_centro  | DECIMAL(1,0)      | PRIMARY KEY                            | Número identificador de la entrada.       |
-- |                    |                   | NOT NULL                               |                                           |
-- +--------------------+-------------------+----------------------------------------+-------------------------------------------+
-- | nom_entrada_centro | VARCHAR(50)       | NOT NULL                               | Nombre de la entrada al centro.           |
-- |                    |                   | CHECK(LENGTH(nom_entrada_centro) >= 5) |                                           |
-- +--------------------+-------------------+----------------------------------------+-------------------------------------------+
-- | id_centro          | DECIMAL(4,0)      | FOREIGN KEY                            | Número identificador del centro.          |
-- |                    |                   | NOT NULL                               |                                           |
-- +--------------------+-------------------+----------------------------------------+-------------------------------------------+
-- | id_sede            | DECIMAL(1,0)      | FOREIGN KEY                            | Número identificador de la sede.          |
-- |                    |                   | NOT NULL                               |                                           |
-- +--------------------+-------------------+----------------------------------------+-------------------------------------------+
-- | usr_insert         | VARCHAR(50)       | NOT NULL                               | Usuario que creó el registro.             |
-- |                    |                   | CHECK (LENGTH(TRIM(usr_insert)) >= 3)  |                                           |
-- +--------------------+-------------------+----------------------------------------+-------------------------------------------+
-- | fec_insert         | TIMESTAMP         | NOT NULL                               | Fecha/hora de creación del registro.      |
-- |                    | WITHOUT TIME ZONE |                                        |                                           |
-- +--------------------+-------------------+----------------------------------------+-------------------------------------------+
-- | usr_update         | VARCHAR(50)       | CHECK (LENGTH(TRIM(usr_update)) >= 3)  | Usuario que actualizó el registro.        |
-- +--------------------+-------------------+----------------------------------------+-------------------------------------------+
-- | fec_update         | TIMESTAMP         |                                        | Fecha/hora de actualización del registro. |
-- |                    | WITHOUT TIME ZONE |                                        |                                           |
-- +--------------------+-------------------+----------------------------------------+-------------------------------------------+

CREATE TABLE IF NOT EXISTS tab_entradas_centro
(
    id_entrada_centro       DECIMAL(1,0)                NOT NULL,
    nom_entrada_centro      VARCHAR(50)                 NOT NULL CHECK(LENGTH(nom_entrada_centro) >= 5),
    id_centro               DECIMAL(4,0)                NOT NULL,
    id_sede                 DECIMAL(1,0)                NOT NULL,
    usr_insert              VARCHAR(50)                 NOT NULL CHECK (LENGTH(TRIM(usr_insert)) >= 3),
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR(50)                          CHECK (LENGTH(TRIM(usr_update)) >= 3),
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
	PRIMARY KEY(id_entrada_centro),
    FOREIGN KEY(id_centro,id_sede) REFERENCES tab_sedes(id_centro,id_sede)
);

-- TABLA DE REDES DE CONOCIMIENTO SENA

-- TABLA DE TAB_REDES
-- _____________________________________________________________________________________________________________________
-- |  Columna   |            Tipo   |               Restricción             |                Descripción                |
-- +------------+-------------------+---------------------------------------+-------------------------------------------+
-- | id_red     | DECIMAL(2,0)      | PRIMARY KEY                           | Número identificador de la red.           |
-- |            |                   | NOT NULL                              |                                           |
-- +------------+-------------------+---------------------------------------+-------------------------------------------+
-- | nom_red    | TEXT              | NOT NULL                              | Nombre de la red.                         |
-- +------------+-------------------+---------------------------------------+-------------------------------------------+
-- | nom_lider  | VARCHAR(80)       | NOT NULL                              | Nombre del líder.                         |
-- |            |                   | CHECK(LENGTH(nom_lider) >= 3)         |                                           |
-- +------------+-------------------+---------------------------------------+-------------------------------------------+
-- | usr_insert | VARCHAR(50)       | NOT NULL                              | Usuario que creó el registro.             |
-- |            |                   | CHECK (LENGTH(TRIM(usr_insert)) >= 3) |                                           |
-- +------------+-------------------+---------------------------------------+-------------------------------------------+
-- | fec_insert | TIMESTAMP         | NOT NULL                              | Fecha/hora de creación del registro.      |
-- |            | WITHOUT TIME ZONE |                                       |                                           |
-- +------------+-------------------+---------------------------------------+-------------------------------------------+
-- | usr_update | VARCHAR(50)       | CHECK (LENGTH(TRIM(usr_update)) >= 3) | Usuario que actualizó el registro.        |
-- +------------+-------------------+---------------------------------------+-------------------------------------------+
-- | fec_update | TIMESTAMP         |                                       | Fecha/hora de actualización del registro. |
-- |            | WITHOUT TIME ZONE |                                       |                                           |
-- +------------+-------------------+---------------------------------------+-------------------------------------------+

CREATE TABLE IF NOT EXISTS tab_redes
(
    id_red                  DECIMAL(2,0)                NOT NULL,
    nom_red           		TEXT                        NOT NULL CHECK(LENGTH(nom_red) >= 3),
    nom_lider               VARCHAR(80)                 NOT NULL CHECK(LENGTH(nom_lider) >= 3),
    usr_insert              VARCHAR(50)                 NOT NULL CHECK (LENGTH(TRIM(usr_insert)) >= 3),
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR(50)                          CHECK (LENGTH(TRIM(usr_update)) >= 3),
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
	PRIMARY KEY(id_red)
);

-- TABLA DE PARÁMETROS GENERALES DEL SISTEMA APLICABLE A TODOS LOS PROCESOS.

-- TABLA DE TAB_PMTROS_GRALES
-- _______________________________________________________________________________________________________________________________________________________________________________________________________
-- |          Columna           |       Tipo        |                                Restricción                                |                           Descripción                                   |
-- +----------------------------+-------------------+---------------------------------------------------------------------------+-------------------------------------------------------------------------+
-- | id_centro                  | DECIMAL(8,0)      | PRIMARY KEY                                                               | Número identificador de los parametros generales.                       |
-- |                            |                   | FOREIGN KEY                                                               | Número identificador de los centros.                                    |
-- |                            |                   | NOT NULL                                                                  | Centro en donde estará ejecutando SMARCSET.                             |
-- +----------------------------+-------------------+---------------------------------------------------------------------------+-------------------------------------------------------------------------+
-- | dir_centro                 | VARCHAR(90)       | NOT NULL                                                                  | Dirección del centro.                                                   |
-- |                            |                   | CHECK(LENGTH(dir_centro) >= 10)                                           |                                                                         |
-- +----------------------------+-------------------+---------------------------------------------------------------------------+-------------------------------------------------------------------------+
-- | tel_centro                 | DECIMAL(10,0)     | NOT NULL                                                                  | Número de teléfono del centro.                                          |
-- +----------------------------+-------------------+---------------------------------------------------------------------------+-------------------------------------------------------------------------+
-- | ano_academico              | DECIMAL(4,0)      | NOT NULL                                                                  | Año académico en el que está trabajando.                                |
-- +----------------------------+-------------------+---------------------------------------------------------------------------+-------------------------------------------------------------------------+
-- | mes_academico              | DECIMAL(2,0)      | NOT NULL                                                                  | Mes académico.                                                          |
-- +----------------------------+-------------------+---------------------------------------------------------------------------+-------------------------------------------------------------------------+
-- | val_nota_minima_rap        | DECIMAL(3,0)      | NOT NULL                                                                  | Nota mínima del aprendiz para aprobar.                                  |
-- |                            |                   | DEFAULT 71                                                                |                                                                         |
-- |                            |                   | CHECK(val_nota_minima_rap >= 0 AND val_nota_minima_rap <= 100)            |                                                                         |
-- +----------------------------+-------------------+---------------------------------------------------------------------------+-------------------------------------------------------------------------+
-- | num_horas_instructor       | DECIMAL(3,0)      | NOT NULL                                                                  | Horas al mes que instructor debe cumplir por contrato.                  |
-- |                            |                   | DEFAULT 160                                                               |                                                                         |
-- |                            |                   | CHECK(num_horas_instructor >=0 AND num_horas_instructor <= 200)           |                                                                         |
-- +----------------------------+-------------------+---------------------------------------------------------------------------+-------------------------------------------------------------------------+
-- | val_porcent_icfes_raps     | DECIMAL(2,0)      | NOT NULL                                                                  | Valor mínimo de raps calificados para asistir a pruebas ICFES.          |
-- +----------------------------+-------------------+---------------------------------------------------------------------------+-------------------------------------------------------------------------+
-- | val_tiempo_gracia_aprendiz | DECIMAL(2,0)      | NOT NULL                                                                  | Minutos de tardanza permitidos para un aprendiz.                        |
-- +----------------------------+-------------------+---------------------------------------------------------------------------+-------------------------------------------------------------------------+
-- | val_tiempo_gracia_instru   | DECIMAL(2,0)      | NOT NULL                                                                  | Minutos de tiempo de gracia para instructores.                          |
-- +----------------------------+-------------------+---------------------------------------------------------------------------+-------------------------------------------------------------------------+
-- | val_max_llamados_aprendiz  | DECIMAL(1,0)      | NOT NULL                                                                  | Número máximo de llamados de atención para enviar al aprendiz a comité. |
-- +----------------------------+-------------------+---------------------------------------------------------------------------+-------------------------------------------------------------------------+
-- | nom_administrador          | VARCHAR(80)       | NOT NULL                                                                  | Nombre del administrador.                                               |
-- |                            |                   | CHECK(LENGTH(nom_administrador) >= 3 AND LENGTH(nom_administrador) <= 80) |                                                                         |
-- +----------------------------+-------------------+---------------------------------------------------------------------------+-------------------------------------------------------------------------+
-- | tel_administrador          | DECIMAL(10,0)     | NOT NULL                                                                  | Número de teléfono del administrador.                                   |
-- +----------------------------+-------------------+---------------------------------------------------------------------------+-------------------------------------------------------------------------+
-- | usr_insert                 | VARCHAR(50)       | NOT NULL                                                                  | Usuario que creó el registro.                                           |
-- |                            |                   | CHECK (LENGTH(TRIM(usr_insert)) >= 3)                                     |                                                                         |
-- +----------------------------+-------------------+---------------------------------------------------------------------------+-------------------------------------------------------------------------+
-- | fec_insert                 | TIMESTAMP         | NOT NULL                                                                  | Fecha/hora de creación del registro.                                    |
-- |                            | WITHOUT TIME ZONE |                                                                           |                                                                         |
-- +----------------------------+-------------------+---------------------------------------------------------------------------+-------------------------------------------------------------------------+
-- | usr_update                 | VARCHAR(50)       | CHECK (LENGTH(TRIM(usr_update)) >= 3)                                     | Usuario que actualizó el registro.                                      |
-- |                            |                   |                                                                           |                                                                         |
-- +----------------------------+-------------------+---------------------------------------------------------------------------+-------------------------------------------------------------------------+
-- | fec_update                 | TIMESTAMP         |                                                                           | Fecha/hora de actualización del registro.                               |
-- |                            | WITHOUT TIME ZONE |                                                                           |                                                                         |
-- +----------------------------+-------------------+---------------------------------------------------------------------------+-------------------------------------------------------------------------+

CREATE TABLE IF NOT EXISTS tab_pmtros_grales
(
    id_centro                   DECIMAL(8,0)                NOT NULL,-- Centro en donde se está ejecutando SMARTCSET
    dir_centro                  VARCHAR(90)                 NOT NULL CHECK(LENGTH(dir_centro) >= 10), -- Dirección del Centro
    tel_centro                  DECIMAL(10,0)               NOT NULL,-- Teléfono del Centro
    ano_academico               DECIMAL(4,0)                NOT NULL,-- Año en el que se está trabajando
    mes_academico               DECIMAL(2,0)                NOT NULL,-- Mes. Debe actualizarse automáticamente (EJECUTAR FUNCIÓN CRON)
    val_nota_minima_rap         DECIMAL(3,0)                NOT NULL DEFAULT 71  CHECK(val_nota_minima_rap >= 0 AND val_nota_minima_rap <= 100), -- Nota mínima de aprendiz para aprobar
    num_horas_instructor        DECIMAL(3,0)                NOT NULL DEFAULT 160 CHECK(num_horas_instructor >=0 AND num_horas_instructor <= 200), -- Horas mes instructor por cumplir por contrato
    val_porcent_icfes_raps      DECIMAL(2,0)                NOT NULL DEFAULT 75,-- Valor mínimo de raps calificados para asistir a pruebas ICFES
    val_tiempo_gracia_aprendiz  DECIMAL(2,0)                NOT NULL DEFAULT 0, -- Minutos de tardanza permitidos para un aprendiz
    val_tiempo_gracia_instru    DECIMAL(2,0)                NOT NULL DEFAULT 0, -- Minutos de tardanza permitidos para un instructor
    val_max_llamados_aprendiz   DECIMAL(1,0)                NOT NULL DEFAULT 3, -- Máximo # de llamados de at. a un aprendiz para enviar a comité
    nom_administrador           VARCHAR(80)                 NOT NULL CHECK(LENGTH(nom_administrador) >= 3 AND LENGTH(nom_administrador) <= 80),
    tel_administrador           DECIMAL(10,0)               NOT NULL,
    usr_insert                  VARCHAR(50)                 NOT NULL CHECK (LENGTH(TRIM(usr_insert)) >= 3),
    fec_insert                  TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update                  VARCHAR(50)                          CHECK (LENGTH(TRIM(usr_update)) >= 3),
    fec_update                  TIMESTAMP WITHOUT TIME ZONE,
	PRIMARY KEY(id_centro),
    FOREIGN KEY(id_centro) REFERENCES tab_centros(id_centro)
);

-- *******************************************
-- 3. TABLAS GENERALES DE CARACTER TRANSVERSAL
-- *******************************************
-- TABLA DE TIPOS DE DOCUMENTO PARA PERSONAS

-- TABLA DE TAB_TIPOS_DOCUM
-- ________________________________________________________________________________________________________________________
-- | Columna        |       Tipo        |              Restricción             | Descripción                               |
-- +----------------+-------------------+--------------------------------------+-------------------------------------------+
-- | id_tipo_docum  | VARCHAR(2)        | PRIMARY KEY                          | Número identificador del documento.       |
-- |                |                   | NOT NULL                             |                                           |
-- +----------------+-------------------+--------------------------------------+-------------------------------------------+
-- | nom_tipo_docum | VARCHAR(40)       | NOT NULL                             | Nombre del tipo documento.                |
-- |                |                   | CHECK(LENGTH(nom_tipo_docum) >= 2)   |                                           |
-- +----------------+-------------------+--------------------------------------+-------------------------------------------+
-- | usr_insert     | VARCHAR(50)       | NOT NULL                             | Usuario que creó el registro.             |
-- |                |                   | CHECK(LENGTH(TRIM(usr_insert)) >= 3) |                                           |
-- +----------------+-------------------+--------------------------------------+-------------------------------------------+
-- | fec_insert     | TIMESTAMP         | NOT NULL                             | Fecha/hora de creación del registro.      |
-- |                | WITHOUT TIME ZONE |                                      |                                           |
-- +----------------+-------------------+--------------------------------------+-------------------------------------------+
-- | usr_update     | VARCHAR(50)       | CHECK(LENGTH(TRIM(usr_update)) >= 3) | Usuario que actualizó el registro.        |
-- +----------------+-------------------+--------------------------------------+-------------------------------------------+
-- | fec_update     | TIMESTAMP         |                                      | Fecha/hora de actualización del registro. |
-- |                | WITHOUT TIME ZONE |                                      |                                           |
-- +----------------+-------------------+--------------------------------------+-------------------------------------------+

CREATE TABLE IF NOT EXISTS tab_tipos_docum
(
    id_tipo_docum               VARCHAR(4)                  NOT NULL,
    nom_tipo_docum              VARCHAR(40)                 NOT NULL CHECK(LENGTH(nom_tipo_docum) >= 2),
    usr_insert                  VARCHAR(50)                 NOT NULL CHECK(LENGTH(TRIM(usr_insert)) >= 3),
    fec_insert                  TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update                  VARCHAR(50)                          CHECK(LENGTH(TRIM(usr_update)) >= 3),
    fec_update                  TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_tipo_docum)
);

-- TABLA DE EMPRESAS QUE TIENEN QUE VER CON EL CENTRO (PRODUCTIVA DE APRENDICEZ, CONTRATISTAS, ETC.)

-- TABLA DE TAB_EMPRESAS
-- _________________________________________________________________________________________________________________________
-- |    Columna    |        Tipo       |              Restricción             |                 Descripción                 |
-- +---------------+-------------------+--------------------------------------+---------------------------------------------+
-- | id_empresa    | DECIMAL(10,0)     | PRIMARY KEY                          | Número identificador de la empresa.         |
-- |               |                   | NOT NULL                             |                                             |
-- +---------------+-------------------+--------------------------------------+---------------------------------------------+
-- | id_tipo_docum | VARCHAR(3)        | FOREIGN KEY                          | Número identificador del tipo de documento. |
-- |               |                   | NOT NULL                             |                                             |
-- |               |                   | DEFAULT 'N/A'                        |                                             |
-- +---------------+-------------------+--------------------------------------+---------------------------------------------+
-- | nom_empresa   | VARCHAR(100)      | NOT NULL                             | Nombre de la empresa.                       |
-- |               |                   | DEFAULT 'Sin Empresa'                |                                             |
-- |               |                   | CHECK(LENGTH(nom_empresa) >= 2)      |                                             |
-- +---------------+-------------------+--------------------------------------+---------------------------------------------+
-- | usr_insert    | VARCHAR(50)       | NOT NULL                             | Usuario que creó el registro.               |
-- |               |                   | CHECK(LENGTH(TRIM(usr_insert)) >= 3) |                                             |
-- +---------------+-------------------+--------------------------------------+---------------------------------------------+
-- | fec_insert    | TIMESTAMP         | NOT NULL                             | Fecha/hora de creación del registro.        |
-- |               | WITHOUT TIME ZONE |                                      |                                             |
-- +---------------+-------------------+--------------------------------------+---------------------------------------------+
-- | usr_update    | VARCHAR(50)       | CHECK(LENGTH(TRIM(usr_update)) >= 3) | Usuario que actualizó el registro.          |
-- |               |                   |                                      |                                             |
-- +---------------+-------------------+--------------------------------------+---------------------------------------------+
-- | fec_update    | TIMESTAMP         |                                      | Fecha/hora de actualización del registro.   |
-- |               | WITHOUT TIME ZONE |                                      |                                             |
-- +---------------+-------------------+--------------------------------------+---------------------------------------------+

CREATE TABLE IF NOT EXISTS tab_empresas
(
    id_empresa                  DECIMAL(10,0)               NOT NULL,
    id_tipo_docum               VARCHAR(3)                  NOT NULL DEFAULT 'N/A',
    nom_empresa                 VARCHAR(100)                NOT NULL CHECK(LENGTH(nom_empresa) >= 2) DEFAULT 'Sin Empresa',
    usr_insert                  VARCHAR(50)                 NOT NULL CHECK(LENGTH(TRIM(usr_insert)) >= 3),
    fec_insert                  TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update                  VARCHAR(50)                          CHECK(LENGTH(TRIM(usr_update)) >= 3),
    fec_update                  TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_empresa),
    FOREIGN KEY(id_tipo_docum) REFERENCES tab_tipos_docum(id_tipo_docum)
);

-- TABLA DE PROFESIONES SEGÚN "CUOC-indice-clasificacion-unica-ocupaciones-colombia"

-- TABLA DE TAB_PROFESIONES
-- _______________________________________________________________________________________________________________________
-- |   Columna     |        Tipo       |             Restricción              |                Descripción                |
-- +---------------+-------------------+--------------------------------------+-------------------------------------------+
-- | id_profesion  | VARCHAR           | PRIMARY KEY                          | Número identificador de la profesión.     |
-- |               |                   | NOT NULL                             |                                           |
-- +---------------+-------------------+--------------------------------------+-------------------------------------------+
-- | nom_profesion | VARCHAR           | NOT NULL                             | Nombre de la profesión.                   |
-- |               |                   | CHECK(LENGTH(nom_profesion) >= 4)    |                                           |
-- +---------------+-------------------+--------------------------------------+-------------------------------------------+
-- | usr_insert    | VARCHAR           | NOT NULL                             | Usuario que creó el registro.             |
-- |               |                   | CHECK(LENGTH(usr_insert) >= 3)       |                                           |
-- +---------------+-------------------+--------------------------------------+-------------------------------------------+
-- | fec_insert    | TIMESTAMP         | NOT NULL                             | Fecha/hora de creación del registro.      |
-- |               | WITHOUT TIME ZONE |                                      |                                           |
-- +---------------+-------------------+--------------------------------------+-------------------------------------------+
-- | usr_update    | VARCHAR           | CHECK(LENGTH(TRIM(usr_update)) >= 3) | Usuario que actualizó el registro.        |
-- +---------------+-------------------+--------------------------------------+-------------------------------------------+
-- | fec_update    | TIMESTAMP         |                                      | Fecha/hora de actualización del registro. |
-- +---------------+-------------------+--------------------------------------+-------------------------------------------+

CREATE TABLE IF NOT EXISTS tab_profesiones
(
    id_profesion                VARCHAR                     NOT NULL,
    nom_profesion               VARCHAR(250)                NOT NULL CHECK(LENGTH(nom_profesion) >= 3),
    usr_insert                  VARCHAR(50)                 NOT NULL CHECK(LENGTH(TRIM(usr_insert)) >= 3),
    fec_insert                  TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update                  VARCHAR(50)                          CHECK(LENGTH(TRIM(usr_update)) >= 3),
    fec_update                  TIMESTAMP WITHOUT TIME ZONE,
  PRIMARY KEY(id_profesion)
);

-- TABLA DE NIVELES DE ESTUDIO

-- TABLA DE TAB_NIVELES_ESTUDIO
-- ______________________________________________________________________________________________________________________________
-- |     Columna       |        Tipo       | Restricción                            | Descripción                                |
-- +-------------------+-------------------+----------------------------------------+--------------------------------------------+
-- | id_nivel_estudio  | DECIMAL(2,0)      | PRIMARY KEY                            | Número identificador del nivel de estudio. |
-- |                   |                   | NOT NULL                               |                                            |
-- +-------------------+-------------------+----------------------------------------+--------------------------------------------+
-- | nom_nivel_estudio | VARCHAR(50)       | NOT NULL                               | Nombre del nivel estudio.                  |
-- |                   |                   | CHECK(LENGTH(nom_nivel_estudio) >= 5)  |                                            |
-- +-------------------+-------------------+----------------------------------------+--------------------------------------------+
-- | usr_insert        | VARCHAR(50)       | NOT NULL                               | Usuario que creó el registro.              |
-- |                   |                   | CHECK(LENGTH(TRIM(usr_insert)) >= 3)   |                                            |
-- +-------------------+-------------------+----------------------------------------+--------------------------------------------+
-- | fec_insert        | TIMESTAMP         | NOT NULL                               | Fecha/hora de creación del registro.       |
-- |                   | WITHOUT TIME ZONE |                                        |                                            |
-- +-------------------+-------------------+----------------------------------------+--------------------------------------------+
-- | usr_update        | VARCHAR(50)       | CHECK(LENGTH(TRIM(usr_update)) >= 3)   | Usuario que creó/actualizó el registro.    |
-- +-------------------+-------------------+----------------------------------------+--------------------------------------------+
-- | fec_update        | TIMESTAMP         |                                        | Fecha/hora de actualización del registro.  |
-- |                   | WITHOUT TIME ZONE |                                        |                                            |
-- +-------------------+-------------------+----------------------------------------+--------------------------------------------+

CREATE TABLE IF NOT EXISTS tab_niveles_estudio
(
    id_nivel_estudio            DECIMAL(2,0)                NOT NULL,
    nom_nivel_estudio           VARCHAR(50)                 NOT NULL CHECK(LENGTH(nom_nivel_estudio) >= 5),
    usr_insert                  VARCHAR(50)                 NOT NULL CHECK(LENGTH(TRIM(usr_insert)) >= 3),
    fec_insert                  TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update                  VARCHAR(50)                          CHECK(LENGTH(TRIM(usr_update)) >= 3),
    fec_update                  TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_nivel_estudio)
);

-- TABLA DE TIPOS DE PERSONAS (Instructor / Aprendiz /Funcionario, etc)

-- TABLA DE TAB_TIPOS_PERSONA
-- __________________________________________________________________________________________________________________________
-- |     Columna      |      Tipo         |             Restricción              |                 Descripción               |
-- +------------------+-------------------+--------------------------------------+-------------------------------------------+
-- | id_tipo_persona  | DECIMAL(2,0)      | PRIMARY KEY                          | Número identificador del tipo persona.    |
-- |                  |                   | NOT NULL                             | Identificador.                            |
-- +------------------+-------------------+--------------------------------------+-------------------------------------------+
-- | nom_tipo_persona | VARCHAR(25)       | NOT NULL                             | Nombre del tipo persona.                  |
-- |                  |                   | CHECK(LENGTH(nom_tipo_persona) >= 5) |                                           |
-- +------------------+-------------------+--------------------------------------+-------------------------------------------+
-- | usr_insert       | VARCHAR(50)       | NOT NULL                             | Usuario que creó/actualizó el registro.   |
-- |                  |                   | CHECK(LENGTH(TRIM(usr_insert)) >= 3) |                                           |
-- +------------------+-------------------+--------------------------------------+-------------------------------------------+
-- | fec_insert       | TIMESTAMP         | NOT NULL                             | Fecha/hora de creación del registro.      |
-- |                  | WITHOUT TIME ZONE |                                      |                                           |
-- +------------------+-------------------+--------------------------------------+-------------------------------------------+
-- | usr_update       | VARCHAR(50)       | CHECK(LENGTH(TRIM(usr_update)) >= 3) | Usuario que creó/actualizó el registro.   |
-- +------------------+-------------------+--------------------------------------+-------------------------------------------+
-- | fec_update       | TIMESTAMP         |                                      | Fecha/hora de actualización del registro. |
-- |                  | WITHOUT TIME ZONE |                                      |                                           |
-- +------------------+-------------------+--------------------------------------+-------------------------------------------+

CREATE TABLE IF NOT EXISTS tab_tipos_persona
(
    id_tipo_persona             DECIMAL(2,0)                NOT NULL,
    nom_tipo_persona            VARCHAR(25)                 NOT NULL CHECK(LENGTH(nom_tipo_persona) >= 5),
    usr_insert                  VARCHAR(50)                 NOT NULL CHECK(LENGTH(TRIM(usr_insert)) >= 3),
    fec_insert                  TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update                  VARCHAR(50)                          CHECK(LENGTH(TRIM(usr_update)) >= 3),
    fec_update                  TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_tipo_persona)
);

-- *******************************************************************
-- 4. TABLAS DE PERSONAS COMO EMPRESAS, INSTRUCTORES, APRENDICES, ETC.
-- *******************************************************************
-- TABLAS GENERALES DE PERSONAS QUE ALIMENTA A TODAS LAS DEMÁS (Instructores, aprendices, visitantes, etc.)

-- TABLA DE TAB_PERSONAS
-- _______________________________________________________________________________________________________________________________________________________
-- |          Columna         |       Tipo        |                 Restricción                  |                       Descripción                      |
-- +--------------------------+-------------------+----------------------------------------------+--------------------------------------------------------+
-- | id_persona               | DECIMAL(10,0)     | PRIMARY KEY                                  | Número identificador de la persona.                    |
-- |                          |                   | NOT NULL                                     |                                                        |
-- +--------------------------+-------------------+----------------------------------------------+--------------------------------------------------------+
-- | id_tipo_docum            | VARCHAR(2)        | FOREIGN KEY                                  | Número identificador del tipo de documento.            |
-- |                          |                   | NOT NULL                                     |                                                        |
-- |                          |                   | DEFAULT 'CC'                                 |                                                        |
-- +--------------------------+-------------------+----------------------------------------------+--------------------------------------------------------+
-- | id_tipo_persona          | DECIMAL(2,0)      | FOREIGN KEY                                  | Número identificador del tipo de persona.              |
-- |                          |                   | NOT NULL                                     |                                                        |
-- +--------------------------+-------------------+----------------------------------------------+--------------------------------------------------------+
-- | nom_persona              | VARCHAR(40)       | NOT NULL                                     | Nombre de la persona.                                  |
-- |                          |                   | CHECK(LENGTH(nom_persona) >= 3)              |                                                        |
-- +--------------------------+-------------------+----------------------------------------------+--------------------------------------------------------+
-- | ape_persona              | VARCHAR(30)       | NOT NULL                                     | Apellido de la persona.                                |
-- |                          |                   | CHECK(LENGTH(ape_persona) >= 2)              |                                                        |    
-- +--------------------------+-------------------+----------------------------------------------+--------------------------------------------------------+
-- | mail_persona             | mail_personal     | NOT NULL                                     | Dirección de correo de la persona.                     |
-- |                          |                   | DEFAULT 'Sin Correo'                         |                                                        |    
-- +--------------------------+-------------------+----------------------------------------------+--------------------------------------------------------+
-- | fec_nacimiento           | DATE              | NOT NULL                                     | Fecha/hora de nacimiento de la persona.                |
-- |                          |                   | DEFAULT '1900-01-01'                         |                                                        |    
-- +--------------------------+-------------------+----------------------------------------------+--------------------------------------------------------+
-- | ind_genero               | DECIMAL(2,0)      | NOT NULL                                     | Identificador del género de la persona.                |
-- |                          |                   |                                              | 99=No definido                                         |    
-- +--------------------------+-------------------+----------------------------------------------+--------------------------------------------------------+
-- | val_huella_digital       | BYTEA             |                                              | Valor numérico de la huella digital.                   |
-- +--------------------------+-------------------+----------------------------------------------+--------------------------------------------------------+
-- | val_patron_facial        | JSONB             |                                              | Patrón facial de la persona.                           |
-- +--------------------------+-------------------+----------------------------------------------+--------------------------------------------------------+
-- | fec_ultima_entrada       | TIMESTAMP         | NOT NULL                                     | Fecha/hora de la última entrada de la persona.         |
-- |                          | WITHOUT TIME ZONE |                                              |                                                        |
-- +--------------------------+-------------------+----------------------------------------------+--------------------------------------------------------+
-- | fec_ultima_salida        | TIMESTAMP         | NOT NULL                                     | Fecha/hora de la última salida de la persona.          |
-- |                          | WITHOUT TIME ZONE |                                              |                                                        |
-- +--------------------------+-------------------+----------------------------------------------+--------------------------------------------------------+
-- | num_visitas              | SMALLINT          | NOT NULL                                     | Número de visitas de la persona.                       |
-- |                          |                   | DEFAULT 0                                    |                                                        |    
-- +--------------------------+------------------ -+----------------------------------------------+-------------------------------------------------------+
-- | id_nivel_estudio         | DECIMAL(2,0)      | FOREIGN KEY                                  | Número identificador del nivel de estudio.             |
-- |                          |                   | NOT NULL                                     |                                                        |
-- +--------------------------+-------------------+----------------------------------------------+--------------------------------------------------------+
-- | id_profesion             | VARCHAR           | FOREIGN KEY                                  | Identificador de la profesión.                         |
-- |                          |                   | NOT NULL                                     |                                                        |
-- +--------------------------+-------------------+----------------------------------------------+--------------------------------------------------------+
-- | id_dpto_reside           | VARCHAR(2)        | FOREIGN KEY                                  | Identificador del departamento donde reside.           |
-- |                          |                   | NOT NULL                                     |                                                        |
-- +--------------------------+-------------------+----------------------------------------------+--------------------------------------------------------+
-- | id_ciudad_reside         | VARCHAR(5)        | FOREIGN KEY                                  | Identificador de la ciudad donde reside.               |
-- |                          |                   | NOT NULL                                     |                                                        |
-- +--------------------------+-------------------+----------------------------------------------+--------------------------------------------------------+
-- | dir_ciudad_reside        | VARCHAR(100)      | NOT NULL                                     | Dirección de residencia de la persona.                 |
-- |                          |                   | CHECK(LENGTH(dir_ciudad_reside) >= 10)       |                                                        |    
-- +--------------------------+-------------------+----------------------------------------------+--------------------------------------------------------+
-- | tel_persona_fijo         | telefono_fijo     | NOT NULL                                     | Teléfono fijo de la persona.                           |
-- +--------------------------+-------------------+----------------------------------------------+--------------------------------------------------------+
-- | tel_persona_movil        | telefono_movil    | NOT NULL                                     | Teléfono móvil de la persona.                          |
-- +--------------------------+-------------------+----------------------------------------------+--------------------------------------------------------+
-- | nom_contacto_emergencias | VARCHAR(60)       | NOT NULL                                     | Nombre del contacto de emergencia.                     |
-- |                          |                   | CHECK(LENGTH(nom_contacto_emergencias) >= 5) |                                                        |    
-- +--------------------------+-------------------+----------------------------------------------+--------------------------------------------------------+
-- | tel_contacto_emergencias | telefono_movil    | NOT NULL                                     | Teléfono del contacto de emergencia.                   |
-- +--------------------------+-------------------+----------------------------------------------+--------------------------------------------------------+
-- | ind_envio_correo         | BOOLEAN           | NOT NULL                                     | Indicador de autorización de enviar correos.           |
-- |                          |                   | DEFAULT TRUE                                 | TRUE=Enviarle correos / FALSE=No se le envían correos. |    
-- +--------------------------+-------------------+----------------------------------------------+--------------------------------------------------------+
-- | ind_estado               | BOOLEAN           | NOT NULL                                     | Indicador de estado de la persona.                     |
-- |                          |                   | DEFAULT TRUE                                 | TRUE=Activo / FALSE=Inactivo.                          |    
-- +--------------------------+-------------------+----------------------------------------------+--------------------------------------------------------+
-- | usr_insert               | VARCHAR(50)       | NOT NULL                                     | Usuario que creó el registro.                          |
-- |                          |                   | CHECK(LENGTH(TRIM(usr_insert)) >= 3)         |                                                        |
-- +--------------------------+-------------------+----------------------------------------------+--------------------------------------------------------+
-- | fec_insert               | TIMESTAMP         | NOT NULL                                     | Fecha/hora de creación del registro.                   |
-- |                          | WITHOUT TIME ZONE |                                              |                                                        |
-- +--------------------------+-------------------+----------------------------------------------+--------------------------------------------------------+
-- | usr_update               | VARCHAR(50)       | CHECK(LENGTH(TRIM(usr_update)) >= 3)         | Usuario que actualizó el registro.                     |
-- +--------------------------+-------------------+----------------------------------------------+--------------------------------------------------------+
-- | fec_update               | TIMESTAMP         |                                              | Fecha/hora de actualización del registro.              |
-- |                          | WITHOUT TIME ZONE |                                              |                                                        |
-- +--------------------------+-------------------+----------------------------------------------+--------------------------------------------------------+

CREATE TABLE IF NOT EXISTS tab_personas
(-- DATOS DE IDENTIFICACIÓN DE LA PERSONA (A VALIDAR CONTRA REGISTRADURÍA)
    id_persona                  DECIMAL(10,0)               NOT NULL,
    id_tipo_docum               VARCHAR(2)                  NOT NULL DEFAULT 'CC',
    id_tipo_persona             DECIMAL(2,0)                NOT NULL DEFAULT 1,
    nom_persona                 VARCHAR(40)                 NOT NULL CHECK(LENGTH(nom_persona) >= 3),
    ape_persona                 VARCHAR(30)                 NOT NULL CHECK(LENGTH(ape_persona) >= 2),
    mail_persona                mail_personal               NOT NULL DEFAULT 'Sin Correo',
    fec_nacimiento              DATE                        NOT NULL DEFAULT '1900-01-01',
    ind_genero                  DECIMAL(2,0)                NOT NULL DEFAULT 99,  -- 99=No definido
 -- DATOS BIOMÉTRICOS (SEGUARDAN UNA SOLA VEZ, PARA VALIDACIONES FUTURAS CADA VEZ QUE INGRESE)
    val_huella_digital          BYTEA,
    val_patron_facial           JSONB,
    fec_ultima_entrada          TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fec_ultima_salida           TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    num_visitas                 SMALLINT                    NOT NULL DEFAULT 0,
-- DATOS DE ESTUDIO
    id_nivel_estudio            DECIMAL(2,0)                NOT NULL DEFAULT 99, -- 99=Sin estudio
    id_profesion                VARCHAR                     NOT NULL DEFAULT '00',
-- DATOS GEOGRÁFICOS DE LA PERSONA
    id_dpto_reside              VARCHAR(2)                  NOT NULL DEFAULT '68', -- ID departamento de la ciudad
    id_ciudad_reside            VARCHAR(5)                  NOT NULL DEFAULT '68001', -- ID ciudad de residencia de la persona
    dir_ciudad_reside           VARCHAR(100)                NOT NULL CHECK(LENGTH(dir_ciudad_reside) >= 10) DEFAULT 'Sin Dirección',
    tel_persona_fijo            telefono_fijo               NOT NULL DEFAULT 6010000000,
    tel_persona_movil           telefono_movil              NOT NULL DEFAULT 3000000000,
    nom_contacto_emergencias    VARCHAR(60)                 NOT NULL CHECK(LENGTH(nom_contacto_emergencias) >= 5) DEFAULT 'Sin Contacto',
    tel_contacto_emergencias    telefono_movil              NOT NULL DEFAULT 3000000000,
    ind_envio_correo            BOOLEAN                     NOT NULL DEFAULT FALSE, -- TRUE=Enviarle correos / FALSE=No se le envían correos
    ind_estado                  BOOLEAN                     NOT NULL DEFAULT TRUE, -- TRUE=Activo / FALSE=Inactivo
    usr_insert                  VARCHAR(50)                 NOT NULL CHECK(LENGTH(TRIM(usr_insert)) >= 3),
    fec_insert                  TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update                  VARCHAR(50)                          CHECK(LENGTH(TRIM(usr_update)) >= 3),
    fec_update                  TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_persona),
    FOREIGN KEY(id_tipo_docum)      REFERENCES tab_tipos_docum(id_tipo_docum),
    FOREIGN KEY(id_tipo_persona)    REFERENCES tab_tipos_persona(id_tipo_persona),
    FOREIGN KEY(id_nivel_estudio)   REFERENCES tab_niveles_estudio(id_nivel_estudio),
    FOREIGN KEY(id_profesion)       REFERENCES tab_profesiones(id_profesion),
    FOREIGN KEY(id_dpto_reside)     REFERENCES tab_dptos(id_dpto),
    FOREIGN KEY(id_ciudad_reside)   REFERENCES tab_ciudades(id_ciudad)
);

CREATE TABLE IF NOT EXISTS log_migracion_aprendices (
    id_log         SERIAL PRIMARY KEY,
    fecha          TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    num_documento_original TEXT,
    motivo         TEXT,
    datos_fila     JSONB
);


-- ESTRUCTURA COMPOSITE PARA DATOS PERSONALES DE UN APRENDIZ
CREATE TYPE datos_personales_aprendiz AS
(
    tel_alterno                 telefono_movil,
    tel_sede                    telefono_fijo,
    ext_sede                    extension,
    tel_padre_fijo              telefono_fijo,
    tel_padre_movil             telefono_movil,
    val_mail_institucional      mail_personal,
    nom_contacto_emergencias    VARCHAR,
    tel_contacto_emergencias    DECIMAL(10,0)
);

--TABLA DE INSTRUCTORES

-- TABLA DE TAB_INSTRUCTORES
-- __________________________________________________________________________________________________________________________________________________________________________
-- |        Columna        |      Tipo         |                    Restricción                            |                            Descripción                          |
-- +-----------------------+-------------------+-----------------------------------------------------------+-----------------------------------------------------------------+
-- | id_instructor         | DECIMAL(10,0)     | PRIMARY KEY                                               | Número identificador del instructor.                            |
-- |                       |                   | NOT NULL                                                  |                                                                 |
-- |                       |                   | CHECK(id_instructor > 20000000)                           |                                                                 |
-- +-----------------------+-------------------+-----------------------------------------------------------+-----------------------------------------------------------------+
-- | id_centro             | DECIMAL(4,0)      | FOREIGN KEY                                               | Número identificador del centro.                                |
-- |                       |                   | NOT NULL                                                  |                                                                 |
-- +-----------------------+-------------------+-----------------------------------------------------------+-----------------------------------------------------------------+
-- | ind_tipo_contrato     | BOOLEAN           | NOT NULL                                                  | TRUE=Planta / FALSE=Contratista.                                |
-- |                       |                   |                                                           | Indicador del tipo de contrato.                                 |
-- +-----------------------+-------------------+-----------------------------------------------------------+-----------------------------------------------------------------+
-- | ind_contratado_actual | BOOLEAN           | NOT NULL                                                  | Indicador del estado de contratación.                           |
-- |                       |                   |                                                           | TRUE=Contratado actualmente / FALSE=No Contratado.              |
-- +-----------------------+-------------------+-----------------------------------------------------------+-----------------------------------------------------------------+
-- | ind_genero            | DECIMAL(1,0)      | NOT NULL                                                  | Indicador del género.                                           |
-- |                       |                   | CHECK(ind_genero = 1 OR ind_genero = 2 OR ind_genero = 4) | 1=Femenino,2=Masculino,3=No binario,4=Trans.                    |
-- +-----------------------+-------------------+-----------------------------------------------------------+-----------------------------------------------------------------+
-- | ind_est_civil         | DECIMAL(1,0)      | NOT NULL                                                  | Indicador del estado civil.                                     |
-- |                       |                   | CHECK(ind_est_civil >= 0 AND ind_est_civil <=9)           | 1=Casado 2=Soltero 3=Unión Libre, 4=Viudo, 5=Divorciado, 0=Otro |
-- +-----------------------+-------------------+-----------------------------------------------------------+-----------------------------------------------------------------+
-- | id_nivel_estudio      | DECIMAL(2,0)      | FOREIGN KEY                                               | Número identificador del nivel de estudio.                      |
-- |                       |                   | NOT NULL                                                  |                                                                 |
-- +-----------------------+-------------------+-----------------------------------------------------------+-----------------------------------------------------------------+
-- | id_profesion          | VARCHAR           | FOREIGN KEY                                               | Número identificador de la profesión.                           |
-- |                       |                   | NOT NULL                                                  |                                                                 |
-- +-----------------------+-------------------+-----------------------------------------------------------+-----------------------------------------------------------------+
-- | id_red                | DECIMAL(2,0)      | FOREIGN KEY                                               | Número identificador de la red.                                 |
-- |                       |                   | NOT NULL                                                  |                                                                 |
-- +-----------------------+-------------------+-----------------------------------------------------------+-----------------------------------------------------------------+
-- | ind_disponibilidad    | BOOLEAN           | NOT NULL                                                  | Indicador de disponibilidad del instructor.                     |
-- |                       |                   | DEFAULT TRUE                                              | TRUE=Disponible / FALSE=No Disponible                           |
-- +-----------------------+-------------------+-----------------------------------------------------------+-----------------------------------------------------------------+
-- | ind_estado            | DECIMAL(1,0)      | NOT NULL                                                  | Indicador de estado del instructor.                             |
-- |                       |                   | CHECK(ind_estado >= 0 AND ind_estado <= 9)                | 0=Activo,2=Suspendido,3=Bloqueado,9=Inactivo                    |
-- +-----------------------+-------------------+-----------------------------------------------------------+-----------------------------------------------------------------+
-- | usr_insert            | VARCHAR(50)       | NOT NULL                                                  | Usuario que creó el registro.                                   |
-- |                       |                   | CHECK(LENGTH(TRIM(usr_insert)) >= 3)                      |                                                                 |
-- +-----------------------+-------------------+-----------------------------------------------------------+-----------------------------------------------------------------+
-- | fec_insert            | TIMESTAMP         | NOT NULL                                                  | Fecha/hora de creación del registro.                            |
-- |                       | WITHOUT TIME ZONE |                                                           |                                                                 |
-- +-----------------------+-------------------+-----------------------------------------------------------+-----------------------------------------------------------------+
-- | usr_update            | VARCHAR(50)       | CHECK(LENGTH(TRIM(usr_update)) >= 3)                      | Usuario que actualizó el registro.                              |
-- +-----------------------+-------------------+-----------------------------------------------------------+-----------------------------------------------------------------+
-- | fec_update            | TIMESTAMP         |                                                           | Fecha/hora de actualización del registro.                       |
-- +-----------------------+-------------------+-----------------------------------------------------------+-----------------------------------------------------------------+

CREATE TABLE IF NOT EXISTS tab_instructores
(
    id_instructor           DECIMAL(10,0)               NOT NULL CHECK(id_instructor > 20000000),
    id_centro               DECIMAL(4,0)                NOT NULL,
    ind_tipo_contrato       BOOLEAN                     NOT NULL, --TRUE=Planta / FALSE=Contratista. Si es contratista, se debe consultar el vigente en la tabla tab_contratos_instructor
    ind_contratado_actual   BOOLEAN                     NOT NULL, --TRUE=Contratado actualmente / FALSE=No Contratado. Si está contratado debe consultarse el contrato en la tabla hija
    ind_genero              DECIMAL(1,0)                NOT NULL CHECK(ind_genero = 1 OR ind_genero = 2 OR ind_genero = 4), --1=Femenino,2=Masculino,3=No binario,4=Trans
    ind_est_civil           DECIMAL(1,0)                NOT NULL CHECK(ind_est_civil >= 0 AND ind_est_civil <=9),--1=Casado 2=Soltero 3=Unión Libre', 3=Viudo, 4=Divorciado, 0=Otro
    id_nivel_estudio        DECIMAL(2,0)                NOT NULL,
    id_profesion            VARCHAR                     NOT NULL,
    id_red                  DECIMAL(2,0)                NOT NULL,
    ind_disponibilidad      BOOLEAN                     NOT NULL DEFAULT TRUE, -- TRUE=Disponible / FALSE=No Disponible (Ocupado con tiempo completo)
    ind_estado              DECIMAL(1,0)                NOT NULL CHECK(ind_estado >= 0 AND ind_estado <= 9), -- 0=Activo,2=Suspendido,3=Bloqueado,9=Inactivo;
    usr_insert              VARCHAR(50)                 NOT NULL CHECK(LENGTH(TRIM(usr_insert)) >= 3),
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR(50)                          CHECK(LENGTH(TRIM(usr_update)) >= 3),
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_instructor),
    FOREIGN KEY(id_centro)        REFERENCES tab_centros(id_centro),
    FOREIGN KEY(id_nivel_estudio) REFERENCES tab_niveles_estudio(id_nivel_estudio),
    FOREIGN KEY(id_profesion)     REFERENCES tab_profesiones(id_profesion),
    FOREIGN KEY(id_red)           REFERENCES tab_redes(id_red)
);

-- Tabla de contratos que tiene un instructor. No aplica para instructores con tipo contrato TRUE en tabla de Instructores (Planta).
-- Si ind_adicion de esta tabla es = TRUE, se debe consultar la tabla dependiente esta tabla para seleccionar los datos de la adición.

-- TABLA DE TAB_CONTRATOS_INSTRUCTOR
-- __________________________________________________________________________________________________________________________
-- |    Columna    |       Tipo        |             Restricción              |                    Descripción               |
-- +---------------+-------------------+--------------------------------------+----------------------------------------------+
-- | id_instructor | DECIMAL(10,0)     | PRIMARY KEY                          | Número identificador del instructor.         |
-- |               |                   | NOT NULL                             |                                              |
-- +---------------+-------------------+--------------------------------------+----------------------------------------------+
-- | num_contrato  | VARCHAR           | PRIMARY KEY                          | Número del contrato.                         |
-- |               |                   | NOT NULL                             |                                              |
-- +---------------+-------------------+--------------------------------------+----------------------------------------------+
-- | year_contrato | DECIMAL(4,0)      |                                      | Año del contrato.                            |
-- +---------------+-------------------+--------------------------------------+----------------------------------------------+
-- | fec_inicio    | DATE              | NOT NULL                             | Fecha de inicio del contrato.                |
-- +---------------+-------------------+--------------------------------------+----------------------------------------------+
-- | fec_fin       | DATE              | NOT NULL                             | Fecha de finalización del contrato.          |
-- +---------------+-------------------+--------------------------------------+----------------------------------------------+
-- | ind_vigente   | BOOLEAN           | NOT NULL DEFAULT TRUE                | Estado de vigencia del contrato.             |
-- |               |                   |                                      | TRUE=Vigente, FALSE=Ejecutado.               |
-- +---------------+-------------------+--------------------------------------+----------------------------------------------+
-- | ind_adicion   | BOOLEAN           | NOT NULL DEFAULT FALSE               | Indicador de adición al contrato.            |
-- |               |                   |                                      | TRUE=Tiene adición, FALSE=No tiene adición.  |
-- +---------------+-------------------+--------------------------------------+----------------------------------------------+
-- | usr_insert    | VARCHAR(50)       | NOT NULL                             | Usuario que creó el registro.                |
-- |               |                   | CHECK(LENGTH(TRIM(usr_insert)) >= 3) |                                              |
-- +---------------+-------------------+--------------------------------------+----------------------------------------------+
-- | fec_insert    | TIMESTAMP         | NOT NULL                             | Fecha/hora de creación del registro.         |
-- |               | WITHOUT TIME ZONE |                                      |                                              |
-- +---------------+-------------------+--------------------------------------+----------------------------------------------+
-- | usr_update    | VARCHAR(50)       | CHECK(LENGTH(TRIM(usr_update)) >= 3) | Usuario que actualizó el registro.           |
-- +---------------+-------------------+--------------------------------------+----------------------------------------------+
-- | fec_update    | TIMESTAMP         |                                      | Fecha/hora de actualización del registro.    |
-- |               | WITHOUT TIME ZONE |                                      |                                              |
-- +---------------+-------------------+--------------------------------------+----------------------------------------------+

CREATE TABLE IF NOT EXISTS tab_contratos_instructor
(
    id_instructor           DECIMAL(10,0)               NOT NULL,
    num_contrato            VARCHAR                     NOT NULL,
    year_contrato           DECIMAL(4,0),
    fec_inicio              DATE                        NOT NULL,
    fec_fin                 DATE                        NOT NULL,
    ind_vigente             BOOLEAN                     NOT NULL DEFAULT TRUE, --TRUE=Vigente / FALSE=Ejecutado. Una vez concluya el contrato debe pasar a FALSE
    ind_adicion             BOOLEAN                     NOT NULL DEFAULT FALSE, -- TRUE=Tiene adición / FALSE=No tiene adición
    usr_insert              VARCHAR(50)                 NOT NULL CHECK(LENGTH(TRIM(usr_insert)) >= 3),
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR(50)                          CHECK(LENGTH(TRIM(usr_update)) >= 3),
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_instructor,num_contrato)
);

-- TABLA DE FUNCIONARIOS DE CENTRO

-- TABLA DE TAB_FUNCIONARIOS
-- _______________________________________________________________________________________________________________________________
-- |       Columna         |       Tipo        |              Restricción             |                  Descripción              |
-- +-----------------------+-------------------+-----------------------------------------------+----------------------------------+
-- | id_funcionario        | DECIMAL(10,0)     | PRIMARY KEY                          | Número identificador del funcionario.     |
-- |                       |                   | PRIMARY KEY                          |                                           |
-- |                       |                   | NOT NULL                             |                                           |
-- +-----------------------+-------------------+--------------------------------------+-------------------------------------------+
-- | id_area               | DECIMAL(2,0)      | NOT NULL                             | Número identificador del área.            |
-- |                       |                   | FOREIGN KEY                          |                                           |
-- +-----------------------+-------------------+--------------------------------------+-------------------------------------------+
-- | id_cargo              | DECIMAL(2,0)      | NOT NULL                             | Número identificador del cargo.           |
-- |                       |                   | FOREIGN KEY                          |                                           |
-- +-----------------------+-------------------+--------------------------------------+-------------------------------------------+
-- | val_grado             | VARCHAR           | NOT NULL                             | Grado asignado al funcionario.            |
-- +-----------------------+-------------------+--------------------------------------+-------------------------------------------+
-- | id_fec_ingreso_planta | DATE              | NOT NULL                             | Fecha de ingreso a planta.                |
-- +-----------------------+-------------------+--------------------------------------+-------------------------------------------+
-- | usr_insert            | VARCHAR(50)       | NOT NULL                             | Usuario que creó el registro.             |
-- |                       |                   | CHECK(LENGTH(TRIM(usr_insert)) >= 3) |                                           |
-- +-----------------------+-------------------+--------------------------------------+-------------------------------------------+
-- | fec_insert            | TIMESTAMP         | NOT NULL                             | Fecha/hora de creación del registro.      |
-- |                       | WITHOUT TIME ZONE |                                      |                                           |
-- +-----------------------+-------------------+--------------------------------------+-------------------------------------------+
-- | usr_update            | VARCHAR(50)       | CHECK(LENGTH(TRIM(usr_update)) >= 3) | Usuario que actualizó el registro.        |
-- +-----------------------+-------------------+--------------------------------------+-------------------------------------------+
-- | fec_update            | TIMESTAMP         |                                      | Fecha/hora de actualización del registro. |
-- |                       | WITHOUT TIME ZONE |                                      |                                           |
-- +-----------------------+-------------------+--------------------------------------+-------------------------------------------+

CREATE TABLE IF NOT EXISTS tab_funcionarios
(
    id_funcionario          DECIMAL(10,0)               NOT NULL,
    id_area                 DECIMAL(2,0)                NOT NULL,
    id_cargo                DECIMAL(2,0)                NOT NULL,
    val_grado               VARCHAR                     NOT NULL,
    id_fec_ingreso_planta   DATE                        NOT NULL,
    usr_insert              VARCHAR(50)                 NOT NULL CHECK(LENGTH(TRIM(usr_insert)) >= 3),
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR(50)                          CHECK(LENGTH(TRIM(usr_update)) >= 3),
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_funcionario),
    FOREIGN KEY(id_funcionario) REFERENCES tab_personas(id_persona),
    FOREIGN KEY(id_area)        REFERENCES tab_areas(id_area),
    FOREIGN KEY(id_cargo)       REFERENCES tab_cargos(id_cargo)
);

-- Tabla de adiciones del contrato. Si el ind_adicion en tab_contratos_instructores es TRUE,
-- Se deben sacar los datos de la adición de esta tabla. Pueden haber hasta 2 adiciones.

-- TABLA DE TAB_ADICION_CONTRATOS
-- _______________________________________________________________________________________________________________________________________________
-- |     Columna      |            Tipo             |               Restricción                    |                 Descripción                  |
-- +------------------+-----------------------------+----------------------------------------------+----------------------------------------------+
-- | id_instructor    | DECIMAL(10,0)               | FOREIGN KEY                                  | Número identificador del instructor.         |
-- |                  |                             | NOT NULL                                     |                                              |
-- +------------------+-----------------------------+----------------------------------------------+----------------------------------------------+
-- | num_contrato     | VARCHAR                     | PRIMARY KEY                                  | Número del contrato.                         |
-- |                  |                             | NOT NULL                                     |                                              |
-- +------------------+-----------------------------+----------------------------------------------+----------------------------------------------+
-- | num_adicion      | DECIMAL(1,0)                | PRIMARY KEY                                  | Número de la adición del contrato.           |
-- |                  |                             | NOT NULL                                     |                                              |
-- |                  |                             | CHECK(num_adicion >= 0 AND num_adicion <= 3) |                                              |
-- +------------------+-----------------------------+----------------------------------------------+----------------------------------------------+
-- | fec_ini_adicion  | DATE                        | NOT NULL                                     | Fecha de inicio de la adición.               |
-- +------------------+-----------------------------+----------------------------------------------+----------------------------------------------+
-- | fec_fin_adicion  | DATE                        | NOT NULL                                     | Fecha de finalización de la adición.         |
-- +------------------+-----------------------------+----------------------------------------------+----------------------------------------------+
-- | usr_insert       | VARCHAR(50)                 | NOT NULL                                     | Usuario que creó el registro.                |
-- |                  |                             | CHECK(LENGTH(TRIM(usr_insert)) >= 3)         |                                              |
-- +------------------+-----------------------------+----------------------------------------------+----------------------------------------------+
-- | fec_insert       | TIMESTAMP                   | NOT NULL                                     | Fecha/hora de creación del registro.         |
-- |                  | WITHOUT TIME ZONE           |                                              |                                              |
-- +------------------+-----------------------------+----------------------------------------------+----------------------------------------------+
-- | usr_update       | VARCHAR(50)                 | CHECK(LENGTH(TRIM(usr_update)) >= 3)         | Usuario que actualizó el registro.           |
-- +------------------+-----------------------------+----------------------------------------------+----------------------------------------------+
-- | fec_update       | TIMESTAMP                   |                                              | Fecha/hora de actualización del registro.    |
-- |                  | WITHOUT TIME ZONE           |                                              |                                              |
-- +------------------+-----------------------------+----------------------------------------------+----------------------------------------------+

CREATE TABLE IF NOT EXISTS tab_adicion_contratos
(
    id_instructor           DECIMAL(10,0)               NOT NULL,
    num_contrato            VARCHAR                     NOT NULL,
    num_adicion             DECIMAL(1,0)                NOT NULL CHECK(num_adicion >= 0 AND num_adicion <=3),
    fec_ini_adicion         DATE                        NOT NULL,
    fec_fin_adicion         DATE                        NOT NULL,
    usr_insert              VARCHAR(50)                 NOT NULL CHECK(LENGTH(TRIM(usr_insert)) >= 3),
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR(50)                          CHECK(LENGTH(TRIM(usr_update)) >= 3),
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(num_contrato,num_adicion),
    FOREIGN KEY(id_instructor,num_contrato) REFERENCES tab_contratos_instructor(id_instructor,num_contrato)
);

-- Tabla de horas trabajadas por mes para un instructor

-- TABLA DE TAB_HORAS_INSTRUCTOR
-- ______________________________________________________________________________________________________________________________
-- |        Columna        |       Tipo       |             Restricción              |                Descripción                |
-- +----------------------+-------------------+--------------------------------------+-------------------------------------------+
-- | id_instructor        | DECIMAL(10,0)     | PRIMARY KEY                          | Número identificador del instructor.      |
-- |                      |                   | FOREIGN KEY                          |                                           |
-- |                      |                   | NOT NULL                             |                                           |
-- +----------------------+-------------------+--------------------------------------+-------------------------------------------+
-- | id_mes               | DECIMAL(2,0)      | PRIMARY KEY                          | Número del mes.                           |
-- |                      |                   | NOT NULL                             | Valores permitidos del 1 al 12.           |
-- +----------------------+-------------------+--------------------------------------+-------------------------------------------+
-- | val_horas_form_mes   | DECIMAL(4,0)      | NOT NULL                             | Cantidad de horas de formación del mes.   |
-- +----------------------+-------------------+--------------------------------------+-------------------------------------------+
-- | val_horas_apoyo_mes  | DECIMAL(4,0)      | NOT NULL                             | Horas ejecutadas en apoyo del mes.        |
-- +----------------------+-------------------+--------------------------------------+-------------------------------------------+
-- | val_horas_invest_mes | DECIMAL(4,0)      | NOT NULL                             | Horas ejecutadas en investigación.        |
-- +----------------------+-------------------+--------------------------------------+-------------------------------------------+
-- | val_horas_acum       | DECIMAL(3,0)      | NOT NULL                             | Cantidad de horas acumuladas.             |
-- +----------------------+-------------------+--------------------------------------+-------------------------------------------+
-- | usr_insert           | VARCHAR           | NOT NULL                             | Usuario que creó el registro.             |
-- |                      |                   | CHECK(LENGTH(TRIM(usr_insert)) >= 3) |                                           |
-- +----------------------+-------------------+--------------------------------------+-------------------------------------------+
-- | fec_insert           | TIMESTAMP         | NOT NULL                             | Fecha/hora de creación del registro.      |
-- |                      | WITHOUT TIME ZONE |                                      |                                           |
-- +----------------------+-------------------+--------------------------------------+-------------------------------------------+
-- | usr_update           | VARCHAR           | CHECK(LENGTH(TRIM(usr_update)) >= 3) | Usuario que actualizó el registro.        |
-- +----------------------+-------------------+--------------------------------------+-------------------------------------------+
-- | fec_update           | TIMESTAMP         |                                      | Fecha/hora de actualización del registro. |
-- |                      | WITHOUT TIME ZONE |                                      |                                           |
-- +----------------------+-------------------+--------------------------------------+-------------------------------------------+

CREATE TABLE IF NOT EXISTS tab_horas_instructor
(
    id_instructor           DECIMAL(10,0)               NOT NULL,
    id_mes                  DECIMAL(2,0)                NOT NULL,   -- Meses del 1 al 12
    val_horas_form_mes      DECIMAL(4,0)                NOT NULL,   -- Cantidad de horas del mes vigente
    val_horas_apoyo_mes     DECIMAL(4,0)                NOT NULL,   -- Horas ejecutadas en apoyo
    val_horas_invest_mes    DECIMAL(4,0)                NOT NULL,   -- Horas ejecutadas en Investigación
    val_horas_acum          DECIMAL(3,0)                NOT NULL,   -- Cantidad de horas acumuladas hasta el mes vigente
    usr_insert              VARCHAR                     NOT NULL CHECK(LENGTH(TRIM(usr_insert)) >= 3),
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR                              CHECK(LENGTH(TRIM(usr_update)) >= 3),
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_instructor,id_mes),
    FOREIGN KEY(id_instructor) REFERENCES tab_instructores(id_instructor)
);

-- TABLA DE CERTIFICADOS LABORALES PARA INSTRUCTORES

-- TABLA DE TAB_CERTIFICADOS
-- ____________________________________________________________________________________________________________________________
-- |     Columna     |       Tipo        |             Restricción              |                Descripción                   |
-- +-----------------+-------------------+--------------------------------------+----------------------------------------------+
-- | id_consecutivo  | DECIMAL(2,0)      | PRIMARY KEY                          | Número consecutivo del certificado.          |
-- |                 |                   | NOT NULL                             |                                              |
-- +-----------------+-------------------+--------------------------------------+----------------------------------------------+
-- | fec_certificado | DATE              | NOT NULL                             | Fecha de emisión del certificado.            |
-- +-----------------+-------------------+--------------------------------------+----------------------------------------------+
-- | id_instructor   | DECIMAL(10,0)     | FOREIGN KEY                          | Número identificador del instructor.         |
-- |                 |                   | NOT NULL                             |                                              |
-- +-----------------+-------------------+--------------------------------------+----------------------------------------------+
-- | usr_insert      | VARCHAR(50)       | NOT NULL                             | Usuario que creó el registro.                |
-- |                 |                   | CHECK(LENGTH(TRIM(usr_insert)) >= 3) |                                              |
-- +-----------------+-------------------+--------------------------------------+----------------------------------------------+
-- | fec_insert      | TIMESTAMP         | NOT NULL                             | Fecha/hora de creación del registro.         |
-- |                 | WITHOUT TIME ZONE |                                      |                                              |
-- +-----------------+-------------------+--------------------------------------+----------------------------------------------+
-- | usr_update      | VARCHAR(50)       | CHECK(LENGTH(TRIM(usr_update)) >= 3) | Usuario que actualizó el registro.           |
-- +-----------------+-------------------+--------------------------------------+----------------------------------------------+
-- | fec_update      | TIMESTAMP         |                                      | Fecha/hora de actualización del registro.    |
-- |                 | WITHOUT TIME ZONE |                                      |                                              |
-- +-----------------+-------------------+--------------------------------------+----------------------------------------------+

CREATE TABLE IF NOT EXISTS tab_certificados
(
    id_consecutivo          DECIMAL(2,0)                NOT NULL,
    fec_certificado         DATE                        NOT NULL,
    id_instructor           DECIMAL(10,0)               NOT NULL,
    usr_insert              VARCHAR(50)                 NOT NULL CHECK(LENGTH(TRIM(usr_insert)) >= 3),
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR(50)                          CHECK(LENGTH(TRIM(usr_update)) >= 3),
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_consecutivo),
    FOREIGN KEY(id_instructor) REFERENCES tab_instructores(id_instructor)
);

-- *******************************************************
-- TABLAS PARA INFORMACIÓN DE LOS PROGRAMAS DE FORMACIÓN *
-- *******************************************************
-- Tabla de Programas de Formación SENA

-- TABLA DE TAB_PROGRAMAS
-- ____________________________________________________________________________________________________________________________________________________________
-- |       Columna         |       Tipo        |              Restricción             | Descripción                                                            |
-- +-----------------------+-------------------+--------------------------------------+------------------------------------------------------------------------+
-- | id_programa           | DECIMAL(8,0)      | PRIMARY KEY                          | Número identificador del programa.                                     |
-- |                       |                   | NOT NULL                             |                                                                        |
-- +-----------------------+-------------------+--------------------------------------+------------------------------------------------------------------------+
-- | nom_programa          | VARCHAR(100)      | NOT NULL                             | Nombre del programa.                                                   |
-- |                       |                   | CHECK(LENGTH(nom_programa) >= 5)     |                                                                        |
-- +-----------------------+-------------------+--------------------------------------+------------------------------------------------------------------------+
-- | num_snies             | VARCHAR           | NOT NULL                             | Número SNIES del programa.                                             |
-- +-----------------------+-------------------+--------------------------------------+------------------------------------------------------------------------+
-- | num_version           | DECIMAL(2,0)      | NOT NULL                             | Número de versión del programa.                                        |
-- +-----------------------+-------------------+--------------------------------------+------------------------------------------------------------------------+
-- | ind_tipo              | VARCHAR           | NOT NULL                             | Tipo de programa de formación.                                         |
-- |                       |                   |                                      | 1=Tecnología, 2=Técnica, 3=Especialización, 4=Complementaria, 5=Curso. |
-- +-----------------------+-------------------+--------------------------------------+------------------------------------------------------------------------+
-- | val_duracion_lect_hrs | DECIMAL(4,0)      | NOT NULL                             | Duración lectiva en horas.                                             |
-- +-----------------------+-------------------+--------------------------------------+------------------------------------------------------------------------+
-- | val_duracion_prod_hrs | DECIMAL(4,0)      | NOT NULL                             | Duración productiva en horas.                                          |
-- +-----------------------+-------------------+--------------------------------------+------------------------------------------------------------------------+
-- | val_duracion_lect_mes | DECIMAL(2,0)      | NOT NULL                             | Duración lectiva en meses.                                             |
-- +-----------------------+-------------------+--------------------------------------+------------------------------------------------------------------------+
-- | val_duracion_prod_me  | DECIMAL(2,0)      | NOT NULL                             | Duración productiva en meses.                                          |
-- +-----------------------+-------------------+--------------------------------------+------------------------------------------------------------------------+
-- | usr_insert            | VARCHAR(50)       | NOT NULL                             | Usuario que creó el registro.                                          |
-- |                       |                   | CHECK(LENGTH(TRIM(usr_insert)) >= 3) |                                                                        |
-- +-----------------------+-------------------+--------------------------------------+------------------------------------------------------------------------+
-- | fec_insert            | TIMESTAMP         | NOT NULL                             | Fecha/hora de creación del registro.                                   |
-- |                       | WITHOUT TIME ZONE |                                      |                                                                        |
-- +-----------------------+-------------------+--------------------------------------+------------------------------------------------------------------------+
-- | usr_update            | VARCHAR(50)       | CHECK(LENGTH(TRIM(usr_update)) >= 3) | Usuario que actualizó el registro.                                     |
-- +-----------------------+-------------------+--------------------------------------+------------------------------------------------------------------------+
-- | fec_update            | TIMESTAMP         |                                      | Fecha/hora de actualización del registro.                              |
-- |                       | WITHOUT TIME ZONE |                                      |                                                                        |
-- +-----------------------+-------------------+--------------------------------------+------------------------------------------------------------------------+
CREATE TABLE IF NOT EXISTS tab_programas
(
    id_programa             DECIMAL(8,0)                NOT NULL,
    nom_programa            VARCHAR(100)                NOT NULL CHECK(LENGTH(nom_programa) >= 5),
    num_snies               VARCHAR                     NOT NULL,
    num_version             DECIMAL(2,0)                NOT NULL,
    ind_tipo                VARCHAR    		            NOT NULL, -- 1=Auxiliar (AX) / 2=Operario (OE) / 3= Ocupación/Oficio (OC) / 4=Técnica (TN) / 5=Tecnología (TO) / 6=Especialización Tecnológica (EG)
    val_duracion_lect_hrs   DECIMAL(4,0)                NOT NULL,
    val_duracion_prod_hrs   DECIMAL(4,0)                NOT NULL,
    val_duracion_lect_mes   DECIMAL(2,0)                NOT NULL,
    val_duracion_prod_mes   DECIMAL(2,0)                NOT NULL,
    usr_insert              VARCHAR(50)                 NOT NULL CHECK(LENGTH(TRIM(usr_insert)) >= 3),
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR(50)                          CHECK(LENGTH(TRIM(usr_update)) >= 3),
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_programa)
);

-- Tabla de competencias para un proyecto y un programa

-- TABLA DE TAB_COMPETENCIAS
-- ____________________________________________________________________________________________________________________________
-- |    Columna      |       Tipo        |             Restricción              |                  Descripción                 |
-- +-----------------+-------------------+--------------------------------------+----------------------------------------------+
-- | id_competencia  | DECIMAL(10,0)     | PRIMARY KEY                          | Número identificador de la competencia.      |
-- |                 |                   | NOT NULL                             |                                              |
-- +-----------------+-------------------+--------------------------------------+----------------------------------------------+
-- | nom_competencia | TEXT              | NOT NULL                             | Nombre de la competencia.                    |
-- |                 |                   | CHECK(LENGTH(nom_competencia) >= 5)  |                                              |
-- +-----------------+-------------------+--------------------------------------+----------------------------------------------+
-- | num_raps        | DECIMAL(2,0)      | NOT NULL                             | Cantidad de RAPS asociados.                  |
-- +-----------------+-------------------+--------------------------------------+----------------------------------------------+
-- | num_horas       | DECIMAL(4,0)      | NOT NULL                             | Cantidad total de horas de la competencia.   |
-- +-----------------+-------------------+--------------------------------------+----------------------------------------------+
-- | ind_transversal | BOOLEAN           | NOT NULL                             | Tipo de competencia.                         |
-- |                 |                   | DEFAULT FALSE                        | TRUE=Es transversal, FALSE=Es técnica.       |
-- +-----------------+-------------------+--------------------------------------+----------------------------------------------+
-- | usr_insert      | VARCHAR(50)       | NOT NULL                             | Usuario que creó el registro.                |
-- |                 |                   | CHECK(LENGTH(TRIM(usr_insert)) >= 3) |                                              |
-- +-----------------+-------------------+--------------------------------------+----------------------------------------------+
-- | fec_insert      | TIMESTAMP         | NOT NULL                             | Fecha/hora de creación del registro.         |
-- |                 | WITHOUT TIME ZONE |                                      |                                              |
-- +-----------------+-------------------+--------------------------------------+----------------------------------------------+
-- | usr_update      | VARCHAR(50)       | CHECK(LENGTH(TRIM(usr_update)) >= 3) | Usuario que actualizó el registro.           |
-- +-----------------+-------------------+--------------------------------------+----------------------------------------------+
-- | fec_update      | TIMESTAMP         |                                      | Fecha/hora de actualización del registro.    |
-- |                 | WITHOUT TIME ZONE |                                      |                                              |
-- +-----------------+-------------------+--------------------------------------+----------------------------------------------+

CREATE TABLE IF NOT EXISTS tab_competencias
(
    id_competencia          DECIMAL(10,0)               NOT NULL,
    nom_competencia         TEXT                        NOT NULL CHECK(LENGTH(nom_competencia) >= 5),
    num_raps                DECIMAL(2,0)                NOT NULL,
    num_horas               DECIMAL(4,0)                NOT NULL,
    ind_transversal         BOOLEAN                     NOT NULL DEFAULT FALSE, -- TRUE=Es transversal / FALSE=Es técnica
    usr_insert              VARCHAR(50)                 NOT NULL CHECK(LENGTH(TRIM(usr_insert)) >= 3),
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR(50)                          CHECK(LENGTH(TRIM(usr_update)) >= 3),
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_competencia)
);

-- Tabla de competencias por instructor. La idea es que el Instructor oriente competencias en las que sea experto y que el sistema detecte esto en esta tabla antes de programarlo.

-- TABLA DE TAB_COMPET_INSTRUCTOR
-- ___________________________________________________________________________________________________________________________
-- | Columna        | Tipo              | Restricción                          | Descripción                                  |
-- +--------------- +-------------------+--------------------------------------+----------------------------------------------+
-- | id_instructor  | DECIMAL(10,0)     | PRIMARY KEY                          | Número identificador del instructor.         |
-- |                |                   | NOT NULL                             |                                              |
-- |                |                   | FOREIGN KEY                          |                                              |
-- +--------------- +-------------------+--------------------------------------+----------------------------------------------+
-- | id_competencia | DECIMAL(10,0)     | PRIMARY KEY                          | Número identificador de la competencia.      |
-- |                |                   | NOT NULL                             |                                              |
-- |                |                   | FOREIGN KEY                          |                                              |
-- +--------------- +-------------------+--------------------------------------+----------------------------------------------+
-- | usr_insert     | VARCHAR(50)       | NOT NULL                             | Usuario que creó el registro.                |
-- |                |                   | CHECK(LENGTH(TRIM(usr_insert)) >= 3) |                                              |
-- +--------------- +-------------------+--------------------------------------+----------------------------------------------+
-- | fec_insert     | TIMESTAMP         | NOT NULL                             | Fecha/hora de creación del registro.         |
-- |                | WITHOUT TIME ZONE |                                      |                                              |
-- +--------------- +-------------------+--------------------------------------+----------------------------------------------+
-- | usr_update     | VARCHAR(50)       | CHECK(LENGTH(TRIM(usr_update)) >= 3) | Usuario que actualizó el registro.           |
-- +--------------- +-------------------+--------------------------------------+----------------------------------------------+
-- | fec_update     | TIMESTAMP         |                                      | Fecha/hora de actualización del registro.    |
-- |                | WITHOUT TIME ZONE |                                      |                                              |
-- +--------------- +-------------------+--------------------------------------+----------------------------------------------+

CREATE TABLE IF NOT EXISTS tab_compet_instructor
(
    id_instructor           DECIMAL(10,0)               NOT NULL,
    id_competencia          DECIMAL(10,0)               NOT NULL,
    usr_insert              VARCHAR(50)                 NOT NULL CHECK(LENGTH(TRIM(usr_insert)) >= 3),
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR(50)                          CHECK(LENGTH(TRIM(usr_update)) >= 3),
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_instructor,id_competencia),
    FOREIGN KEY(id_instructor)          REFERENCES tab_instructores(id_instructor),
    FOREIGN KEY(id_competencia)         REFERENCES tab_competencias(id_competencia)
);

-- Tabla de Actividades de proyecto

-- TABLA DE TAB_ACTIV_PROYECTO
-- __________________________________________________________________________________________________________________________
-- | Columna       | Tipo              | Restricción                          | Descripción                                  |
-- +---------------+-------------------+--------------------------------------+----------------------------------------------+
-- | id_actividad  | DECIMAL(10,0)     | PRIMARY KEY                          | Número identificador de la actividad.        |
-- |               |                   | NOT NULL                             |                                              |
-- +---------------+-------------------+--------------------------------------+----------------------------------------------+
-- | nom_actividad | TEXT              | NOT NULL                             | Nombre de la actividad.                      |
-- |               |                   | CHECK(LENGTH(nom_actividad) >= 5)    |                                              |
-- +---------------+-------------------+--------------------------------------+----------------------------------------------+
-- | usr_insert    | VARCHAR(50)       | NOT NULL                             | Usuario que creó el registro.                |
-- |               |                   | CHECK(LENGTH(TRIM(usr_insert)) >= 3) |                                              |
-- +---------------+-------------------+--------------------------------------+----------------------------------------------+
-- | fec_insert    | TIMESTAMP         | NOT NULL                             | Fecha/hora de creación del registro.         |
-- |               | WITHOUT TIME ZONE |                                      |                                              |
-- +---------------+-------------------+--------------------------------------+----------------------------------------------+
-- | usr_update    | VARCHAR(50)       | CHECK(LENGTH(TRIM(usr_update)) >= 3) | Usuario que actualizó el registro.           |
-- +---------------+-------------------+--------------------------------------+----------------------------------------------+
-- | fec_update    | TIMESTAMP         |                                      | Fecha/hora de actualización del registro.    |
-- |               | WITHOUT TIME ZONE |                                      |                                              |
-- +---------------+-------------------+--------------------------------------+----------------------------------------------+

CREATE TABLE IF NOT EXISTS tab_activ_proyecto
(
    id_actividad            DECIMAL(10,0)               NOT NULL,
    nom_actividad           TEXT                        NOT NULL CHECK(LENGTH(nom_actividad) >= 5),
    usr_insert              VARCHAR(50)                 NOT NULL CHECK(LENGTH(TRIM(usr_insert)) >= 3),
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR(50)                          CHECK(LENGTH(TRIM(usr_update)) >= 3),
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
	PRIMARY KEY(id_actividad)
);

-- Tabla de RAP's

-- TABLA DE TAB_RAPS
-- ________________________________________________________________________________________________________________________
-- | Columna        | Tipo              | Restricción                          | Descripción                               |
-- +--------------- +-------------------+------------------------------------- +------------------------------------------ +
-- | id_rap         | DECIMAL(10,0)     | PRIMARY KEY                          | Número identificador del RAP.             |
-- |                |                   | NOT NULL                             |                                           |
-- +--------------- +-------------------+------------------------------------- +------------------------------------------ +
-- | nom_rap        | TEXT              | NOT NULL                             | Nombre del RAP.                           |
-- |                |                   | CHECK(LENGTH(nom_rap) >= 5)          |                                           |
-- +--------------- +-------------------+------------------------------------- +------------------------------------------ +
-- | id_competencia | DECIMAL(10,0)     | NOT NULL                             | Número identificador de la competencia.   |
-- |                |                   | FOREIGN KEY                          | Relacionado con                           |
-- |                |                   |                                      | tab_competencias(id_competencia).         |
-- +--------------- +-------------------+------------------------------------- +------------------------------------------ +
-- | usr_insert     | VARCHAR(50)       | NOT NULL                             | Usuario que creó el registro.             |
-- |                |                   | CHECK(LENGTH(TRIM(usr_insert)) >= 3) |                                           |
-- +--------------- +-------------------+------------------------------------- +------------------------------------------ +
-- | fec_insert     | TIMESTAMP         | NOT NULL                             | Fecha/hora de creación del registro.      |
-- |                | WITHOUT TIME ZONE |                                      |                                           |
-- +--------------- +-------------------+------------------------------------- +------------------------------------------ +
-- | usr_update     | VARCHAR(50)       | CHECK(LENGTH(TRIM(usr_update)) >= 3) | Usuario que actualizó el registro.        |
-- +--------------- +-------------------+------------------------------------- +------------------------------------------ +
-- | fec_update     | TIMESTAMP         |                                      | Fecha/hora de actualización del registro. |
-- |                | WITHOUT TIME ZONE |                                      |                                           |
-- +--------------- +-------------------+------------------------------------- +------------------------------------------ +

CREATE TABLE IF NOT EXISTS tab_raps
(
    id_rap                  DECIMAL(10,0)               NOT NULL,
    nom_rap                 TEXT                        NOT NULL CHECK(LENGTH(nom_rap) >= 5),
    id_competencia          DECIMAL(10,0)               NOT NULL,
    usr_insert              VARCHAR(50)                 NOT NULL CHECK(LENGTH(TRIM(usr_insert)) >= 3),
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR(50)                          CHECK(LENGTH(TRIM(usr_update)) >= 3),
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
	PRIMARY KEY(id_rap),
    FOREIGN KEY(id_competencia)             REFERENCES tab_competencias(id_competencia)
);

-- Tabla de evidencias aplicables a los RAP's

-- TABLA DE TAB_EVIDENCIAS
-- _________________________________________________________________________________________________________________________________________________
-- | Columna           | Tipo                        | Restricción                                   | Descripción                                  |
-- +-------------------+-----------------------------+-----------------------------------------------+----------------------------------------------+
-- | id_evidencia      | VARCHAR                     | PRIMARY KEY                                   | Número identificador de la evidencia.        |
-- |                   |                             | NOT NULL                                      |                                              |
-- +-------------------+-----------------------------+-----------------------------------------------+----------------------------------------------+
-- | nom_evidencia     | TEXT                        | NOT NULL                                      | Nombre de la evidencia.                      |
-- |                   |                             | CHECK(LENGTH(nom_evidencia) >= 5)             |                                              |
-- +-------------------+-----------------------------+-----------------------------------------------+----------------------------------------------+
-- | val_nota_maxima   | DECIMAL(3,0)                | NOT NULL                                      | Valor máximo permitido para la nota.         |
-- |                   |                             | CHECK(val_nota_maxima >= 0 AND                |                                              |
-- |                   |                             | val_nota_maxima <= 100)                       |                                              |
-- +-------------------+-----------------------------+-----------------------------------------------+----------------------------------------------+
-- | val_nota_minima   | DECIMAL(3,0)                | NOT NULL                                      | Valor mínimo permitido para la nota.         |
-- |                   |                             | CHECK(val_nota_minima >= 0 AND                |                                              |
-- |                   |                             | val_nota_minima <= 100)                       |                                              |
-- +-------------------+-----------------------------+-----------------------------------------------+----------------------------------------------+
-- | usr_insert        | VARCHAR(50)                 | NOT NULL                                      | Usuario que creó el registro.                |
-- |                   |                             | CHECK(LENGTH(TRIM(usr_insert)) >= 3)          |                                              |
-- +-------------------+-----------------------------+-----------------------------------------------+----------------------------------------------+
-- | fec_insert        | TIMESTAMP                   | NOT NULL                                      | Fecha/hora de creación del registro.         |
-- |                   | WITHOUT TIME ZONE           |                                               |                                              |
-- +-------------------+-----------------------------+-----------------------------------------------+----------------------------------------------+
-- | usr_update        | VARCHAR(50)                 | CHECK(LENGTH(TRIM(usr_update)) >= 3)          | Usuario que actualizó el registro.           |
-- +-------------------+-----------------------------+-----------------------------------------------+----------------------------------------------+
-- | fec_update        | TIMESTAMP                   |                                               | Fecha/hora de actualización del registro.    |
-- |                   | WITHOUT TIME ZONE           |                                               |                                              |
-- +-------------------+-----------------------------+-----------------------------------------------+----------------------------------------------+

CREATE TABLE IF NOT EXISTS tab_evidencias
(
    id_evidencia            VARCHAR                     NOT NULL,
    nom_evidencia           TEXT                        NOT NULL CHECK(LENGTH(nom_evidencia) >= 5),
    val_nota_maxima         DECIMAL(3,0)                NOT NULL CHECK(val_nota_maxima >= 0 AND val_nota_maxima <= 100),
    val_nota_minima         DECIMAL(3,0)                NOT NULL CHECK(val_nota_minima >= 0 AND val_nota_minima <= 100),
    usr_insert              VARCHAR(50)                 NOT NULL CHECK(LENGTH(TRIM(usr_insert)) >= 3),
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR(50)                          CHECK(LENGTH(TRIM(usr_update)) >= 3),
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_evidencia)
);

--Tabla de evidencias por RAP

-- TABLA DE TAB_EVIDENCIASXRAP
-- _________________________________________________________________________________________________________________________________________________
-- | Columna           | Tipo                        | Restricción                                   | Descripción                                  |
-- +-------------------+-----------------------------+-----------------------------------------------+----------------------------------------------+
-- | id_rap            | DECIMAL(10,0)               | PRIMARY KEY                                   | Número identificador del RAP.                |
-- |                   |                             | NOT NULL                                      |                                              |
-- |                   |                             | FOREIGN KEY                                   | Relacionado con tab_raps(id_rap).            |
-- +-------------------+-----------------------------+-----------------------------------------------+----------------------------------------------+
-- | id_evidencia      | VARCHAR                     | PRIMARY KEY                                   | Número identificador de la evidencia.        |
-- |                   |                             | NOT NULL                                      |                                              |
-- |                   |                             | FOREIGN KEY                                   | Relacionado con                              |
-- |                   |                             |                                               | tab_evidencias(id_evidencia).                |
-- +-------------------+-----------------------------+-----------------------------------------------+----------------------------------------------+
-- | usr_insert        | VARCHAR(50)                 | NOT NULL                                      | Usuario que creó el registro.                |
-- |                   |                             | CHECK(LENGTH(TRIM(usr_insert)) >= 3)          |                                              |
-- +-------------------+-----------------------------+-----------------------------------------------+----------------------------------------------+
-- | fec_insert        | TIMESTAMP                   | NOT NULL                                      | Fecha/hora de creación del registro.         |
-- |                   | WITHOUT TIME ZONE           |                                               |                                              |
-- +-------------------+-----------------------------+-----------------------------------------------+----------------------------------------------+
-- | usr_update        | VARCHAR(50)                 | CHECK(LENGTH(TRIM(usr_update)) >= 3)          | Usuario que actualizó el registro.           |
-- +-------------------+-----------------------------+-----------------------------------------------+----------------------------------------------+
-- | fec_update        | TIMESTAMP                   |                                               | Fecha/hora de actualización del registro.    |
-- |                   | WITHOUT TIME ZONE           |                                               |                                              |
-- +-------------------+-----------------------------+-----------------------------------------------+----------------------------------------------+

CREATE TABLE IF NOT EXISTS tab_evidenciasXrap
(
    id_rap                  DECIMAL(10,0)               NOT NULL,
    id_evidencia            VARCHAR                     NOT NULL,
    usr_insert              VARCHAR(50)                 NOT NULL CHECK(LENGTH(TRIM(usr_insert)) >= 3),
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR(50)                          CHECK(LENGTH(TRIM(usr_update)) >= 3),
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
	PRIMARY KEY(id_rap,id_evidencia),
	FOREIGN KEY(id_rap)			            REFERENCES tab_raps(id_rap),
	FOREIGN KEY(id_evidencia)	            REFERENCES tab_evidencias(id_evidencia)
);

-- Estructura de tabla de Raps por Competencia y Aprendiz

-- TABLA DE TAB_JUICIOS_EVAL
-- __________________________________________________________________________________________________________________________
-- |   Columna    | Tipo             | Restricción                            | Descripción                                   |
-- +--------------+-------------------+--------------------------------------+---------------------------------------------+
-- | id_aprendiz  | DECIMAL(10,0)     | PRIMARY KEY                             |                                               |
-- |              |                   | NOT NULL                                |                                              |
-- +--------------+-------------------+--------------------------------------+---------------------------------------------+
-- | id_rap       | DECIMAL(6,0)      | FOREIGN KEY                             |                                               |
-- |              |                   | NOT NULL                                |                                              |
-- +--------------+-------------------+--------------------------------------+---------------------------------------------+
-- | val_juicio   | VARCHAR           | NOT NULL                                |                                               |
-- |              |                   | CHECK(LENGTH(val_juicio) >= 5)          |                                              |
-- +--------------+-------------------+--------------------------------------+---------------------------------------------+
-- | fec_juicio   | DATE              | NOT NULL                                | Fecha/hora.                                   |
-- +--------------+-------------------+--------------------------------------+---------------------------------------------+
-- | id_instructor| DECIMAL(10,0)     | FOREIGN KEY                             | Identificador.                                |
-- |              |                   | NOT NULL                                |                                              |
-- +--------------+-------------------+--------------------------------------+---------------------------------------------+
-- | usr_insert   | VARCHAR           | NOT NULL                                | Usuario que creó/actualizó el registro.       |
-- |              |                   | CHECK(LENGTH(TRIM(usr_insert)) >= 3)    |                                              |
-- +--------------+-------------------+--------------------------------------+---------------------------------------------+
-- | fec_insert   | TIMESTAMP         | NOT NULL                                | Fecha/hora.                                   |
-- |              | WITHOUT TIME ZONE |                                         |                                              |
-- +--------------+-------------------+--------------------------------------+---------------------------------------------+
-- | usr_update   | VARCHAR           | CHECK(LENGTH(TRIM(usr_update)) >= 3)    | Usuario que creó/actualizó el registro.       |
-- +--------------+-------------------+--------------------------------------+---------------------------------------------+
-- | fec_update   | TIMESTAMP         |                                         | Fecha/hora.                                   |
-- |              | WITHOUT TIME ZONE |                                         |                                              |
-- +--------------+-------------------+--------------------------------------+---------------------------------------------+

CREATE TABLE IF NOT EXISTS tab_juicios_eval
(
    id_aprendiz               DECIMAL(10,0)               NOT NULL,
    id_rap                    DECIMAL(6,0)                NOT NULL,
    val_juicio                VARCHAR                     NOT NULL CHECK(LENGTH(val_juicio) >= 5),
    fec_juicio                DATE                        NOT NULL,
    id_instructor             DECIMAL(10,0)               NOT NULL,
    usr_insert                VARCHAR(50)                 NOT NULL CHECK(LENGTH(TRIM(usr_insert)) >= 3),
    fec_insert                TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update                VARCHAR(50)                          CHECK(LENGTH(TRIM(usr_update)) >= 3),
    fec_update                TIMESTAMP WITHOUT TIME ZONE,
  PRIMARY KEY(id_aprendiz),
  FOREIGN KEY(id_rap)           REFERENCES tab_raps(id_rap),
  FOREIGN KEY(id_instructor)    REFERENCES tab_instructores(id_instructor)
);

-- ***********************************************************************************
-- TABLAS PARA EL SISTEMA DE INGRESO Y EGRESO DE PERSONAS AL CENTRO DE SERVICIOS CSET
-- ***********************************************************************************
-- TABLA DE MÉTODOS DE AUTENTICACIÓN PARA INGRESO DE VISITANTES

-- TABLA DE TAB_METODOS_AUT
-- __________________________________________________________________________________________________________________________
-- | Columna        | Tipo             | Restricción                            | Descripción                                   |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | id_metodo_aut  | DECIMAL(2,0)     | NOT NULL                               |                                               |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | nom_metodo_aut | VARCHAR          | NOT NULL                               | Nombre del metodo aut.                        |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | usr_insert     | VARCHAR          | NOT NULL                               | Usuario que creó/actualizó el registro.       |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | fec_insert     | TIMESTAMP WITHOUT TIME ZONE | NOT NULL                               | Fecha/hora.                                   |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | usr_update     | VARCHAR          |                                        | Usuario que creó/actualizó el registro.       |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | fec_update     | TIMESTAMP WITHOUT TIME ZONE |                                        | Fecha/hora.                                   |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+

CREATE TABLE IF NOT EXISTS tab_metodos_aut
(
    id_metodo_aut           DECIMAL(2,0)                NOT NULL,
    nom_metodo_aut          VARCHAR(30)                 NOT NULL CHECK(LENGTH(nom_metodo_aut) >= 5),
    usr_insert              VARCHAR(50)                 NOT NULL CHECK(LENGTH(TRIM(usr_insert)) >= 3),
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR(50)                          CHECK(LENGTH(TRIM(usr_update)) >= 3),
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_metodo_aut)
);

-- TABLA DE VEHICULOS DE PERSPONAS AUTORIZADOS PARA INGRESO A PARKING

-- TABLA DE TAB_VEHICULOS
-- __________________________________________________________________________________________________________________________
-- | Columna        | Tipo             | Restricción                            | Descripción                                   |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | id_vehiculo    | VARCHAR          | NOT NULL                               |                                               |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | ind_tipovehiculo | DECIMAL(1,0)     | NOT NULL                               | Indicador booleano.                           |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | id_propietario | DECIMAL(10,0)    | NOT NULL                               |                                               |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | usr_insert     | VARCHAR          | NOT NULL                               | Usuario que creó/actualizó el registro.       |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | fec_insert     | TIMESTAMP WITHOUT TIME ZONE | NOT NULL                               | Fecha/hora.                                   |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | usr_update     | VARCHAR          |                                        | Usuario que creó/actualizó el registro.       |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | fec_update     | TIMESTAMP WITHOUT TIME ZONE |                                        | Fecha/hora.                                   |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+

CREATE TABLE IF NOT EXISTS tab_vehiculos
(
    id_vehiculo             VARCHAR                     NOT NULL,
    ind_tipovehiculo        DECIMAL(1,0)                NOT NULL, -- 1=Automovil / 2= Moto / 3= Bicicleta / 3=Patineta
    id_propietario          DECIMAL(10,0)               NOT NULL,
    usr_insert              VARCHAR(50)                 NOT NULL CHECK(LENGTH(TRIM(usr_insert)) >= 3),
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR(50)                          CHECK(LENGTH(TRIM(usr_update)) >= 3),
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_vehiculo),
    FOREIGN KEY(id_propietario) REFERENCES tab_personas(id_persona)
);

-- TABLA TRANSACCIONAL DE REGISTRO DE INGRESOS

-- TABLA DE TAB_LOG_INGRESOS
-- __________________________________________________________________________________________________________________________
-- | Columna        | Tipo             | Restricción                            | Descripción                                   |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | id_ingreso     | INTEGER          | NOT NULL                               |                                               |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | id_visitante   | DECIMAL(10,0)    | NOT NULL                               |                                               |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | fec_ingreso    | TIMESTAMP        | DEFAULT CURRENT_TIMESTAMP NOT NULL     | Fecha/hora.                                   |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | fec_salida     | TIMESTAMP        | DEFAULT CURRENT_TIMESTAMP NOT NULL     | Fecha/hora.                                   |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | id_metodo_aut  | DECIMAL(2,0)     | NOT NULL                               |                                               |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | id_entrada_centro | DECIMAL(1,0)     | NOT NULL                               | Identificador.                                |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | val_datos_origen | JSONB            |                                        |                                               |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | val_observaciones | TEXT             |                                        |                                               |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | usr_insert     | VARCHAR          | NOT NULL                               | Usuario que creó/actualizó el registro.       |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | fec_insert     | TIMESTAMP WITHOUT TIME ZONE | NOT NULL                               | Fecha/hora.                                   |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | usr_update     | VARCHAR          |                                        | Usuario que creó/actualizó el registro.       |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | fec_update     | TIMESTAMP WITHOUT TIME ZONE |                                        | Fecha/hora.                                   |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+

CREATE TABLE IF NOT EXISTS tab_log_ingresos
(
    id_ingreso              INTEGER                     NOT NULL,
    id_visitante            DECIMAL(10,0)               NOT NULL,
    fec_ingreso             TIMESTAMP                   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fec_salida              TIMESTAMP                   NOT NULL DEFAULT CURRENT_TIMESTAMP,
    id_metodo_aut           DECIMAL(2,0)                NOT NULL,
    id_entrada_centro       DECIMAL(1,0)                NOT NULL,
-- 'datos_origen' guarda el string del QR, Barcode o la metadata del formulario
    val_datos_origen        JSONB,
    val_observaciones       TEXT,
    usr_insert              VARCHAR(50)                 NOT NULL CHECK(LENGTH(TRIM(usr_insert)) >= 3),
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR(50)                          CHECK(LENGTH(TRIM(usr_update)) >= 3),
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_ingreso),
    FOREIGN KEY(id_visitante)       REFERENCES tab_personas(id_persona),
    FOREIGN KEY(id_metodo_aut)      REFERENCES tab_metodos_aut(id_metodo_aut),
    FOREIGN KEY(id_entrada_centro)  REFERENCES tab_entradas_centro(id_entrada_centro)
);
-- Indices para optimización de búsquedas frecuentes
CREATE INDEX idx_fec_ingresos ON tab_log_ingresos(fec_ingreso DESC);

--=====================================================================================

--****************************
-- TABLAS PARA REVISAR
--****************************

-- Tipo de dato para atributo de descripcion innovación del proyecto
CREATE TYPE innovacion_proyectos AS
(
	ind_resuelve_necesidad_sector_prod	    BOOLEAN,
	ind_mejora_proceso_productivo		    BOOLEAN,
	ind_usa_nuevas_tecnicas				    BOOLEAN,
	ind_prod_derechos_autor				    BOOLEAN,
	ind_posicion_mercado				    BOOLEAN
);

-- Tipo de dato para atributo de valoración productiva del proyecto
CREATE TYPE valoracion_productiva AS
(
	ind_necesidad_cliente_potencial		    BOOLEAN,
	ind_viabilidad_plan_negocio			    BOOLEAN
);

-- Tabla de proyectos asociados a una ficha y un programa de formación

-- TABLA DE TAB_PROYECTOS
-- __________________________________________________________________________________________________________________________
-- | Columna        | Tipo             | Restricción                            | Descripción                                   |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | id_proyecto    | DECIMAL(8,0)     | NOT NULL                               |                                               |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | id_programa    | DECIMAL(8,0)     | NOT NULL                               | Identificador.                                |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | nom_proyecto   | VARCHAR          | NOT NULL                               | Nombre del proyecto.                          |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | num_fichas_asociadas | DECIMAL(2,0)     | NOT NULL                               |                                               |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | val_tiempo_ejecucion | DECIMAL(2,0)     | NOT NULL                               |                                               |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | num_resultados | DECIMAL(2,0)     | NOT NULL                               |                                               |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | num_rap_especificos | DECIMAL(2,0)     | NOT NULL                               |                                               |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | num_rap_transversales | DECIMAL(2,0)     | NOT NULL                               |                                               |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | num_rap_basicos | DECIMAL(2,0)     | NOT NULL                               |                                               |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | val_problema   | TEXT             | NOT NULL                               |                                               |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | val_justificacion | TEXT             | NOT NULL                               |                                               |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | usr_insert     | VARCHAR          | NOT NULL                               | Usuario que creó/actualizó el registro.       |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | fec_insert     | TIMESTAMP WITHOUT TIME ZONE | NOT NULL                               | Fecha/hora.                                   |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | usr_update     | VARCHAR          |                                        | Usuario que creó/actualizó el registro.       |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | fec_update     | TIMESTAMP WITHOUT TIME ZONE |                                        | Fecha/hora.                                   |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+

CREATE TABLE IF NOT EXISTS tab_proyectos
(
    id_proyecto             DECIMAL(8,0)                NOT NULL,
    id_programa             DECIMAL(8,0)                NOT NULL,
    nom_proyecto            VARCHAR(100)                NOT NULL CHECK(LENGTH(nom_proyecto) >= 5),
    num_fichas_asociadas    DECIMAL(2,0)                NOT NULL,
    val_tiempo_ejecucion    DECIMAL(2,0)                NOT NULL, -- Este valor se debe dar en meses
    num_resultados          DECIMAL(2,0)                NOT NULL, -- Cantidad de RAPS asociados,
    num_rap_especificos     DECIMAL(2,0)                NOT NULL,
    num_rap_transversales   DECIMAL(2,0)                NOT NULL,
    num_rap_basicos         DECIMAL(2,0)                NOT NULL,
    val_problema            TEXT                        NOT NULL CHECK(LENGTH(val_problema) >= 5),
    val_justificacion       TEXT                        NOT NULL CHECK(LENGTH(val_justificacion) >= 5),
--    COMPETENCIAS DEL PROYECTO
--    PLANEACION DEL PROYECTO
    usr_insert              VARCHAR(50)                 NOT NULL CHECK(LENGTH(TRIM(usr_insert)) >= 3),
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR(50)                          CHECK(LENGTH(TRIM(usr_update)) >= 3),
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_proyecto),
    FOREIGN KEY(id_programa)                REFERENCES tab_programas(id_programa)
);

-- Estructura para diligenciar datos del ambiente. Variables.
CREATE TYPE inv_ambiente AS
(
    equipos_computo         BOOLEAN,        -- Posee equipos de cómputo? TRUE=Sí / FALSE=No
    num_equipos             DECIMAL(3,0),   -- Número de equipos de cómputo, incluye impresoras, portátiles, desktop, etc
    ind_smartboard          BOOLEAN,        -- Posee tablero programable? TRUE=Sí / FALSE=No
    ind_videobeam           BOOLEAN,        -- Posee Videobeam? TRUE=Sí / FALSE=No
    ind_impresora           BOOLEAN,        -- Posee Impresolra? TRUE=Sí / FALSE=No
    ind_aire                BOOLEAN,        -- Posee aire acondicionado? TRUE=Sí / FALSE=No    
    val_capacidad           DECIMAL(3,0)    -- Número de puestos disponibles para aprendices
);

-- Tabla de caracterización de ambientes. Se le asociará un CRUD específico y trato especial

-- TABLA DE TAB_AMBIENTES
-- __________________________________________________________________________________________________________________________
-- | Columna        | Tipo             | Restricción                            | Descripción                                   |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | id_ambiente    | VARCHAR          | NOT NULL                               | Identificador.                                |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | nom_ambiente   | VARCHAR          | NOT NULL                               | Nombre del ambiente.                          |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | id_centro      | DECIMAL(4,0)     | NOT NULL                               | Identificador.                                |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | id_sede        | DECIMAL(1,0)     | NOT NULL                               | Identificador.                                |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | ind_disponible_man | BOOLEAN          | NOT NULL DEFAULT TRUE                  | Indicador booleano.                           |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | ind_disponible_tar | BOOLEAN          | NOT NULL DEFAULT TRUE                  | Indicador booleano.                           |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | ind_disponible_noc | BOOLEAN          | NOT NULL DEFAULT TRUE                  | Indicador booleano.                           |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | inventario_ambiente | inv_ambiente     |                                        |                                               |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | equipos_ambiente | JSON             |                                        |                                               |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | usr_insert     | VARCHAR          | NOT NULL                               | Usuario que creó/actualizó el registro.       |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | fec_insert     | TIMESTAMP WITHOUT TIME ZONE | NOT NULL                               | Fecha/hora.                                   |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | usr_update     | VARCHAR          |                                        | Usuario que creó/actualizó el registro.       |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | fec_update     | TIMESTAMP WITHOUT TIME ZONE |                                        | Fecha/hora.                                   |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+

CREATE TABLE IF NOT EXISTS tab_ambientes
(
    id_ambiente             VARCHAR                     NOT NULL,   -- ID del ambiente
    nom_ambiente            VARCHAR(50)                 NOT NULL CHECK(LENGTH(nom_ambiente) >= 5),   -- Nombre del ambiente
    id_centro               DECIMAL(4,0)                NOT NULL,   -- ID del Centro
    id_sede                 DECIMAL(1,0)                NOT NULL,   -- ID de la Sede a la que está asociado el ambiente (ppal, salud, etc.)
    ind_disponible_man      BOOLEAN                     NOT NULL DEFAULT TRUE, -- TRUE=Disponible / FALSE=No disponible (Jornada mañana)
    ind_disponible_tar      BOOLEAN                     NOT NULL DEFAULT TRUE, -- TRUE=Disponible / FALSE=No disponible (Jornada tarde)
    ind_disponible_noc      BOOLEAN                     NOT NULL DEFAULT TRUE, -- TRUE=Disponible / FALSE=No disponible (Jornada noche)
    inventario_ambiente     inv_ambiente,
    equipos_ambiente        JSON,
    usr_insert              VARCHAR(50)                 NOT NULL CHECK(LENGTH(TRIM(usr_insert)) >= 3),
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR(50)                          CHECK(LENGTH(TRIM(usr_update)) >= 3),
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_ambiente),
    FOREIGN KEY(id_centro)                      REFERENCES tab_centros(id_centro),
    FOREIGN KEY(id_centro,id_sede)              REFERENCES tab_sedes(id_centro,id_sede)
);

-- TABLA DE SECTORES SEGÚN DIAN

-- TABLA DE TAB_SECTORES
-- __________________________________________________________________________________________________________________________
-- | Columna        | Tipo             | Restricción                            | Descripción                                   |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | id_sector      | DECIMAL(4,0)     | NOT NULL                               | Identificador.                                |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | nom_sector     | VARCHAR          | NOT NULL                               | Nombre del sector.                            |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | usr_insert     | VARCHAR          | NOT NULL                               | Usuario que creó/actualizó el registro.       |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | fec_insert     | TIMESTAMP WITHOUT TIME ZONE | NOT NULL                               | Fecha/hora.                                   |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | usr_update     | VARCHAR          |                                        | Usuario que creó/actualizó el registro.       |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | fec_update     | TIMESTAMP WITHOUT TIME ZONE |                                        | Fecha/hora.                                   |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+

CREATE TABLE IF NOT EXISTS tab_sectores
(
    id_sector               DECIMAL(4,0)                NOT NULL,
    nom_sector              VARCHAR                     NOT NULL CHECK(LENGTH(nom_sector) >= 3),
    usr_insert              VARCHAR(50)                 NOT NULL CHECK(LENGTH(TRIM(usr_insert)) >= 3),
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR(50)                          CHECK(LENGTH(TRIM(usr_update)) >= 3),
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_sector)
);

-- TABLA DE OCUPACIONES SEGÚN DIAN

-- TABLA DE TAB_OCUPACIONES
-- __________________________________________________________________________________________________________________________
-- | Columna        | Tipo             | Restricción                            | Descripción                                   |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | id_ocupacion   | DECIMAL(4,0)     | NOT NULL                               | Identificador.                                |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | nom_ocupacion  | VARCHAR          | NOT NULL                               | Nombre del ocupacion.                         |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | usr_insert     | VARCHAR          | NOT NULL                               | Usuario que creó/actualizó el registro.       |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | fec_insert     | TIMESTAMP WITHOUT TIME ZONE | NOT NULL                               | Fecha/hora.                                   |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | usr_update     | VARCHAR          |                                        | Usuario que creó/actualizó el registro.       |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | fec_update     | TIMESTAMP WITHOUT TIME ZONE |                                        | Fecha/hora.                                   |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+

CREATE TABLE IF NOT EXISTS tab_ocupaciones
(
    id_ocupacion            DECIMAL(4,0)                NOT NULL,
    nom_ocupacion           VARCHAR(160)                NOT NULL CHECK(LENGTH(nom_ocupacion) >= 4),
    usr_insert              VARCHAR(50)                 NOT NULL CHECK(LENGTH(TRIM(usr_insert)) >= 3),
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR(50)                          CHECK(LENGTH(TRIM(usr_update)) >= 3),
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_ocupacion)
);

-- TABLA DE TAB_PROG_ESPECIALES
-- __________________________________________________________________________________________________________________________
-- | Columna        | Tipo             | Restricción                            | Descripción                                   |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | id_prog_especial | DECIMAL(6,0)     | NOT NULL                               | Identificador.                                |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | nom_prog_especial | VARCHAR          | NOT NULL                               | Nombre del prog especial.                     |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | usr_insert     | VARCHAR          | NOT NULL                               | Usuario que creó/actualizó el registro.       |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | fec_insert     | TIMESTAMP WITHOUT TIME ZONE | NOT NULL                               | Fecha/hora.                                   |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | usr_update     | VARCHAR          |                                        | Usuario que creó/actualizó el registro.       |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | fec_update     | TIMESTAMP WITHOUT TIME ZONE |                                        | Fecha/hora.                                   |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+

CREATE TABLE IF NOT EXISTS tab_prog_especiales
(
    id_prog_especial        DECIMAL(6,0)                NOT NULL,
    nom_prog_especial       VARCHAR                     NOT NULL CHECK(LENGTH(nom_prog_especial) >= 3),
    usr_insert              VARCHAR(50)                 NOT NULL CHECK(LENGTH(TRIM(usr_insert)) >= 3),
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR(50)                          CHECK(LENGTH(TRIM(usr_update)) >= 3),
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_prog_especial)
);

-- Tabla de caracterización de fichas. Se le asociará un CRUD específico y trato especial

-- TABLA DE TAB_FICHAS
-- __________________________________________________________________________________________________________________________
-- | Columna        | Tipo             | Restricción                            | Descripción                                   |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | id_ficha       | DECIMAL(10,0)    | NOT NULL                               | Identificador.                                |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | id_centro      | DECIMAL(2,0)     | NOT NULL                               | Identificador.                                |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | id_programa    | DECIMAL(8,0)     | NOT NULL                               | Identificador.                                |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | id_nivel_estudio | DECIMAL(2,0)     | NOT NULL                               | Identificador.                                |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | ind_jornada    | DECIMAL(1,0)     | NOT NULL CHECK(ind_jornada >= 1 AND ind_jornada <= 4) | Indicador booleano.                           |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | ind_modalidad  | DECIMAL(1,0)     | NOT NULL                               | Indicador booleano.                           |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | fec_inicio     | DATE             | NOT NULL                               | Fecha/hora.                                   |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | fec_fin_lectiva | DATE             | NOT NULL                               | Fecha/hora.                                   |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | fec_fin_productiva | DATE             | NOT NULL                               | Fecha/hora.                                   |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | val_duracion   | DECIMAL(2,0)     | NOT NULL                               |                                               |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | id_instructor_lider | DECIMAL(10,0)    | NOT NULL                               |                                               |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | id_sector      | DECIMAL(1,0)     | NOT NULL DEFAULT 0                     | Identificador.                                |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | id_empresa     | DECIMAL(10,0)    | NOT NULL                               | Identificador.                                |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | id_ocupacion   | DECIMAL(4,0)     | NOT NULL                               | Identificador.                                |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | id_ciudad      | VARCHAR          | NOT NULL                               | Identificador.                                |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | cod_convenio   | DECIMAL(1,0)     | NOT NULL DEFAULT 0                     |                                               |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | nom_convenio   | VARCHAR          | NOT NULL DEFAULT 'Sin Convenio'        | Nombre del convenio.                          |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | ind_amp_cobertura | BOOLEAN          | NOT NULL DEFAULT FALSE                 | Indicador booleano.                           |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | id_prog_especial | DECIMAL(6,0)     | NOT NULL DEFAULT 0                     | Identificador.                                |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | ind_abierta    | BOOLEAN          | NOT NULL DEFAULT TRUE                  | Indicador booleano.                           |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | nom_vocero     | VARCHAR          | NOT NULL                               | Nombre del vocero.                            |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | tel_vocero     | DECIMAL(10,0)    | NOT NULL                               | Teléfono.                                     |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | mail_vocero    | mail_personal    | NOT NULL                               | Dirección de correo.                          |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | val_cupo       | DECIMAL(3,0)     | NOT NULL DEFAULT 30                    |                                               |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | id_ambiente_base | VARCHAR          | NOT NULL DEFAULT 'Sin Ambiente Base'   |                                               |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | num_inscritos_opcion1 | DECIMAL(3,0)     | NOT NULL                               |                                               |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | num_inscritos_opcion2 | DECIMAL(3,0)     | NOT NULL                               |                                               |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | ind_estado     | DECIMAL(1,0)     | NOT NULL                               | Indicador booleano.                           |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | num_cursos     | DECIMAL(2,0)     | NOT NULL DEFAULT 1                     |                                               |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | tot_aprendices_masc | DECIMAL(3,0)     | NOT NULL                               |                                               |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | tot_aprendices_fem | DECIMAL(3,0)     | NOT NULL                               |                                               |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | tot_aprendices_nobin | DECIMAL(2,0)     | NOT NULL                               |                                               |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | tot_aprendices_trans | DECIMAL(2,0)     | NOT NULL                               |                                               |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | total_aprendices | DECIMAL(4,0)     | GENERATED ALWAYS AS                    |                                               |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | COALESCE(tot_aprendices_masc, | 0::DECIMAL(3,0)) | +                                      |                                               |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | COALESCE(tot_aprendices_fem, | 0::DECIMAL(3,0)) | +                                      |                                               |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | COALESCE(tot_aprendices_nobin, | 0::DECIMAL(4,0)) | +                                      |                                               |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | COALESCE(tot_aprendices_trans, | 0::DECIMAL(4,0)) |                                        |                                               |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+

CREATE TABLE IF NOT EXISTS tab_fichas
(
    id_ficha                DECIMAL(10,0)               NOT NULL,
    id_centro               DECIMAL(2,0)                NOT NULL,
    id_programa             DECIMAL(8,0)                NOT NULL,
    id_nivel_estudio        DECIMAL(2,0)                NOT NULL,
    ind_jornada             DECIMAL(1,0)                NOT NULL CHECK(ind_jornada >= 1 AND ind_jornada <= 4), -- 1=Mañana / 2=Tarde / 3=Noche
    ind_modalidad           DECIMAL(1,0)                NOT NULL, -- 1=PRESENCIAL / 2=VIRTUAL / 3= DISTANCIA
    fec_inicio              DATE                        NOT NULL,
     fec_fin_lectiva         DATE                        NOT NULL DEFAULT (fec_inicio + INTERVAL '6 months'), -- Se asume que la duración lectiva es de 6 meses a partir de la fecha de inicio
    fec_fin_productiva      DATE                        NOT NULL, --- fecha fin programa
    val_duracion            DECIMAL(2,0)                NOT NULL, -- Valor dado en meses
    id_instructor_lider     DECIMAL(10,0)               NOT NULL, -- necesitamos id
    id_sector               DECIMAL(1,0)                NOT NULL DEFAULT 0,
    id_empresa              DECIMAL(10,0)               NOT NULL,
    id_ocupacion            DECIMAL(4,0)                NOT NULL,
    id_ciudad               VARCHAR                     NOT NULL, -- tenemos nombre / no coincide con la DIAN
    cod_convenio            DECIMAL(1,0)                NOT NULL DEFAULT 0,
    nom_convenio            VARCHAR                     NOT NULL DEFAULT 'Sin Convenio',
    ind_amp_cobertura       BOOLEAN                     NOT NULL DEFAULT FALSE, -- TRUE=Si es ampliación / FALSE=No es ampliación
    id_prog_especial        DECIMAL(6,0)                NOT NULL DEFAULT 0,
    ind_abierta             BOOLEAN                     NOT NULL DEFAULT TRUE, --TRUE=Abierta / FALSE=Cerrada
    nom_vocero              VARCHAR                     NOT NULL CHECK(LENGTH(nom_vocero) >= 3 AND LENGTH(nom_vocero) <= 50),
    tel_vocero              telefono_movil              NOT NULL, -- Validación para teléfonos móviles colombianos
    mail_vocero             mail_personal               NOT NULL,
    val_cupo                DECIMAL(3,0)                NOT NULL DEFAULT 30,
    id_ambiente_base        VARCHAR                     NOT NULL DEFAULT 'Sin Ambiente Base',
    num_inscritos_opcion1   DECIMAL(3,0)                NOT NULL,
    num_inscritos_opcion2   DECIMAL(3,0)                NOT NULL,
    ind_estado              DECIMAL(1,0)                NOT NULL, --1=Inscripción/2=En matrícula/3=Ejecución/7=Terminada * Fecha/8=Terminada
    num_cursos              DECIMAL(2,0)                NOT NULL DEFAULT 1,
    tot_aprendices_masc     DECIMAL(3,0)                NOT NULL,
    tot_aprendices_fem      DECIMAL(3,0)                NOT NULL,
    tot_aprendices_nobin    DECIMAL(2,0)                NOT NULL,
    tot_aprendices_trans    DECIMAL(2,0)                NOT NULL,
    total_aprendices        DECIMAL(4,0) GENERATED ALWAYS AS
                                        (
                                         COALESCE(tot_aprendices_masc, 0::DECIMAL(3,0))  +
                                         COALESCE(tot_aprendices_fem, 0::DECIMAL(3,0))   +
                                         COALESCE(tot_aprendices_nobin, 0::DECIMAL(4,0)) +
                                         COALESCE(tot_aprendices_trans, 0::DECIMAL(4,0))
                                        ) STORED,
    tot_horas_planta        INTERVAL                    NOT NULL DEFAULT '00:00:00',
    tot_horas_contratista   INTERVAL                    NOT NULL DEFAULT '00:00:00',
    tot_horas_contrat_ext   INTERVAL                    NOT NULL DEFAULT '00:00:00',
    tot_horas_monitores     INTERVAL                    NOT NULL DEFAULT '00:00:00',
    tot_horas_inst_empresa  INTERVAL                    NOT NULL DEFAULT '00:00:00',
    total_horas             INTERVAL GENERATED ALWAYS AS
                                    (
                                     COALESCE(tot_horas_planta, '0'::interval)      +
                                     COALESCE(tot_horas_contratista, '0'::interval) +
                                     COALESCE(tot_horas_contrat_ext, '0'::interval) +
                                     COALESCE(tot_horas_monitores, '0'::interval)   +
                                     COALESCE(tot_horas_inst_empresa, '0'::interval)
                                    ) STORED,
    tot_aprendices_activos  DECIMAL(3,0)                NOT NULL,
    val_duracion_programa   INTERVAL                    NOT NULL,
    id_nuevo_sector         DECIMAL(1,0)                NOT NULL DEFAULT 0,
    usr_insert              VARCHAR(50)                 NOT NULL CHECK(LENGTH(TRIM(usr_insert)) >= 3),
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR(50)                          CHECK(LENGTH(TRIM(usr_update)) >= 3),
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_ficha),
    FOREIGN KEY(id_centro)              REFERENCES tab_centros(id_centro),
    FOREIGN KEY(id_programa)            REFERENCES tab_programas(id_programa),
    FOREIGN KEY(id_nivel_estudio)       REFERENCES tab_niveles_estudio(id_nivel_estudio),
    FOREIGN KEY(id_instructor_lider)    REFERENCES tab_instructores(id_instructor),
    FOREIGN KEY(id_sector)              REFERENCES tab_sectores(id_sector),
    FOREIGN KEY(id_empresa)             REFERENCES tab_empresas(id_empresa),
    FOREIGN KEY(id_ocupacion)           REFERENCES tab_ocupaciones(id_ocupacion),
    FOREIGN KEY(id_ciudad)              REFERENCES tab_ciudades(id_ciudad),
    FOREIGN KEY(id_ambiente_base)       REFERENCES tab_ambientes(id_ambiente),
    FOREIGN KEY(id_prog_especial)       REFERENCES tab_prog_especiales(id_prog_especial),
    FOREIGN KEY(id_nuevo_sector)        REFERENCES tab_sectores(id_sector)
);
-- Se debe tener en cuenta la validaciòn acerca de:
-- Un ambiente no puede ser asignado a dos fichas al mismo tiempo en la misma jornada
-- Un Instructor no puede orientar dos fichas ni competencias al mismo tiempo en la misma jornada
-- Un ambiente debe estar disponible. Validar los indicadores ind_disponible_man/tar/noc de tab_ambientes

-- Tabla de aprendices

-- TABLA DE TAB_APRENDICES
-- __________________________________________________________________________________________________________________________
-- | Columna        | Tipo             | Restricción                            | Descripción                                   |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | id_aprendiz    | DECIMAL(10,0)    | NOT NULL                               |                                               |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | datos_aprendiz | datos_personales_aprendiz |                                        |                                               |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | ind_etdo_formacion | DECIMAL(1,0)     | NOT NULL                               | Indicador booleano.                           |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | num_llamados   | SMALLINT         | NOT NULL                               |                                               |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | usr_insert     | VARCHAR          | NOT NULL                               | Usuario que creó/actualizó el registro.       |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | fec_insert     | TIMESTAMP WITHOUT TIME ZONE | NOT NULL                               | Fecha/hora.                                   |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | usr_update     | VARCHAR          |                                        | Usuario que creó/actualizó el registro.       |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | fec_update     | TIMESTAMP WITHOUT TIME ZONE |                                        | Fecha/hora.                                   |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+

CREATE TABLE IF NOT EXISTS tab_aprendices
(
    id_aprendiz             DECIMAL(10,0)               NOT NULL,
    datos_aprendiz          datos_personales_aprendiz,
    ind_etdo_formacion      DECIMAL(1,0)                NOT NULL DEFAULT 1, -- 1=En formación / 2=Aplazado /  3=Retiro Vol. /4=Cancelado / 5=Condicionado / 6=Suspendido / 7= Desertado
    num_llamados            SMALLINT                    NOT NULL DEFAULT 0,   -- Cantidad de llamados de atención acumulados
    usr_insert              VARCHAR(50)                 NOT NULL CHECK(LENGTH(TRIM(usr_insert)) >= 3),
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR(50)                          CHECK(LENGTH(TRIM(usr_update)) >= 3),
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_aprendiz)
);

-- Tabla de aprendices por ficha

-- TABLA DE TAB_APRENDICES_FICHAS
-- __________________________________________________________________________________________________________________________
-- | Columna        | Tipo             | Restricción                            | Descripción                                   |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | id_ficha       | DECIMAL(10,0)    | NOT NULL                               | Identificador.                                |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | id_aprendiz    | DECIMAL(10,0)    | NOT NULL                               |                                               |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | usr_insert     | VARCHAR          | NOT NULL                               | Usuario que creó/actualizó el registro.       |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | fec_insert     | TIMESTAMP WITHOUT TIME ZONE | NOT NULL                               | Fecha/hora.                                   |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | usr_update     | VARCHAR          |                                        | Usuario que creó/actualizó el registro.       |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+
-- | fec_update     | TIMESTAMP WITHOUT TIME ZONE |                                        | Fecha/hora.                                   |
-- +--------------+----------------+--------------------------------------+---------------------------------------------+

CREATE TABLE IF NOT EXISTS tab_aprendices_fichas
(
    id_ficha                DECIMAL(10,0)               NOT NULL,
    id_aprendiz             DECIMAL(10,0)               NOT NULL,
    usr_insert              VARCHAR(50)                 NOT NULL CHECK(LENGTH(TRIM(usr_insert)) >= 3),
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR(50)                          CHECK(LENGTH(TRIM(usr_update)) >= 3),
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_ficha,id_aprendiz),
    FOREIGN KEY(id_ficha)                   REFERENCES tab_fichas(id_ficha),
    FOREIGN KEY(id_aprendiz)                REFERENCES tab_aprendices(id_aprendiz)
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
    id_consec       INTEGER                     NOT NULL,
    nom_tabla       VARCHAR                     NOT NULL CHECK(LENGTH(nom_tabla) >= 5),
    nom_registro    JSONB                       NOT NULL,
    usr_insert      VARCHAR(50)                 NOT NULL CHECK(LENGTH(TRIM(usr_insert)) >= 3),
    fec_insert      TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    PRIMARY KEY(id_consec)
);

-- PENDIENTE MODIFICAR EL ATRIBUTO JSONB CON LOS REGISTROS CORRESPONDIENTES A LA ACTIVIDAD REALIZADA SOBRE LA TABLA
-- Stored Procedure para auditoría
CREATE OR REPLACE FUNCTION fun_act_tabla() RETURNS "trigger" AS
$$
    DECLARE wid_consec tab_borrados.id_consec%TYPE;
    BEGIN
        IF TG_OP = 'INSERT' THEN
           NEW.usr_insert = CURRENT_USER;
           NEW.fec_insert = CURRENT_TIMESTAMP;
           RETURN NEW;
        END IF;
        IF TG_OP = 'UPDATE' THEN
           NEW.usr_update = CURRENT_USER;
           NEW.fec_update = CURRENT_TIMESTAMP;
           RETURN NEW;
        END IF;
        IF TG_OP = 'INSERT OR UPDATE' THEN
            SELECT MAX(a.id_consec) INTO wid_consec FROM tab_borrados a;
            IF wid_consec IS NULL THEN
                wid_consec = 1;
            ELSE
                wid_consec = wid_consec + 1;
            END IF;
            INSERT INTO tab_borrados VALUES(wid_consec,TG_RELNAME,CURRENT_USER,CURRENT_TIMESTAMP);
            RETURN OLD; 
        END IF;
    END;
$$
LANGUAGE PLPGSQL;

-- **************************************************************
-- TRIGGERS DE AUDITORÍA PARA GENERAR LOS USUARIOS DE LAS TABLAS
-- **************************************************************
CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_usuarios FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();
CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_menus FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();
CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_menu_usuarios FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();
CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_config_sistema FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();
CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_dptos FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();
CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_ciudades FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();
CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_regionales FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();
CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_centros FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();
CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_sedes FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();
CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_areas FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();
CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_entradas_centro FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();
CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_redes FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();
CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_pmtros_grales FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();
CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_empresas FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();
CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_tipos_docum FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();
CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_profesiones FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();
CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_niveles_estudio FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();
CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_tipos_persona FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();
CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_personas FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();
CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_instructores FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();
CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_contratos_instructor FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();
CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_adicion_contratos FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();
CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_horas_instructor FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();
CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_certificados FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();
CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_programas FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();
CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_competencias FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();
CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_compet_instructor FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();
CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_activ_proyecto FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();
CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_raps FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();
CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_evidencias FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();
CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_evidenciasXrap FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();
CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_juicios_eval FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();
CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_metodos_aut FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();
CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_vehiculos FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();
CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_log_ingresos FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();
CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_proyectos FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();
CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_ambientes FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();
CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_sectores FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();
CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_ocupaciones FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();
CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_prog_especiales FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();
CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_fichas FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();
CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_aprendices FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();
CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_aprendices_fichas FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();
CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_ausencias_aprendiz FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();
CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_llamados_atencion FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();
CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_ofertas FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();
CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_competencias_ficha FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();
CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_rutas FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();
CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_programacion FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();
CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_prog_competencia FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();