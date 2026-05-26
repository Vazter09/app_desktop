-- *******************************************************************************************
-- * SERVICIO NACIONAL DE APRENDIZAJE - SENA                                                 *
-- * SISTEMA INTEGRADO PARA LA GESTIÓN DE PLATAFORMA TECNOLÓGICA CSET                        *
-- * SCRIPT DE INSTALACIÓN DEL SISTEMA. INCLUYE LA CREACIÓN DE ESTRUCTURAS Y LAS INSERCIONES *
-- * CORRESPONDIENTES A LOS DATOS BÁSICOS PARA CARGA DE TABLAS MAESTRAS                      *
-- * Autores: CARLOS EDUARDO PEREZ RUEDA                                                     *
-- * Fecha: Abril de 2026                                                                    *
-- * Versión: 1.1                                                                            *
-- * Revisión: Abril de 2026                                                                 *
-- * Derechos Reservados de los Autores.                                                     *
-- * Cualquier modificación, comercialización y/o uso sin la autorización de los autores se  *
-- * considerará DELITO, de acuerdo con las leyes vigentes para el caso en COLOMBIA          * 
-- *******************************************************************************************

DROP TABLE IF EXISTS tab_borrados;
DROP TABLE IF EXISTS tab_prog_competencia;
DROP TABLE IF EXISTS tab_compet_instructor;
DROP TABLE IF EXISTS tab_compet_ficha;
DROP TABLE IF EXISTS tab_programacion;
DROP TABLE IF EXISTS tab_aprendices_fichas;
DROP TABLE IF EXISTS tab_aprendices;
DROP TABLE IF EXISTS tab_rutas;
DROP TABLE IF EXISTS tab_fichas;
DROP TABLE IF EXISTS tab_ambientes;
DROP TYPE IF EXISTS inv_ambiente;
DROP TABLE IF EXISTS tab_sedes;
DROP TABLE IF EXISTS tab_horas_instructor;
DROP TABLE IF EXISTS tab_instructores;
DROP TABLE IF EXISTS tab_evid_rap;
DROP TABLE IF EXISTS tab_evidencias;
DROP TABLE IF EXISTS tab_raps;
DROP TYPE IF EXISTS datos_personales;
DROP TABLE IF EXISTS tab_adi_contratos_instructor;
DROP TABLE IF EXISTS tab_contratos_instructor;
DROP TABLE IF EXISTS tab_profesiones;
DROP TABLE IF EXISTS tab_ciudades;
DROP TABLE IF EXISTS tab_dptos;
DROP TABLE IF EXISTS tab_competencias;
DROP TABLE IF EXISTS tab_activ_proyecto;
DROP TABLE IF EXISTS tab_proyectos;
DROP TYPE IF EXISTS innovacion_proyectos;
DROP TYPE IF EXISTS valoracion_productiva;
DROP TABLE IF EXISTS tab_programas;
DROP TABLE IF EXISTS tab_redes;
DROP TABLE IF EXISTS tab_centros;
DROP TABLE IF EXISTS tab_regionales;
DROP TABLE IF EXISTS tab_pmtros;
DROP TABLE IF EXISTS tab_users;

-- ***************************************************************************
-- 1. TABLAS DE SEGURIDAD Y ACCESOS AL SISTEMA DE GESTIÓN DE USUARIOS Y MENÚS
-- ***************************************************************************
-- TABLA DE USUARIOS
CREATE TABLE tab_usuarios
(
    id_usuario                  VARCHAR         NOT NULL CHECK(LENGTH(id_usuario) >= 5),
    nom_usuario                 VARCHAR         NOT NULL CHECK(LENGTH(nom_usuario) >= 8),
    pass_usuario                VARCHAR         NOT NULL CHECK(LENGTH(pass_usuario) >= 12),
    mail_usuario                VARCHAR         NOT NULL CHECK(mail_usuario ~* '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$'),
    ind_usuario                 BOOLEAN         NOT NULL DEFAULT FALSE, -- TRUE=Si es administrador / FALSE= Es un usuario normal.
    ind_estado                  BOOLEAN         NOT NULL DEFAULT TRUE,  -- TRUE=Sí está activo / FALSE=No está activo.
    PRIMARY KEY(id_usuario)
);

-- TABLA DE MENÚS
CREATE TABLE tab_menus
(
    id_menu                     VARCHAR         NOT NULL,
    nom_menu                    VARCHAR         NOT NULL CHECK(LENGTH(nom_menu) >= 3 AND LENGTH(nom_menu) <= 25),
    ind_id_padre                VARCHAR         NOT NULL,
    nom_programa                VARCHAR         NOT NULL DEFAULT 'no_aplica',
    PRIMRY KEY(id_menu)
);

-- TABLA DE MENÚS DE USUARIOS
CREATE TABLE tab_menu_usuarios
(
    id_usuario                  VARCHAR         NOT NULL,,
    id_menu                     VARCHAR         NOT NULL,
    PRIMARY KEY(id_usuario,id_menu),
    FOREIGN KEY(id_usuario) REFERENCES tab_usuarios(id_usuario),
    FOREIGN KEY(id_menu)    REFERENCES tab_menus(id_menu)
);

-- **************************
-- 2. TABLAS INSTITUCIONALES
-- **************************
-- TABLA DE DEPARTAMENTOS DE COLOMBIA SEGÚN DANE
CREATE TABLE tab_dptos
(
    id_dpto                     VARCHAR(2)      NOT NULL, -- ID del departamento
    nom_dpto                    VARCHAR         NOT NULL, -- Nombre del departamento
    usr_insert                  VARCHAR         NOT NULL,
    fec_insert                  TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update                  VARCHAR,
    fec_update                  TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_dpto)
);
INSERT INTO tab_dptos VALUES('00','Sin Departamento');

