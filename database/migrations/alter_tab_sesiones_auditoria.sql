-- Auditoría de sesiones: id_sesion, fec_fin, ubicación, tabla archivo.
-- Idempotente: no recrea tab_sesiones si ya tiene id_sesion.

DROP FUNCTION IF EXISTS fun_ingreso_sesion(TEXT);
DROP FUNCTION IF EXISTS fun_ingreso_sesion(TEXT, TEXT);
DROP FUNCTION IF EXISTS fun_salida_sesion(TEXT);
DROP FUNCTION IF EXISTS fun_salida_sesion(INTEGER, TEXT, TEXT);
DROP FUNCTION IF EXISTS fun_actualizar_sesion_actividad(TEXT);
DROP FUNCTION IF EXISTS fun_actualizar_sesion_actividad(INTEGER, TEXT, TEXT);

DO $$
BEGIN
    IF EXISTS (
        SELECT 1
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = 'tab_sesiones'
          AND column_name = 'id_sesion'
    ) THEN
        RAISE NOTICE 'tab_sesiones ya tiene auditoría (id_sesion); se omite migración estructural.';
        RETURN;
    END IF;

    DROP TABLE IF EXISTS tab_sesiones_archivo;
    DROP TABLE IF EXISTS tab_sesiones;

    CREATE SEQUENCE IF NOT EXISTS seq_sesiones START WITH 1 INCREMENT BY 1;

    CREATE TABLE tab_sesiones
    (
        id_sesion       INTEGER                     NOT NULL DEFAULT nextval('seq_sesiones'),
        id_usuario      VARCHAR(20)                 NOT NULL,
        fec_inicio      TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
        fec_fin         TIMESTAMP WITHOUT TIME ZONE,
        ult_actividad   TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
        ult_ruta        VARCHAR(255),
        ult_menu_id     VARCHAR(20),
        cod_cierre      VARCHAR(20),
        usr_cierre      VARCHAR(50),
        ip_cliente      VARCHAR(45),
        PRIMARY KEY (id_sesion),
        FOREIGN KEY (id_usuario) REFERENCES tab_usuarios (id_usuario)
    );

    CREATE UNIQUE INDEX ux_tab_sesiones_usuario_activa
        ON tab_sesiones (id_usuario) WHERE fec_fin IS NULL;

    CREATE INDEX ix_tab_sesiones_fec_fin ON tab_sesiones (fec_fin, fec_inicio);

    CREATE TABLE tab_sesiones_archivo
    (
        id_sesion       INTEGER                     NOT NULL,
        id_usuario      VARCHAR(20)                 NOT NULL,
        fec_inicio      TIMESTAMP WITHOUT TIME ZONE NOT NULL,
        fec_fin         TIMESTAMP WITHOUT TIME ZONE NOT NULL,
        ult_actividad   TIMESTAMP WITHOUT TIME ZONE NOT NULL,
        ult_ruta        VARCHAR(255),
        ult_menu_id     VARCHAR(20),
        cod_cierre      VARCHAR(20),
        usr_cierre      VARCHAR(50),
        ip_cliente      VARCHAR(45),
        PRIMARY KEY (id_sesion)
    );
END $$;

CREATE SEQUENCE IF NOT EXISTS seq_sesiones START WITH 1 INCREMENT BY 1;

CREATE TABLE IF NOT EXISTS tab_sesiones_archivo
(
    id_sesion       INTEGER                     NOT NULL,
    id_usuario      VARCHAR(20)                 NOT NULL,
    fec_inicio      TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    fec_fin         TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    ult_actividad   TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    ult_ruta        VARCHAR(255),
    ult_menu_id     VARCHAR(20),
    cod_cierre      VARCHAR(20),
    usr_cierre      VARCHAR(50),
    ip_cliente      VARCHAR(45),
    PRIMARY KEY (id_sesion)
);

-- Firmas legacy (PK id_usuario / DELETE al cerrar)
DROP FUNCTION IF EXISTS fun_ingreso_sesion(VARCHAR);
DROP FUNCTION IF EXISTS fun_salida_sesion(VARCHAR);
DROP FUNCTION IF EXISTS fun_actualizar_sesion_actividad(VARCHAR);
