-- Registro completo de persona en tab_personas (módulo registro, formulario base).
CREATE OR REPLACE FUNCTION fun_registrar_persona(
    wid_persona                 tab_personas.id_persona%TYPE,
    wid_tipo_docum              tab_personas.id_tipo_docum%TYPE,
    wid_tipo_persona            tab_personas.id_tipo_persona%TYPE,
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
    wind_estado                 tab_personas.ind_estado%TYPE,
    wusr                        tab_personas.usr_insert%TYPE
) RETURNS TEXT AS $$
DECLARE
    wmail_norm TEXT;
BEGIN
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

    IF wid_tipo_persona IS NULL OR wid_tipo_persona < 1 THEN
        PERFORM smartcset_raise_validacion('Seleccione el tipo de persona.');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM tab_tipos_persona
        WHERE id_tipo_persona = wid_tipo_persona AND id_tipo_persona <> 99
    ) THEN
        PERFORM smartcset_raise_validacion(
            'El tipo de persona no es válido.',
            'id_tipo_persona=' || COALESCE(wid_tipo_persona::TEXT, 'NULL')
        );
    END IF;

    IF LENGTH(TRIM(COALESCE(wnom_persona, ''))) < 3 THEN
        PERFORM smartcset_raise_validacion('Los nombres deben tener al menos 3 caracteres.');
    END IF;

    IF LENGTH(TRIM(COALESCE(wape_persona, ''))) < 2 THEN
        PERFORM smartcset_raise_validacion('Los apellidos deben tener al menos 2 caracteres.');
    END IF;

    wmail_norm := LOWER(TRIM(COALESCE(wmail_persona, '')));
    IF wmail_norm = '' OR wmail_norm !~* '^[A-Za-z0-9._%-]+@[A-Za-z0-9.-]+[.][A-Za-z]+$' THEN
        PERFORM smartcset_raise_validacion(
            'El correo personal no tiene un formato válido.',
            'Use una dirección como nombre@dominio.com'
        );
    END IF;

    IF wfec_nacimiento IS NULL THEN
        PERFORM smartcset_raise_validacion('La fecha de nacimiento es obligatoria.');
    END IF;

    IF wfec_nacimiento > CURRENT_DATE THEN
        PERFORM smartcset_raise_validacion('La fecha de nacimiento no puede ser futura.');
    END IF;

    IF wfec_nacimiento < DATE '1900-01-01' THEN
        PERFORM smartcset_raise_validacion('La fecha de nacimiento no es válida.');
    END IF;

    IF wind_genero IS NULL OR wind_genero < 1 THEN
        PERFORM smartcset_raise_validacion('Seleccione el género.');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM tab_niveles_estudio WHERE id_nivel_estudio = wid_nivel_estudio
    ) THEN
        PERFORM smartcset_raise_validacion('El nivel de estudio seleccionado no es válido.');
    END IF;

    IF wid_profesion IS NULL OR TRIM(wid_profesion) = '' THEN
        PERFORM smartcset_raise_validacion('Seleccione la profesión.');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM tab_profesiones WHERE id_profesion = wid_profesion
    ) THEN
        PERFORM smartcset_raise_validacion('La profesión seleccionada no es válida.');
    END IF;

    IF wid_dpto_reside IS NULL OR TRIM(wid_dpto_reside) = '' THEN
        PERFORM smartcset_raise_validacion('Seleccione el departamento de residencia.');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM tab_dptos WHERE id_dpto = wid_dpto_reside
    ) THEN
        PERFORM smartcset_raise_validacion('El departamento de residencia no es válido.');
    END IF;

    IF wid_ciudad_reside IS NULL OR TRIM(wid_ciudad_reside) = '' THEN
        PERFORM smartcset_raise_validacion('Seleccione la ciudad de residencia.');
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM tab_ciudades
        WHERE id_ciudad = wid_ciudad_reside AND id_dpto = wid_dpto_reside
    ) THEN
        PERFORM smartcset_raise_validacion(
            'La ciudad no corresponde al departamento seleccionado.'
        );
    END IF;

    IF LENGTH(TRIM(COALESCE(wdir_ciudad_reside, ''))) < 10 THEN
        PERFORM smartcset_raise_validacion('La dirección debe tener al menos 10 caracteres.');
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

    IF LENGTH(TRIM(COALESCE(wnom_contacto_emergencias, ''))) < 5 THEN
        PERFORM smartcset_raise_validacion(
            'El nombre del contacto de emergencias debe tener al menos 5 caracteres.'
        );
    END IF;

    IF wtel_contacto_emergencias IS NULL
       OR wtel_contacto_emergencias < 3000000000
       OR wtel_contacto_emergencias > 3519999999 THEN
        PERFORM smartcset_raise_validacion(
            'El teléfono de emergencias debe ser un celular colombiano válido.'
        );
    END IF;

    IF wusr IS NULL OR LENGTH(TRIM(wusr)) < 3 THEN
        PERFORM smartcset_raise_validacion('No se pudo identificar el usuario de registro.');
    END IF;

    IF EXISTS (SELECT 1 FROM tab_personas WHERE id_persona = wid_persona) THEN
        PERFORM smartcset_raise_negocio(
            'Ya existe una persona registrada con ese número de documento.'
        );
    END IF;

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
        wid_persona, wid_tipo_docum, wid_tipo_persona,
        TRIM(wnom_persona), TRIM(wape_persona), wmail_norm::mail_personal,
        wfec_nacimiento, wind_genero,
        CURRENT_TIMESTAMP, CURRENT_TIMESTAMP,
        wid_nivel_estudio, wid_profesion,
        wid_dpto_reside, wid_ciudad_reside, TRIM(wdir_ciudad_reside),
        wtel_persona_fijo, wtel_persona_movil,
        TRIM(wnom_contacto_emergencias), wtel_contacto_emergencias,
        COALESCE(wind_envio_correo, FALSE), COALESCE(wind_estado, TRUE),
        TRIM(wusr), CURRENT_TIMESTAMP
    );

    RETURN wid_persona::TEXT;
EXCEPTION
    WHEN SQLSTATE 'P0001' THEN
        RAISE;
    WHEN OTHERS THEN
        PERFORM smartcset_handle_sql_error();
END;
$$ LANGUAGE plpgsql;