-- TABLA DE CIUDADES CON DEPATARMENTO SEGÚN DANE
CREATE TABLE tab_ciudades
(
    id_ciudad                   VARCHAR(5)      NOT NULL, -- ID de la ciudad
    nom_ciudad                  VARCHAR         NOT NULL, -- Nomnbre de la ciudad
    id_dpto                     VARCHAR(2)      NOT NULL, -- ID departamento de la ciudad
    usr_insert                  VARCHAR         NOT NULL,
    fec_insert                  TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update                  VARCHAR,
    fec_update                  TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_ciudad),
    FOREIGN KEY(id_dpto) REFERENCES tab_dptos(id_dpto)
);
INSERT INTO tab_ciudades VALUES('00000','Sin Ciudad','00');

-- TABLA DE REGIONALES DEL SENA
CREATE TABLE tab_regionales
(
    id_regional                 DECIMAL(2,0)    NOT NULL, -- ID de la regional de acuerdo con catálogo del SENA
    nom_regional                VARCHAR         NOT NULL, -- Nombre de la regional
    dir_regional                VARCHAR         NOT NULL, -- Dirección
    id_dpto                     VARCHAR(2)      NOT NULL,
    num_extension_tel           DECIMAL(8,0)    NOT NULL, -- Número de extensión.
    nom_director                VARCHAR         NOT NULL, -- Nombre del director vigente
    usr_insert                  VARCHAR         NOT NULL,
    fec_insert                  TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update                  VARCHAR,
    fec_update                  TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_regional),
    FOREIGN KEY(id_dpto) REFERENCES tab_dptos(id_dpto)
);
INSERT INTO tab_regionales VALUES(0,'Sin Regional','Sin Dirección Reg.','00','0','Sin Director');

-- TABLA DE CENTROS DE UNA REGIONAL DEL SENA
CREATE TABLE tab_centros
(
    id_centro                   DECIMAL(4,0)    NOT NULL, -- ID del Centro
    nom_centro                  VARCHAR         NOT NULL, -- Nombre del Centro
    dir_centro                  VARCHAR         NOT NULL, -- Dirección
    num_extension_tel           DECIMAL(8,0)    NOT NULL, -- Extensión. NO hay teléfono fijo, se enruta por la línea nacional
    nom_subdirector             VARCHAR         NOT NULL, -- Nombre del subdirector vigente
    id_regional                 DECIMAL(2,0)    NOT NULL, -- ID de la regional
    usr_insert                  VARCHAR         NOT NULL,
    fec_insert                  TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update                  VARCHAR,
    fec_update                  TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_centro),
    FOREIGN KEY(id_regional)                REFERENCES tab_regionales(id_regional)
);
INSERT INTO tab_centros VALUES(0,0,'Sin Dirección de Centro',0,'Sin Nombre Subdirector',0);

-- TABLA DE SEDES DE UN CENTRO
CREATE TABLE tab_sedes
(
    id_centro               DECIMAL(4,0),
    id_sede                 DECIMAL(1,0)    NOT NULL,
    nom_sede                VARCHAR         NOT NULL,
    dir_sede                VARCHAR         NOT NULL,
    nom_encargado           VARCHAR         NOT NULL,
    tel_sede                DECIMAL(10,0)   NOT NULL,
    usr_insert              VARCHAR         NOT NULL,
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR,
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_centro,id_sede),
    FOREIGN KEY(id_centro)                  REFERENCES tab_centros(id_centro)    
);

-- TABLA DE REDES DE CONOCIMIENTO SENA
CREATE TABLE tab_redes
(
    id_red                  DECIMAL(2,0)    NOT NULL, -- ID red de conocimiento según catálogo del SENA
    nom_red           		TEXT            NOT NULL, -- Nombre de la red
    nom_lider               VARCHAR         NOT NULL, -- Nombre del líder vigente
    usr_insert              VARCHAR         NOT NULL,
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR,
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
	PRIMARY KEY(id_red)
);

-- TABLA DE PARÁMETROS GENERALES DEL SISTEMA APLICABLE A TODOS LOS PROCESOS.
CREATE TABLE tab_pmtros_grales
(
    id_centro                   DECIMAL(8,0)    NOT NULL,   -- Centro en donde se está ejecutando SMARTCSET
    dir_centro                  VARCHAR         NOT NULL,
    tel_centro                  DECIMAL(10,0)   NOT NULL,   -- Teléfono del Centro
    ano_academico               DECIMAL(4,0)    NOT NULL,   -- Año en el que se está trabajando
    mes_academico               DECIMAL(2,0)    NOT NULL,   -- Mes. Debe actualizarse automáticamente (EJECUTAR FUNCIÓN CRON)
    val_nota_minima_rap         DECIMAL(3,0)    NOT NULL    DEFAULT 71  CHECK(VAL_NOTA_MINIMA >= 0 AND val_nota_minima <= 100), -- Nota mínima de aprendiz para aprobar
    num_horas_instructor        DECIMAL(3,0)    NOT NULL    DEFAULT 160 CHECK(val_horas_instructor >=0 AND val_horas_instructor <= 200), -- Horas mes instructor por cumplir por contrato
    val_porcent_icfes_raps      DECIMAL(2,0)    NOT NULL    DEFAULT 75,-- Valor mínimo de raps calificados para asistir a pruebas ICFES
    usr_insert                  VARCHAR         NOT NULL,
    fec_insert                  TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update                  VARCHAR,
    fec_update                  TIMESTAMP WITHOUT TIME ZONE,
	PRIMARY KEY(id_centro),
    FOREIGN KEY(id_centro)              REFERENCES tab_centros(id_centro);
);

-- TABLA DE EMPRESAS QUE TIENEN QUE VER CON EL CENTRO (PRODUCTIVA DE APRENDICEZ, CONTRATISTAS, ETC.)
CREATE TABLE tab_empresas
(
    id_empresa                  DECIMAL(10,0)   NOT NULL,
    id_tipodoc                  VARCHAR(3)      NOT NULL    DEFAULT 'Sin',
    nom_empresa                 VARCHAR         NOT NULL    DEFAULT 'Sin Empresa'
    usr_insert                  VARCHAR         NOT NULL,
    fec_insert                  TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update                  VARCHAR,
    fec_update                  TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_empresa),
    FOREIGN KEY(id_tipodoc) REFERENCES tab_tiposdoc(id_tipodoc)
);
INSERT INTO tab_empresas VALUES(999,'Sin','Sin Empresa');

