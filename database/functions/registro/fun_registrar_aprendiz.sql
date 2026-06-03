-- Registro atómico de aprendiz: tab_personas + tab_aprendices + tab_aprendices_fichas (opcional).
-- id_tipo_persona fijo = 2 (Aprendiz). Retorna id_persona registrado (TEXT).
CREATE OR REPLACE FUNCTION fun_registrar_aprendiz(
    wid_persona                 tab_personas.id_persona%TYPE,
    wid_tipo_docum              tab_personas.id_tipo_docum%TYPE,
    wnom_persona                tab_personas.nom_persona%TYPE,
    wape_persona                tab_personas.ape_persona%TYPE,
    wmail_persona               tab_personas.mail_persona%TYPE,
    wfec_nacimiento             tab_personas.fec_nacimiento%TYPE,
    wind_genero                 tab_personas.ind_genero%TYPE,
    wid_nivel_estudio           tab_personas.id_nivel_estudio%TYPE,
    wid_profesion               tab_personas.id_profesion%TYPE,
    wid_dpto_reside             tab_personas.id_dpto_reside%TYPE,
    wid_ciudad_reside           tab_personas.id_ciudad_reside%TYPE,
    wdir_ciudad_reside          tab_personas.dir_ciudad_reside%TYPE,
    wtel_persona_fijo           tab_personas.tel_persona_fijo%TYPE,
    wtel_persona_movil          tab_personas.tel_persona_movil%TYPE,
    wnom_contacto_emergencias   tab_personas.nom_contacto_emergencias%TYPE,
    wtel_contacto_emergencias   tab_personas.tel_contacto_emergencias%TYPE,
    wind_envio_correo           tab_personas.ind_envio_correo%TYPE,
    wtel_alterno                telefono_movil,
    wtel_sede                   telefono_fijo,
    wext_sede                   extension,
    wtel_padre_fijo             telefono_fijo,
    wtel_padre_movil            telefono_movil,
    wval_mail_institucional     mail_personal,
    wind_etdo_formacion         tab_aprendices.ind_etdo_formacion%TYPE,
    wusr                        VARCHAR,
    wid_ficha                   tab_aprendices_fichas.id_ficha%TYPE DEFAULT NULL
) RETURNS TEXT AS $$
DECLARE
    v_tipo_aprendiz CONSTANT DECIMAL(2,0) := 2;
    v_nom           VARCHAR(40);
    v_ape           VARCHAR(30);
    v_dir           VARCHAR(100);
    v_contacto      VARCHAR(60);
    v_mail_norm     TEXT;
    v_datos         datos_personales_aprendiz;
