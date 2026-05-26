-- Bootstrap mínimo SMARTCSET — módulo ingreso/egreso (desarrollo)
-- PostgreSQL 14+

CREATE DOMAIN mail_personal AS VARCHAR(255)
    CHECK (VALUE ~* '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$');

-- Maestras geográficas e institucionales mínimas
CREATE TABLE IF NOT EXISTS tab_dptos (
    id_dpto VARCHAR(2) NOT NULL,
    nom_dpto VARCHAR NOT NULL,
    usr_insert VARCHAR NOT NULL,
    fec_insert TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update VARCHAR,
    fec_update TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY (id_dpto)
);

CREATE TABLE IF NOT EXISTS tab_ciudades (
    id_ciudad VARCHAR(5) NOT NULL,
    nom_ciudad VARCHAR NOT NULL,
    id_dpto VARCHAR(2) NOT NULL,
    usr_insert VARCHAR NOT NULL,
    fec_insert TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update VARCHAR,
    fec_update TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY (id_ciudad),
    FOREIGN KEY (id_dpto) REFERENCES tab_dptos (id_dpto)
);

CREATE TABLE IF NOT EXISTS tab_tipos_docum (
    id_tipo_docum VARCHAR(3) NOT NULL,
    nom_tipo_docum VARCHAR NOT NULL,
    usr_insert VARCHAR NOT NULL,
    fec_insert TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update VARCHAR,
    fec_update TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY (id_tipo_docum)
);

CREATE TABLE IF NOT EXISTS tab_niveles_estudio (
    id_nivel_estudio DECIMAL(2,0) NOT NULL,
    nom_nivel_estudio VARCHAR NOT NULL,
    usr_insert VARCHAR NOT NULL,
    fec_insert TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update VARCHAR,
    fec_update TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY (id_nivel_estudio)
);

CREATE TABLE IF NOT EXISTS tab_profesiones (
    id_profesion VARCHAR NOT NULL,
    nom_profesion VARCHAR NOT NULL,
    usr_insert VARCHAR NOT NULL,
    fec_insert TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update VARCHAR,
    fec_update TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY (id_profesion)
);

CREATE TABLE IF NOT EXISTS tab_tipos_persona (
    id_tipo_persona DECIMAL(2,0) NOT NULL,
    nom_tipo_persona VARCHAR NOT NULL,
    usr_insert VARCHAR NOT NULL,
    fec_insert TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update VARCHAR,
    fec_update TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY (id_tipo_persona)
);

CREATE TABLE IF NOT EXISTS tab_usuarios (
    id_usuario VARCHAR NOT NULL CHECK (LENGTH(id_usuario) >= 5),
    nom_usuario VARCHAR NOT NULL CHECK (LENGTH(nom_usuario) >= 8),
    pass_usuario VARCHAR NOT NULL CHECK (LENGTH(pass_usuario) >= 12),
    mail_usuario mail_personal NOT NULL,
    ind_usuario BOOLEAN NOT NULL DEFAULT FALSE,
    ind_estado BOOLEAN NOT NULL DEFAULT TRUE,
    usr_insert VARCHAR NOT NULL,
    fec_insert TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update VARCHAR,
    fec_update TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY (id_usuario)
);

CREATE TABLE IF NOT EXISTS tab_personas (
    id_persona DECIMAL(10,0) NOT NULL,
    id_tipo_docum VARCHAR(2) NOT NULL DEFAULT 'CC',
    id_tipo_persona DECIMAL(2,0) NOT NULL,
    nom_persona VARCHAR NOT NULL,
    ape_persona VARCHAR NOT NULL,
    mail_persona mail_personal NOT NULL DEFAULT 'sin.correo@ejemplo.com',
    fec_nacimiento DATE NOT NULL DEFAULT '1900-01-01',
    ind_genero DECIMAL(2,0) NOT NULL,
    val_huella_digital BYTEA,
    val_patron_facial JSONB,
    fec_ultima_entrada TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    fec_ultima_salida TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    num_visitas SMALLINT NOT NULL DEFAULT 0,
    id_nivel_estudio DECIMAL(2,0) NOT NULL,
    id_profesion VARCHAR NOT NULL,
    id_dpto_reside VARCHAR(2) NOT NULL,
    id_ciudad_reside VARCHAR(5) NOT NULL,
    dir_ciudad_reside VARCHAR NOT NULL,
    tel_persona_fijo DECIMAL(10,0) NOT NULL,
    tel_persona_movil DECIMAL(10,0) NOT NULL,
    nom_contacto_emergencias DECIMAL(10,0) NOT NULL,
    tel_contacto_emergencias DECIMAL(10,0) NOT NULL,
    ind_envio_correo BOOLEAN NOT NULL DEFAULT TRUE,
    ind_estado BOOLEAN NOT NULL DEFAULT TRUE,
    usr_insert VARCHAR NOT NULL,
    fec_insert TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update VARCHAR,
    fec_update TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY (id_persona),
    FOREIGN KEY (id_tipo_docum) REFERENCES tab_tipos_docum (id_tipo_docum),
    FOREIGN KEY (id_tipo_persona) REFERENCES tab_tipos_persona (id_tipo_persona),
    FOREIGN KEY (id_nivel_estudio) REFERENCES tab_niveles_estudio (id_nivel_estudio),
    FOREIGN KEY (id_profesion) REFERENCES tab_profesiones (id_profesion),
    FOREIGN KEY (id_dpto_reside) REFERENCES tab_dptos (id_dpto),
    FOREIGN KEY (id_ciudad_reside) REFERENCES tab_ciudades (id_ciudad)
);