-- *******************************************
-- 3. TABLAS GENERALES DE CARACTER TRANSVERSAL
-- *******************************************
-- TABLA DE TIPOS DE DOCUMENTO PARA PERSONAS
CREATE TABLE tab_tiposdoc
(
    id_tipodoc                  VARCHAR(3)      NOT NULL,
    nom_tipodoc                 VARCHAR         NOT NULL,
    usr_insert                  VARCHAR         NOT NULL,
    fec_insert                  TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update                  VARCHAR,
    fec_update                  TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_tipodoc)
);
INSERT INTO tab_tiposdoc VALUES('Sin','Sin Tipo Documento');

-- TABLA DE PROFESIONES SEGÚN "CUOC-indice-clasificacion-unica-ocupaciones-colombia"
CREATE TABLE tab_profesiones
(
    id_profesion                VARCHAR         NOT NULL, -- ID de la profesión, según CUOC de Colombia
    nom_profesion               VARCHAR         NOT NULL, -- Nombre de la profesión
    usr_insert                  VARCHAR         NOT NULL,
    fec_insert                  TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update                  VARCHAR,
    fec_update                  TIMESTAMP WITHOUT TIME ZONE,
  PRIMARY KEY(id_profesion)
);
INSERT INTO tab_profesiones VALUES('00','Profesión Genérica');

-- TABLA DE NIVELES DE ESTUDIO
CREATE TABLE tab_niveles_estudio
(
    id_nivel_estudio            DECIMAL(2,0)    NOT NULL,
    nom_nivel_estudio           VARCHAR         NOT NULL,
    usr_insert                  VARCHAR         NOT NULL,
    fec_insert                  TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update                  VARCHAR,
    fec_update                  TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_nivel_estudio)
);

-- *******************************************************************
-- 4. TABLAS DE PERSONAS COMO EMPRESAS, INSTRUCTORES, APRENDICES, ETC.
-- *******************************************************************
-- TABLAS GENERALES DE PERSONAS QUE ALIMENTA A TODAS LAS DEMÁS (Instructores, aprendices, visitantes, etc.)
CREATE TABLE tab_personas
(-- DATOS DE IDENTIFICACIÓN DE LA PERSONA (A VALIDAR CONTRA REGISTRADURÍA)
    id_persona                  DECIMAL(10,0)   NOT NULL,
    id_tipodoc                  VARCHAR(2)      NOT NULL    DEFAULT 'CC',
    nom_persona                 VARCHAR         NOT NULL,
    ape_persona                 VARCHAR         NOT NULL,
    mail_persona                TEXT            NOT NULL    DEFAULT 'Sin Correo';
    fec_nacimiento              DATE            NOT NULL    DEFAULT '1900-01-01'
    ind_genero                  DECIMAL(2,0)    NOT NULL,
-- DATOS GEOGRÁFICOS DE LA PERSONA
    id_dpto_reside              VARCHAR(2)      NOT NULL, -- ID departamento de la ciudad
    id_ciudad_reside            VARCHAR(5)      NOT NULL,
    dir_ciudad_reside           VARCHAR         NOT NULL,
    tel_persona_fijo            DECIMAL(10,0)   NOT NULL,
    tel_persona_movil           DECIMAL(10,0)   NOT NULL,
    nom_contacto_emergencias    DECIMAL(10,0)   NOT NULL,
    tel_contacto_emergencias    DECIMAL(10,0)   NOT NULL,
    ind_envio_correo            BOOLEAN         NOT NULL    DEFAULT TRUE, -- TRUE=Enviarle correos / FALSE=No se le envían correos
    ind_estado                  BOOLEAN         NOT NULL    DEFAULT TRUE, -- TRUE=Activo / FALSE=Inactivo
    usr_insert                  VARCHAR         NOT NULL,
    fec_insert                  TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update                  VARCHAR,
    fec_update                  TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_persona),
    FOREIGN KEY(id_tipodoc)         REFERENCES tab_tiposdoc(id_tipodoc),
    FOREIGN KEY(id_dpto_reside)     REFERENCES tab_dptos(id_dpto),
    FOREIGN KEY(id_ciudad_reside)   REFERENCES tab_ciudades(id_ciudad)
);
INSERT INTO tab_personas VALUES(9999,'Sin','Sin Nombre Persona','Sin Apellido','Sin Correo','1900-01-01',0,'00','00000','Sin Dirección',0,0,
                                 'Sin Contacto',0,TRUE);

-- Datos personales o de residencia del instructor
CREATE TYPE datos_personales_aprendiz AS
(
    tel_alterno                 DECIMAL(10,0),
    tel_sede                    DECIMAL(10,0),
    ext_sede                    DECIMAL(4),
    tel_padre_fijo              DECIMAL(10,0),
    tel_padre_movil             DECIMAL(10,0),
    val_correo_institucional    VARCHAR,
    nom_contacto_emergencias    VARCHAR,
    tel_contacto_emergencias    DECIMAL(10,0)
);

