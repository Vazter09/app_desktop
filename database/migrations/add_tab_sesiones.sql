-- Sesiones de aplicación (no incluida en script_BD_SMARTCSET V.1.5)
CREATE TABLE IF NOT EXISTS tab_sesiones (
    id_usuario    VARCHAR NOT NULL PRIMARY KEY,
    token_sesion  VARCHAR NOT NULL,
    fec_inicio    TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ult_actividad TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (id_usuario) REFERENCES tab_usuarios (id_usuario)
);