BEGIN
    IF wusr IS NULL OR LENGTH(TRIM(wusr)) < 3 THEN
        PERFORM smartcset_raise_validacion('El usuario de auditoría no es válido.');
    END IF;

    IF wid_persona IS NULL OR wid_persona < 1 THEN
        PERFORM smartcset_raise_validacion(
            'El número de documento no es válido.',
            'id_persona=' || COALESCE(wid_persona::TEXT, 'NULL')
        );
    END IF;

    IF wid_tipo_docum IS NULL OR TRIM(wid_tipo_docum) = '' THEN
        PERFORM smartcset_raise_validacion('Seleccione el tipo de documento.');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM tab_tipos_docum WHERE id_tipo_docum = wid_tipo_docum
    ) THEN
        PERFORM smartcset_raise_validacion(
            'El tipo de documento no está registrado en el sistema.',
            'id_tipo_docum=' || wid_tipo_docum
        );
    END IF;

    IF EXISTS (SELECT 1 FROM tab_personas WHERE id_persona = wid_persona) THEN
        PERFORM smartcset_raise_negocio(
            'Ya existe una persona registrada con ese número de documento.',
            'id_persona=' || wid_persona::TEXT,
            'Consulte el listado administrativo o use otro documento.'
        );
    END IF;

    IF EXISTS (SELECT 1 FROM tab_aprendices WHERE id_aprendiz = wid_persona) THEN
        PERFORM smartcset_raise_negocio(
            'Ya existe un aprendiz registrado con ese número de documento.',
            'id_aprendiz=' || wid_persona::TEXT
        );
    END IF;

    v_nom := TRIM(wnom_persona);
    v_ape := TRIM(wape_persona);
    IF LENGTH(v_nom) < 3 OR LENGTH(v_ape) < 2 THEN
        PERFORM smartcset_raise_validacion(
            'Nombres (mín. 3 caracteres) y apellidos (mín. 2) son obligatorios.'
        );
    END IF;

    v_mail_norm := LOWER(TRIM(COALESCE(wmail_persona::TEXT, '')));
    IF v_mail_norm = '' OR v_mail_norm !~* '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$' THEN
        PERFORM smartcset_raise_validacion(
            'El correo personal no tiene un formato válido.',
            'Use una dirección como nombre@dominio.com'
        );
    END IF;

    IF wfec_nacimiento IS NULL THEN
        PERFORM smartcset_raise_validacion('La fecha de nacimiento es obligatoria.');
    END IF;

    IF wfec_nacimiento > CURRENT_DATE OR wfec_nacimiento < DATE '1900-01-01' THEN
        PERFORM smartcset_raise_validacion('La fecha de nacimiento no es válida.');
    END IF;

    IF wind_genero IS NULL OR wind_genero NOT IN (1, 2, 3, 4) THEN
        PERFORM smartcset_raise_validacion('Seleccione un género válido.');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM tab_niveles_estudio WHERE id_nivel_estudio = wid_nivel_estudio
    ) THEN
        PERFORM smartcset_raise_validacion('El nivel de estudio seleccionado no es válido.');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM tab_profesiones WHERE id_profesion = wid_profesion
    ) THEN
        PERFORM smartcset_raise_validacion('La profesión u oficio seleccionado no es válido.');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM tab_dptos WHERE id_dpto = wid_dpto_reside
    ) THEN
        PERFORM smartcset_raise_validacion('El departamento de residencia no es válido.');
    END IF;

    IF NOT EXISTS (
        SELECT 1
          FROM tab_ciudades
         WHERE id_ciudad = wid_ciudad_reside
           AND id_dpto = wid_dpto_reside
    ) THEN
        PERFORM smartcset_raise_validacion(
            'La ciudad no corresponde al departamento seleccionado.'
        );
    END IF;

    v_dir := TRIM(wdir_ciudad_reside);
    IF LENGTH(v_dir) < 10 THEN
        PERFORM smartcset_raise_validacion(
            'La dirección de residencia debe tener al menos 10 caracteres.'
        );
    END IF;

    IF wtel_persona_fijo IS NULL
       OR wtel_persona_fijo < 6010000000
       OR wtel_persona_fijo > 6089999999 THEN
        PERFORM smartcset_raise_validacion(
            'El teléfono fijo debe ser un número válido de Bogotá o área metropolitana (601xxxxxxx).'
        );
    END IF;

    IF wtel_persona_movil IS NULL
       OR wtel_persona_movil < 3000000000
       OR wtel_persona_movil > 3519999999 THEN
        PERFORM smartcset_raise_validacion(
            'El teléfono móvil debe ser un celular colombiano válido (300xxxxxxx a 351xxxxxxx).'
        );
    END IF;

    v_contacto := TRIM(wnom_contacto_emergencias);
    IF LENGTH(v_contacto) < 5 THEN
        PERFORM smartcset_raise_validacion(
            'El contacto de emergencias debe tener al menos 5 caracteres.'
        );
    END IF;

    IF wtel_contacto_emergencias IS NULL
       OR wtel_contacto_emergencias < 3000000000
       OR wtel_contacto_emergencias > 3519999999 THEN
        PERFORM smartcset_raise_validacion(
            'El teléfono de emergencias debe ser un celular colombiano válido.'
        );
    END IF;

    IF wind_etdo_formacion IS NULL
       OR wind_etdo_formacion NOT IN (1, 2, 3, 4, 5, 6, 7) THEN
        PERFORM smartcset_raise_validacion('Seleccione un estado de formación válido.');
    END IF;

    IF wid_ficha IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM tab_fichas WHERE id_ficha = wid_ficha
    ) THEN
        PERFORM smartcset_raise_validacion(
            'La ficha de formación seleccionada no existe.',
            'id_ficha=' || wid_ficha::TEXT
        );
    END IF;

    v_datos := ROW(
        wtel_alterno,
        wtel_sede,
        wext_sede,
        wtel_padre_fijo,
        wtel_padre_movil,
        wval_mail_institucional,
        v_contacto,
        wtel_contacto_emergencias
    )::datos_personales_aprendiz;

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
        wid_persona, wid_tipo_docum, v_tipo_aprendiz,
        v_nom, v_ape, v_mail_norm::mail_personal,
        wfec_nacimiento, wind_genero,
        CURRENT_TIMESTAMP, CURRENT_TIMESTAMP,
        wid_nivel_estudio, wid_profesion,
        wid_dpto_reside, wid_ciudad_reside, v_dir,
        wtel_persona_fijo, wtel_persona_movil,
        v_contacto, wtel_contacto_emergencias,
        COALESCE(wind_envio_correo, FALSE), TRUE,
        TRIM(wusr), CURRENT_TIMESTAMP
    );

    INSERT INTO tab_aprendices (
        id_aprendiz, datos_aprendiz,
        ind_etdo_formacion, num_llamados,
        usr_insert, fec_insert
    ) VALUES (
        wid_persona, v_datos,
        wind_etdo_formacion, 0,
        TRIM(wusr), CURRENT_TIMESTAMP
    );

    IF wid_ficha IS NOT NULL THEN
        INSERT INTO tab_aprendices_fichas (
            id_ficha, id_aprendiz, usr_insert, fec_insert
        ) VALUES (
            wid_ficha, wid_persona, TRIM(wusr), CURRENT_TIMESTAMP
        );
    END IF;

    RETURN wid_persona::TEXT;
EXCEPTION
    WHEN SQLSTATE 'P0001' THEN
        RAISE;
    WHEN unique_violation THEN
        PERFORM smartcset_raise_negocio('Ya existe un registro con esos datos.');
    WHEN OTHERS THEN
        PERFORM smartcset_handle_sql_error();
END;
$$ LANGUAGE plpgsql;