--TABLA DE INSTRUCTORES
CREATE TABLE tab_instructores
(
    id_instructor           DECIMAL(10,0)   NOT NULL    CHECK(id_instructor > 20000000),
    id_centro               DECIMAL(4,0)    NOT NULL,
    ind_tipo_contrato       BOOLEAN         NOT NULL, --TRUE=Planta / FALSE=Contratista. Si es contratista, se debe consultar el vigente en la tabla tab_contratos_instructor
    ind_contratado_actual   BOOLEAN         NOT NULL, --TRUE=Contratado actualmente / FALSE=No Contratado. Si está contratado debe consultarse el contrato en la tabla hija
    ind_genero              DECIMAL(1,0)    NOT NULL    CHECK(ind_genero = 1 OR ind_genero = 2 OR ind_genero = 4), --1=Femenino,2=Masculino,3=No binario,4=Trans
    ind_est_civil           DECIMAL(1,0)    NOT NULL    CHECK(ind_est_civil >= 0 AND ind_est_civil <=9),--1=Casado 2=Soltero 3=Unión Libre', 3=Viudo, 4=Divorciado, 5=Otro
    id_nivel_estudio        DECIMAL(2,0)    NOT NULL,
    id_profesion            VARCHAR         NOT NULL,
    id_red                  DECIMAL(2,0)    NOT NULL,
    ind_disponibilidad      BOOLEAN         NOT NULL    DEFAULT TRUE, -- TRUE=Disponible / FALSE=No Disponible (Ocupado con tiempo completo)
    ind_estado              DECIMAL(1,0)    NOT NULL    CHECK(ind_estado >= 0 AND ind_estado <= 9) NOT NULL, -- 0=Activo,2=Suspendido,3=Bloqueado,9=Inactivo;
    usr_insert              VARCHAR         NOT NULL,
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR,
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_instructor),
    FOREIGN KEY(id_centro)        REFERENCES tab_centros(id_centro),
    FOREIGN KEY(id_nivel_estudio) REFERENCES tab_niveles_estudio(id_nivel_estudio),
    FOREIGN KEY(id_profesion)     REFERENCES tab_profesiones(id_profesion),
    FOREIGN KEY(id_red)           REFERENCES tab_redes(id_red)
);

-- Tabla de contratos que tiene un instructor. No aplica para instructores con tipo contrato TRUE en tabla de Instructores (Planta).
-- Si ind_adicion de esta tabla es = TRUE, se debe consultar la tabla dependiente esta tabla para seleccionar los datos de la adición.
CREATE TABLE tab_contratos_instructor
(
    id_instructor           DECIMAL(10,0)   NOT NULL,
    num_contrato            VARCHAR         NOT NULL,
    year_contrato           DECIMAL(4,0),
    fec_inicio              DATE            NOT NULL,
    fec_fin                 DATE            NOT NULL,
    ind_vigente             BOOLEAN         NOT NULL    DEFAULT TRUE, --TRUE=Vigente / FALSE=Ejecutado. Una vez concluya el contrato debe pasar a FALSE
    ind_adicion             BOOLEAN         NOT NULL    DEFAULT FALSE, -- TRUE=Tiene adición / FALSE=No tiene adición
    usr_insert              VARCHAR         NOT NULL,
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR,
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_instructor,num_contrato)
);

-- Tabla de adiciones del contrato. Si el ind_adicion en tab_contratos_instructores es TRUE,
-- Se deben sacar los datos de la adición de esta tabla. Pueden haber hasta 2 adiciones.
CREATE TABLE tab_adi_contratos_instructor
(
    id_instructor           DECIMAL(10,0)   NOT NULL,
    num_contrato            VARCHAR         NOT NULL,
    num_adicion             DECIMAL(1,0)    NOT NULL    CHECK(num_adicion >= 0 AND num_adicion <=3),
    fec_ini_adicion         DATE            NOT NULL,
    fec_fin_adicion         DATE            NOT NULL,
    usr_insert              VARCHAR         NOT NULL,
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR,
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(num_contrato,num_adicion),
    FOREIGN KEY(num_contrato) REFERENCES tab_contratos_instructor(num_contrato)
);

-- Tabla de horas trabajadas por mes para un instructor
CREATE TABLE tab_horas_instructor
(
    id_instructor           DECIMAL(10,0)   NOT NULL,
    id_mes                  DECIMAL(2,0)    NOT NULL,   -- Meses del 1 al 12
    val_horas_form_mes      DECIMAL(4,0)    NOT NULL,   -- Cantidad de horas del mes vigente
    val_horas_apoyo_mes     DECIMAL(4,0)    NOT NULL,   -- Horas ejecutadas en apoyo
    val_hotras_invest_mes   DECIMAL(4,0)    NOT NULL,   -- Horas ejecutadas en Investigación
    val_horas_acum          DECIMAL(3,0)    NOT NULL,   -- Cantidad de horas acumuladas hasta el mes vigente
    usr_insert              VARCHAR         NOT NULL,
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR,
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_instructor,id_mes),
    FOREIGN KEY(id_instructor) REFERENCES tab_instructores(id_instructor)
);

-- *******************************************************
-- TABLAS PARA INFORMACIÓN DE LOS PROGRAMAS DE FORMACIÓN *
-- *******************************************************
-- Tabla de Programas de Formación SENA
CREATE TABLE tab_programas
(
    id_programa             DECIMAL(8,0)    NOT NULL,
    nom_programa            VARCHAR         NOT NULL,
    num_snies               VARCHAR         NOT NULL,
    num_version             DECIMAL(2,0)    NOT NULL,
    ind_tipo                VARCHAR    		NOT NULL, -- 1=Tecnología / 2=Técnica / 3= Epecialización / 4=Complementaria / 5=Curso
    val_duracion_lect_hrs   DECIMAL(4,0)    NOT NULL,
    val_duracion_prod_hrs   DECIMAL(4,0)    NOT NULL,
    val_duracion_lect_mes   DECIMAL(2,0)    NOT NULL,
    val_duracion_prod_me    DECIMAL(2,0)    NOT NULL,
    usr_insert              VARCHAR         NOT NULL,
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR,
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_programa)
);

-- Tabla de competencias para un proyecto y un programa
CREATE TABLE tab_competencias
(
    id_competencia          DECIMAL(10,0)   NOT NULL,
    nom_competencia         TEXT            NOT NULL,
    num_raps                DECIMAL(2,0)    NOT NULL,
    num_horas               DECIMAL(4,0)    NOT NULL,
    ind_transversal         BOOLEAN         NOT NULL    DEFAULT FALSE, -- TRUE=Es transversal / FALSE=Es técnica
    usr_insert              VARCHAR         NOT NULL,
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR,
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_competencia)
);

