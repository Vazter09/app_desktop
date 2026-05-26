-- Procedimiento almacenado para insertar un aprendiz y su información básica
CREATE OR REPLACE FUNCTION fun_insert_aprendiz(
    p_id_persona               DECIMAL(10,0),
    p_id_tipo_persona          DECIMAL(2,0)    DEFAULT 1,
    p_id_tipo_docum            VARCHAR(3),
    p_nom_persona              VARCHAR,
    p_ape_persona              VARCHAR,
    p_mail_persona             mail_personal,
    p_fec_nacimiento           DATE,
    p_ind_genero               DECIMAL(2,0),
    p_id_nivel_estudio         DECIMAL(2,0),
    p_id_profesion             VARCHAR,
    p_id_dpto_reside           VARCHAR(2),
    p_id_ciudad_reside         VARCHAR(5),
    p_dir_ciudad_reside        VARCHAR,
    p_tel_persona_fijo         DECIMAL(10,0),
    p_tel_persona_movil        DECIMAL(10,0),
    p_nom_contacto_emergencias VARCHAR,
    p_tel_contacto_emergencias DECIMAL(10,0),
    p_ind_envio_correo         BOOLEAN        DEFAULT TRUE,
    p_ind_estado               BOOLEAN        DEFAULT TRUE,
    p_usr_insert               VARCHAR,
    p_tel_alterno              DECIMAL(10,0)  DEFAULT NULL,
    p_tel_sede                 DECIMAL(10,0)  DEFAULT NULL,
    p_ext_sede                 DECIMAL(4,0)   DEFAULT NULL,
    p_tel_padre_fijo           DECIMAL(10,0)  DEFAULT NULL,
    p_tel_padre_movil          DECIMAL(10,0)  DEFAULT NULL,
    p_val_mail_institucional   mail_personal   DEFAULT NULL,
    p_ind_etdo_formacion       DECIMAL(1,0)   DEFAULT 1,
    p_id_ficha                 DECIMAL(10,0)  DEFAULT NULL
) RETURNS VOID AS
$$
BEGIN
    INSERT INTO tab_personas (
        id_persona, id_tipo_docum, id_tipo_persona,
        nom_persona, ape_persona, mail_persona,
        fec_nacimiento, ind_genero,
        fec_ultima_entrada, fec_ultima_salida,
        id_nivel_estudio, id_profesion,
        id_dpto_reside, id_ciudad_reside, dir_ciudad_reside,
        tel_persona_fijo, tel_persona_movil,
        nom_contacto_emergencias, tel_contacto_emergencias,
        ind_envio_correo, ind_estado,
        usr_insert, fec_insert
    ) VALUES (
        p_id_persona, p_id_tipo_docum, p_id_tipo_persona,
        p_nom_persona, p_ape_persona, p_mail_persona,
        p_fec_nacimiento, p_ind_genero,
        NOW(), NOW(),
        p_id_nivel_estudio, p_id_profesion,
        p_id_dpto_reside, p_id_ciudad_reside, p_dir_ciudad_reside,
        p_tel_persona_fijo, p_tel_persona_movil,
        p_nom_contacto_emergencias, p_tel_contacto_emergencias,
        p_ind_envio_correo, p_ind_estado,
        p_usr_insert, NOW()
    );

    INSERT INTO tab_aprendices (
        id_aprendiz, datos_aprendiz,
        ind_etdo_formacion, num_llamados,
        usr_insert, fec_insert
    ) VALUES (
        p_id_persona,
        ROW(
            p_tel_alterno,
            p_tel_sede,
            p_ext_sede,
            p_tel_padre_fijo,
            p_tel_padre_movil,
            p_val_mail_institucional,
            p_nom_contacto_emergencias,
            p_tel_contacto_emergencias
        )::datos_personales_aprendiz,
        p_ind_etdo_formacion,
        0,
        p_usr_insert,
        NOW()
    );

    IF p_id_ficha IS NOT NULL THEN
        INSERT INTO tab_aprendices_fichas (
            id_ficha, id_aprendiz,
            usr_insert, fec_insert
        ) VALUES (
            p_id_ficha, p_id_persona,
            p_usr_insert, NOW()
        );
    END IF;
END;
$$ LANGUAGE plpgsql;