CREATE TABLE IF NOT EXISTS tab_metodos_aut (
    id_metodo_aut DECIMAL(2,0) NOT NULL,
    nom_metodo_aut VARCHAR NOT NULL,
    usr_insert VARCHAR NOT NULL,
    fec_insert TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update VARCHAR,
    fec_update TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY (id_metodo_aut)
);

CREATE TABLE IF NOT EXISTS tab_entradas_centro (
    id_entrada_centro DECIMAL(1,0) NOT NULL,
    nom_entrada_centro VARCHAR NOT NULL,
    usr_insert VARCHAR NOT NULL,
    fec_insert TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update VARCHAR,
    fec_update TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY (id_entrada_centro)
);

CREATE TABLE IF NOT EXISTS tab_log_ingresos (
    id_ingreso INTEGER NOT NULL,
    id_visitante DECIMAL(10,0) NOT NULL,
    fec_ingreso TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fec_salida TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    id_metodo_aut DECIMAL(2,0) NOT NULL,
    id_entrada_centro DECIMAL(1,0) NOT NULL,
    val_datos_origen JSONB,
    val_observaciones TEXT,
    usr_insert VARCHAR NOT NULL,
    fec_insert TIMESTAMP WITHOUT TIME ZONE NOT NULL,
    usr_update VARCHAR,
    fec_update TIMESTAMP WITHOUT TIME ZONE,
    PRIMARY KEY (id_ingreso),
    FOREIGN KEY (id_visitante) REFERENCES tab_personas (id_persona),
    FOREIGN KEY (id_metodo_aut) REFERENCES tab_metodos_aut (id_metodo_aut),
    FOREIGN KEY (id_entrada_centro) REFERENCES tab_entradas_centro (id_entrada_centro)
);

CREATE INDEX IF NOT EXISTS idx_fec_ingresos ON tab_log_ingresos (fec_ingreso DESC);

CREATE UNIQUE INDEX IF NOT EXISTS idx_log_ingreso_persona_abierto
    ON tab_log_ingresos (id_visitante)
    WHERE (fec_salida = fec_ingreso);

CREATE SEQUENCE IF NOT EXISTS seq_log_ingresos START WITH 1 INCREMENT BY 1;

CREATE OR REPLACE FUNCTION fun_act_tabla() RETURNS trigger AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        NEW.usr_insert := COALESCE(NEW.usr_insert, CURRENT_USER);
        NEW.fec_insert := COALESCE(NEW.fec_insert, CURRENT_TIMESTAMP);
        RETURN NEW;
    END IF;
    IF TG_OP = 'UPDATE' THEN
        NEW.usr_update := CURRENT_USER;
        NEW.fec_update := CURRENT_TIMESTAMP;
        RETURN NEW;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS tri_act_tabla ON tab_usuarios;
CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_usuarios
    FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();

DROP TRIGGER IF EXISTS tri_act_tabla ON tab_personas;
CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_personas
    FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();

DROP TRIGGER IF EXISTS tri_act_tabla ON tab_metodos_aut;
CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_metodos_aut
    FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();

DROP TRIGGER IF EXISTS tri_act_tabla ON tab_entradas_centro;
CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_entradas_centro
    FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();

DROP TRIGGER IF EXISTS tri_act_tabla ON tab_log_ingresos;
CREATE TRIGGER tri_act_tabla BEFORE INSERT OR UPDATE ON tab_log_ingresos
    FOR EACH ROW EXECUTE PROCEDURE fun_act_tabla();