-- Tabla de competencias por instructor. La idea es que el Instructor oriente competencias en las que sea experto y que el sistema detecte esto en esta tabla antes de programarlo.
CREATE TABLE tab_compet_instructor
(
    id_instructor           DECIMAL(10,0)  NOT NULL,
    id_competencia          DECIMAL(10,0)  NOT NULL,
    usr_insert              VARCHAR        NOT NULL,
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR,
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_instructor,id_competencia),
    FOREIGN KEY(id_instructor)          REFERENCES tab_instructores(id_instructor),
    FOREIGN KEY(id_competencia)         REFERENCES tab_competencias(id_competencia),
);

-- Tabla de Actividades de proyecto
CREATE TABLE tab_activ_proyecto
(
    id_actividad            DECIMAL(10,0)   NOT NULL,
    nom_actividad           TEXT            NOT NULL,
    usr_insert              VARCHAR         NOT NULL,
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR,
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
	PRIMARY KEY(id_actividad)
);

-- Tabla de RAP's
CREATE TABLE tab_raps
(
    id_rap                  DECIMAL(10,0)   NOT NULL,
    id_competencia          DECIMAL(10,0)   NOT NULL,
    nom_rap                 TEXT            NOT NULL,
    usr_insert              VARCHAR         NOT NULL,
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR,
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
	PRIMARY KEY(id_rap),
    FOREIGN KEY(id_competencia)             REFERENCES tab_competencias(id_competencia)
);

-- Tabla de evidencias aplicables a los RAP's
CREATE TABLE tab_evidencias
(
    id_evidencia            VARCHAR         NOT NULL,
    nom_evidencia           TEXT            NOT NULL,
    val_nota_maxima         DECIMAL(3,0)    NOT NULL    CHECK(val_nota_maxima >= 0 AND val_nota_maxima <= 100),
    val_nota_minima         DECIMAL(3,0)    NOT NULL    CHECK(val_nota_minima >= 0 AND val_nota_minima <= 100),
    usr_insert              VARCHAR         NOT NULL,
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR,
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_evidencia)
);

--Tabla de evidencias por RAP
CREATE TABLE tab_evid_rap
(
    id_rap                  DECIMAL(10,0)   NOT NULL,
    id_evidencia            VARCHAR         NOT NULL,
    usr_insert              VARCHAR         NOT NULL,
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR,
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
	PRIMARY KEY(id_rap,id_evidencia),
	FOREIGN KEY(id_rap)			            REFERENCES tab_raps(id_rap),
	FOREIGN KEY(id_evidencia)	            REFERENCES tab_evidencias(id_evidencia)
);

-- ENTIDADES DE INGRESO
-- Personas
-- Aprendices
-- Visitantes
-- Instructores
-- Ingresos
-- Motivos de rechazo
-- Dispositivos de lectura
-- Entradas al Centro
-- Vehículos
-- Elementos confiscados
-- Llamados de atención (aprendices e instructores)
-- Comités


--===============================================


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
CREATE TABLE tab_proyectos
(
    id_proyecto             DECIMAL(8,0)    NOT NULL,
    id_programa             DECIMAL(8,0)    NOT NULL,
    nom_proyecto            VARCHAR         NOT NULL,
    num_fichas_asociadas    DECIMAL(2,0)    NOT NULL,
    val_tiempo_ejecucion    DECIMAL(2,0)    NOT NULL, -- Este valor se debe dar en meses
    num_resultados          DECIMAL(2,0)    NOT NULL, -- Cantidad de RAPS asociados,
    num_rap_especificos     DECIMAL(2,0)    NOT NULL,
    num_rap_transversales   DECIMAL(2,0)    NOT NULL,
    num_rap_basicos         DECIMAL(2,0)    NOT NULL,
    val_problema            TEXT            NOT NULL,
    val_justificacion       TEXT            NOT NULL,
--    COMPETENCIAS DEL PROYECTO
--    PLANEACION DEL PROYECTO
    usr_insert              VARCHAR         NOT NULL,
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR,
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
CREATE TABLE tab_ambientes
(
    id_ambiente             VARCHAR         NOT NULL,   -- ID del ambiente
    nom_ambiente            VARCHAR         NOT NULL,   -- Nombre del ambiente
    id_centro               DECIMAL(4,0)    NOT NULL,   -- ID del Centro
    id_sede                 DECIMAL(1,0)    NOT NULL,   -- ID de la Sede a la que está asociado el ambiente (ppal, salud, etc.)
    ind_disponible_man      BOOLEAN         NOT NULL    DEFAULT TRUE, -- TRUE=Disponible / FALSE=No disponible (Jornada mañana)
    ind_disponible_tar      BOOLEAN         NOT NULL    DEFAULT TRUE, -- TRUE=Disponible / FALSE=No disponible (Jornada tarde)
    ind_disponible_noc      BOOLEAN         NOT NULL    DEFAULT TRUE, -- TRUE=Disponible / FALSE=No disponible (Jornada noche)
    inventario_ambiente     inv_ambiente,
    equipos_ambiente        JSON,
    usr_insert              VARCHAR         NOT NULL,
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR,
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_ambiente),
    FOREIGN KEY(id_centro)                      REFERENCES tab_centros(id_centro),
    FOREIGN KEY(id_centro,id_sede)              REFERENCES tab_sedes(id_centro,id_sede)
);

-- TABLA DE NIVELES DE FORMACIÓN
CREATE TABLE tab_niveles
(
    id_nivel                DECIMAL(2,0)    NOT NULL,
    nom_nivel               VARCHAR         NOT NULL,
    PRIMARY KEY(id_nivel)
);
INSERT INTO tab_niveles VALUES(0,'Sin Nivel');

