-- Dispositivos portería (tablets APK) + idempotencia sync offline
CREATE TABLE IF NOT EXISTS tab_dispositivos_porteria (
    id_dispositivo   SERIAL PRIMARY KEY,
    nom_dispositivo  VARCHAR(100) NOT NULL,
    token_hash       TEXT NOT NULL,
    id_usuario_audit VARCHAR NOT NULL,
    id_entrada_default NUMERIC NULL,
    ind_activo       BOOLEAN NOT NULL DEFAULT TRUE,
    fec_ultimo_uso   TIMESTAMP NULL,
    usr_insert       VARCHAR(50) NOT NULL DEFAULT 'system',
    fec_insert       TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    usr_update       VARCHAR(50) NULL,
    fec_update       TIMESTAMP NULL,
    CONSTRAINT fk_disp_porteria_usuario
        FOREIGN KEY (id_usuario_audit) REFERENCES tab_usuarios (id_usuario)
);

CREATE INDEX IF NOT EXISTS idx_disp_porteria_activo
    ON tab_dispositivos_porteria (ind_activo)
    WHERE ind_activo = TRUE;

CREATE TABLE IF NOT EXISTS tab_porteria_sync_client (
    client_id        UUID PRIMARY KEY,
    id_dispositivo   INTEGER NOT NULL,
    tipo_operacion   VARCHAR(10) NOT NULL,
    id_ingreso       NUMERIC NOT NULL,
    fec_sync         TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_sync_client_dispositivo
        FOREIGN KEY (id_dispositivo) REFERENCES tab_dispositivos_porteria (id_dispositivo),
    CONSTRAINT chk_sync_tipo_operacion
        CHECK (tipo_operacion IN ('ingreso', 'salida'))
);

CREATE INDEX IF NOT EXISTS idx_sync_client_dispositivo
    ON tab_porteria_sync_client (id_dispositivo, fec_sync DESC);
