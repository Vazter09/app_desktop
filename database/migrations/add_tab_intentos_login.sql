-- ===================================================================
-- Migración: add_tab_intentos_login
-- Descripción: Tabla de registro de intentos de login para rate
--              limiting. Bloquea por IP tras N intentos fallidos
--              en una ventana de tiempo configurable.
-- Entregable: FASE 1 — E3 (Rate limiting + logging autenticación)
-- ===================================================================

CREATE SEQUENCE IF NOT EXISTS seq_intentos_login
    START WITH 1
    INCREMENT BY 1
    NO MAXVALUE
    CACHE 1;

CREATE TABLE IF NOT EXISTS tab_intentos_login (
    id_intento   INTEGER      NOT NULL DEFAULT nextval('seq_intentos_login'),
    ip_cliente   VARCHAR(45)  NOT NULL,
    id_usuario   VARCHAR(20)  NULL,
    ind_exitoso  BOOLEAN      NOT NULL DEFAULT FALSE,
    motivo_fallo VARCHAR(30)  NULL,
    user_agent   VARCHAR(255) NULL,
    fec_intento  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT tab_intentos_login_pkey PRIMARY KEY (id_intento),
    CONSTRAINT tab_intentos_login_ip_check
        CHECK (LENGTH(TRIM(ip_cliente)) >= 7)
);

-- Columnas de auditoría forense (E3 enriquecido): idempotente para BD ya creadas.
-- motivo_fallo: 'usuario_no_existe' | 'contrasena_incorrecta' | 'usuario_inactivo'
--               (NULL en intentos exitosos). Se valida en fun_registrar_intento_login.
ALTER TABLE tab_intentos_login ADD COLUMN IF NOT EXISTS motivo_fallo VARCHAR(30)  NULL;
ALTER TABLE tab_intentos_login ADD COLUMN IF NOT EXISTS user_agent   VARCHAR(255) NULL;

CREATE INDEX IF NOT EXISTS ix_tab_intentos_login_ip_fec
    ON tab_intentos_login (ip_cliente, fec_intento DESC);

CREATE INDEX IF NOT EXISTS ix_tab_intentos_login_fec
    ON tab_intentos_login (fec_intento DESC);