-- TABLA DE SECTORES SEGÚN DIAN
CREATE TABLE tab_sectores
(
    id_sector               DECIMAL(4,0)    NOT NULL,
    nom_sector              VARCHAR         NOT NULL,
    PRIMARY KEY(id_sector)
);
INSERT INTO tab_sectores VALUES(0,'Sin Sector');

-- TABLA DE OCUPACIONES SEGÚN DIAN
CREATE TABLE tab_ocupaciones
(
    id_ocupacion            DECIMAL(4,0)    NOT NULL,
    nom_ocupacion           VARCHAR         NOT NULL,
    PRIMARY KEY(id_ocupacion)
);
INSERT INTO tab_ocupaciones VALUES(0,'Sin Ocupacion');

CREATE TABLE tab_prog_especiales
(
    id_prog_especial        DECIMAL(6,0)    NOT NULL,
    nom_prog_especial       VARCHAR         NOT NULL,
    PRIMARY KEY(id_prog_especial)   
);

-- Tabla de caracterización de fichas. Se le asociará un CRUD específico y trato especial
CREATE TABLE tab_fichas
(
    id_ficha                DECIMAL(10,0)   NOT NULL,
    id_centro               DECIMAL(2,0)    NOT NULL,
    id_programa             DECIMAL(8,0)    NOT NULL,
    id_nivel                DECIMAL(1,0)    NOT NULL,
    ind_jornada             DECIMAL(1,0)    NOT NULL    CHECK(ind_jornada >= 1 AND ind_jornada <= 4), -- 1=Mañana / 2=Tarde / 3=Noche
    ind_modalidad           DECIMAL(1,0)    NOT NULL, -- 1=PRESENCIAL / 2=VIRTUAL / 3= DISTANCIA
    fec_inicio              DATE            NOT NULL,
    fec_fin_lectiva         DATE            NOT NULL,
    fec_fin_productiva      DATE            NOT NULL,
    val_duracion            DECIMAL(2,0)    NOT NULL, -- Valor dado en meses
    id_instructor_lider     DECIMAL(10,0)   NOT NULL,
    id_sector               DECIMAL(1,0)    NOT NULL    DEFAULT 0,
    id_empresa              DECIMAL(10,0)   NOT NULL,
    id_ocupacion            DECIMAL(4,0)    NOT NULL,
    id_dpto                 VARCHAR         NOT NULL,
    id_ciudad               VARCHAR         NOT NULL,
    cod_convenio            DECIMAL(1,0)    NOT NULL    DEFAULT 0,
    nom_convenio            VARCHAR         NOT NULL    DEFAULT 'Sin Convenio',
    ind_amp_cobertura       BOOLEAN         NOT NULL    DEFAULT FALSE, -- TRUE=Si es ampliación / FALSE=No es ampliación
    id_prog_especial        DECIMAL(6,0)    NOT NULL    DEFAULT 0,
    ind_abierta             BOOLEAN         NOT NULL    DEFAULT TRUE, --TRUE=Abierta / FALSE=Cerrada
    nom_vocero              VARCHAR         NOT NULL,
    tel_vocero              DECIMAL(10,0)   NOT NULL,
    mail_vocero             VARCHAR         NOT NULL,
    val_cupo                DECIMAL(3,0)    NOT NULL DEFAULT 30,
    id_ambiente_base        VARCHAR         NOT NULL DEFAULT 'Sin Ambiente Base',
    num_inscritos_opcion1   DECIMAL(3,0)    NOT NULL,
    num_inscritos_opcion2   DECIMAL(3,0)    NOT NULL,
    ind_estado              DECIMAL(1,0)    NOT NULL, --1=Inscripción/2=En matrícula/3=Ejecución/7=Terminada * Fecha/8=Terminada
    num_cursos              DECIMAL(2,0)    NOT NULL    DEFAULT 1,
    tot_aprendices_masc     DECIMAL(3,0)    NOT NULL,
    tot_aprendices_fem      DECIMAL(3,0)    NOT NULL,
    tot_aprendices_nobin    DECIMAL(2,0)    NOT NULL,
    tot_aprendices_trans    DECIMAL(2,0)    NOT NULL,
    total_aprendices        DECIMAL(4,0) GENERATED ALWAYS AS
                                        (
                                         COALESCE(tot_aprendices_masc, 0::DECIMAL(3,0))  +
                                         COALESCE(tot_aprendices_fem, 0::DECIMAL(3,0))   +
                                         COALESCE(tot_aprendices_nobin, 0::DECIMAL(4,0)) +
                                         COALESCE(tot_aprendices_trans, 0::DECIMAL(4,0))
                                        ),
    tot_horas_planta        INTERVAL        NOT NULL    DEFAULT 00:00:00,
    tot_horas_contratista   INTERVAL        NOT NULL    DEFAULT 00:00:00,
    tot_horas_contrat_ext   INTERVAL        NOT NULL    DEFAULT 00:00:00,
    tot_horas_monitores     INTERVAL        NOT NULL    DEFAULT 00:00:00,
    tot_horas_inst_empresa  INTERVAL        NOT NULL    DEFAULT 00:00:00,
    total_horas             INTERVAL GENERATED ALWAYS AS
                                    (
                                     COALESCE(tot_horas_planta, '0'::interval)      +
                                     COALESCE(tot_horas_contratista, '0'::interval) +
                                     COALESCE(tot_horas_contrat_ext, '0'::interval) +
                                     COALESCE(tot_horas_monitores, '0'::interval)   +
                                     COALESCE(tot_horas_inst_empresa, '0'::interval)
                                    ) STORED,
    tot_aprendices_activos  DECIMAL(3,0)    NOT NULL,
    val_duracion_programa   INTERVAL        NOT NULL,
    id_nuevo_sector         DECIMAL(1,0)    NOT NULL    DEFAULT 0,
    usr_insert              VARCHAR         NOT NULL,
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR,
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_ficha),
    FOREIGN KEY(id_centro)                  REFERENCES tab_centros(id_centro),
    FOREIGN KEY(id_programa)                REFERENCES tab_programas(id_programa),
    FOREIGN KEY(id_nivel)                   REFERENCES tab_niveles(id_nivel),
    FOREIGN KEY(id_instructor_lider)        REFERENCES tab_instructores(id_instructor),
    FOREIGN KEY(id_sector)                  REFERENCES tab_sectores(id_sector),
    FOREIGN KEY(id_empresa)                 REFERENCES tab_empresas(id_empresa),
    FOREIGN KEY(id_ocupacion)               REFERENCES tab_ocupaciones(id_ocupacion),
    FOREIGN KEY(id_dpto,id_ciudad)          REFERENCES tab_ciudades(id_dpto,id_ciudad),
    FOREIGN KEY(id_ambiente_base)           REFERENCES tab_ambientes(id_ambiente),
    FOREIGN KEY(id_prog_especia)            REFERENCES tab_prog_especiales(id_prog_especial),
    FOREIGN KEY(id_nuevo_sector)            REFERENCES tab_sectores(id_sector)
);
-- Se debe tener en cuenta la validaciòn acerca de:
-- Un ambiente no puede ser asignado a dos fichas al mismo tiempo en la misma jornada
-- Un Instructor no puede orientar dos fichas ni competencias al mismo tiempo en la misma jornada
-- Un ambiente debe estar disponible. Validar los indicadores ind_disponible_man/tar/noc de tab_ambientes

-- Tabla de aprendices
CREATE TABLE tab_aprendices
(
    id_aprendiz             DECIMAL(10,0)   NOT NULL,
    datos_aprendiz          datos_personales_aprndiz,
    ind_etdo_formacion      DECIMAL(1,0)    NOT NULL, -- 1=En formación / 2=Aplazado /  3=Retiro Vol. /4=Cancelado / 5=Condicionado / 6=Suspendido / 7= Desertado
    usr_insert              VARCHAR         NOT NULL,
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR,
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_aprendiz)
);

-- Tabla de aprendices por ficha
CREATE TABLE tab_aprendices_fichas
(
    id_ficha                DECIMAL(10,0)   NOT NULL,
    id_aprendiz             DECIMAL(10,0)   NOT NULL,
    usr_insert              VARCHAR         NOT NULL,
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR,
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_ficha,id_aprendiz),
    FOREIGN KEY(id_ficha)                   REFERENCES tab_fichas(id_ficha),
    FOREIGN KEY(id_aprendiz)                REFERENCES tab_aprendices(id_aprendiz),
);

CREATE TABLE tab_ausencias_aprendiz
(
    id_aprendiz             DECIMAL(10,0)   NOT NULL,
    fec_ausencia            DATE            NOT NULL    DEFAULT '1900-01-01' CHECK (fec_ausencia <= CURENT_DATE),
    val_motivo              TEXT            NOT NULL    DEFAULT 'Sin Motivo Ausencia Aprendiz'
    ind_evidencia_excusa    BOOLEAN         NOT NULL    DEFAULT TRUE,   -- TRUE=Hay evidencia / FALSE=Nol hay evidencia
    val_ruta_excusa         VARCHAR         NOT NULL    DEFAULT 'Sin ruta evidencia Aprendiz'
    usr_insert              VARCHAR         NOT NULL,
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR,
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_aprendiz,fec_ausencia),
    FOREIGN KEY(id_aprendiz)                REFERENCES tab_aprendices(id_aprendiz)
);

-- TABLA DE OFERTAS TRIMESTRALES
CREATE TABLE tab_ofertas
(
    id_oferta               SMALLINT        NOT NULL,
    ano_oferta              DECIMAL(4,0)    NOT NULL,
    trim_oferta             DECIMAL(1,0)    NOT NULL,
    num_oferta              DECIMAL(1,0)    NOT NULL,
    ind_tipo_oferta         BOOLEAN         NOT NULL DEFAULT TRUE,  --TRUE=Presencial / FALSE=Virtual)
    usr_insert              VARCHAR         NOT NULL,
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR,
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_oferta)
);

-- Tabla de competencias por Ficha
CREATE TABLE tab_compet_ficha
(
    id_ficha                DECIMAL(10,0)   NOT NULL,
    id_competencia          DECIMAL(10,0)   NOT NULL,
    ind_estado              DECIMAL(1,0)    NOT NULL    CHECK(ind_estado >= 0 AND ind_estado <= 3), --0=No vista / 1=En curso / 2=Vista
    usr_insert              VARCHAR         NOT NULL,
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR,
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_ficha,id_competencia)
    FOREIGN KEY(id_ficha)               REFERENCES tab_fichas(id_ficha),
    FOREIGN KEY(id_competencia)         REFERENCES tab_competencias(id_competencia),
);

-- Tabla de rutas de formación. Se le asociará un CRUD específico y trato especial
-- Tabla de rutas
CREATE TABLE tab_rutas
(
    id_ruta                 DECIMAL(8,0)    NOT NULL,
    id_ficha                DECIMAL(10,0)   NOT NULL,
    nom_ruta                VARCHAR         NOT NULL,
    usr_insert              VARCHAR         NOT NULL,
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR,
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
CREATE TABLE tab_programacion
(
    id_ruta                 DECIMAL(8,0)    NOT NULL,
    id_ficha                DECIMAL(10,0)   NOT NULL,
    id_fase                 DECIMAL(1,0)    NOT NULL, -- 1=Inducción, 2=Planeación, 3=Análisis, 4= Ejecución, 5=Evaluación
    id_competencia          DECIMAL(8,0)    NOT NULL,
    id_instructor           DECIMAL(10,0)   NOT NULL,
    ind_jornada             DECIMAL(1,0)    NOT NULL    CHECK(ind_jornada >= 1 AND ind_jornada <= 3), -- 1=Mañana / 2=Tarde /3=Noche
    fec_inicial             DATE            NOT NULL,
    fec_final               DATE            NOT NULL,
    usr_insert              VARCHAR         NOT NULL,
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR,
    fec_update              TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY(id_ruta,id_ficha,id_competencia,id_instructor),
    FOREIGN KEY(id_ficha)                   REFERENCES tab_fichas(id_ficha),
    FOREIGN KEY(id_competencia)             REFERENCES tab_competencias(id_competencia),
    FOREIGN KEY(id_instructor)              REFERENCES tab_instructores(id_instructor)
);

-- Tabla de transacciones de una ruta, por competencia
CREATE TABLE tab_prog_competencia
(
    id_ruta                 DECIMAL(8,0)    NOT NULL,
    id_ficha                DECIMAL(10,0)   NOT NULL,
    id_fase                 DECIMAL(1,0)    NOT NULL,
    id_competencia          DECIMAL(8,0)    NOT NULL,
    id_instructor           DECIMAL(10,0)   NOT NULL,
    id_actividad            DECIMAL(10,0)  	NOT NULL,
    id_rap                  DECIMAL(10,0)   NOT NULL,
    val_dias                DECIMAL(2,0)    NOT NULL    DEFAULT 6,
    fec_inicio              DATE            NOT NULL,
    fec_final               DATE            NOT NULL,
    usr_insert              VARCHAR         NOT NULL,
    fec_insert              TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update              VARCHAR,
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
CREATE TABLE tab_borrados
(
    id_consec       INTEGER     NOT NULL,
    nom_tabla       VARCHAR     NOT NULL,
    usr_insert      VARCHAR     NOT NULL,
    fec_insert      TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    PRIMARY KEY(id_consec)
);

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

-- Triggers para la auditoría en todas las tablas
CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_pmtros
FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();

CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_programacion
FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();

CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_aprendices_fichas
FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();

CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_prog_competencia
FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();

CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_aprendices
FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();

CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_rutas
FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();

CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_fichas
FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();

CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_ambientes
FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();

CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_sedes
FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();

CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_instructores
FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();

CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_evid_rap
FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();

CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_evidencias
FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();

CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_raps
FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();

CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_adi_contratos_instructor
FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();

CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_contratos_instructor
FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();

CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_profesiones
FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();

CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_ciudades
FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();

CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_dptos
FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();

CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_competencias
FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();

CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_activ_proyecto
FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();

CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_proyectos
FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();

CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_programas
FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();

CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_redes
FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();

CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_centros
FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();

CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_regionales
FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();

CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_adi_contratos_instructor
FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();

CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_compet_instructor
FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();

CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_compet_ficha
FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();

CREATE OR REPLACE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_pmtros
FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();

CREATE OR REPLACE TRIGGER tri_del_tabla AFTER DELETE ON tab_programacion
FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();

CREATE OR REPLACE TRIGGER tri_del_tabla AFTER DELETE ON tab_aprendices_fichas
FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();

CREATE OR REPLACE TRIGGER tri_del_tabla AFTER DELETE ON tab_ambientes
FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();

CREATE OR REPLACE TRIGGER tri_del_tabla AFTER DELETE ON  tab_prog_competencia
FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();

CREATE OR REPLACE TRIGGER tri_del_tabla AFTER DELETE ON tab_aprendices
FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();

CREATE OR REPLACE TRIGGER tri_del_tabla AFTER DELETE ON tab_rutas
FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();

CREATE OR REPLACE TRIGGER tri_del_tabla AFTER DELETE ON tab_fichas
FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();

CREATE OR REPLACE TRIGGER tri_del_tabla AFTER DELETE ON tab_sedes
FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();

CREATE OR REPLACE TRIGGER tri_del_tabla AFTER DELETE ON tab_instructores
FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();

CREATE OR REPLACE TRIGGER tri_del_tabla AFTER DELETE ON tab_evid_rap
FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();

CREATE OR REPLACE TRIGGER tri_del_tabla AFTER DELETE ON tab_evidencias
FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();

CREATE OR REPLACE TRIGGER tri_del_tabla AFTER DELETE ON tab_raps
FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();

CREATE OR REPLACE TRIGGER tri_del_tabla AFTER DELETE ON tab_adi_contratos_instructor
FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();

CREATE OR REPLACE TRIGGER tri_del_tabla AFTER DELETE ON tab_contratos_instructor
FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();

CREATE OR REPLACE TRIGGER tri_del_tabla AFTER DELETE ON tab_profesiones
FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();

CREATE OR REPLACE TRIGGER tri_del_tabla AFTER DELETE ON tab_ciudades
FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();

CREATE OR REPLACE TRIGGER tri_del_tabla AFTER DELETE ON tab_dptos
FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();

CREATE OR REPLACE TRIGGER tri_del_tabla AFTER DELETE ON tab_competencias
FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();

CREATE OR REPLACE TRIGGER tri_del_tabla AFTER DELETE ON tab_activ_proyecto
FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();

CREATE OR REPLACE TRIGGER tri_del_tabla AFTER DELETE ON tab_proyectos
FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();

CREATE OR REPLACE TRIGGER tri_del_tabla AFTER DELETE ON tab_programas
FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();

CREATE OR REPLACE TRIGGER tri_del_tabla AFTER DELETE ON tab_redes
FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();

CREATE OR REPLACE TRIGGER tri_del_tabla AFTER DELETE ON tab_centros
FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();

CREATE OR REPLACE TRIGGER tri_del_tabla AFTER DELETE ON tab_regionales
FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();

CREATE OR REPLACE TRIGGER tri_del_tabla AFTER DELETE ON tab_adi_contratos_instructor
FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();

CREATE OR REPLACE TRIGGER tri_del_tabla AFTER DELETE ON tab_compet_instructor
FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();

CREATE OR REPLACE TRIGGER tri_del_tabla AFTER DELETE ON tab_compet_ficha
FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();