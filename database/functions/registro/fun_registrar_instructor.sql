-- Registro atómico de instructor: tab_personas + tab_instructores
-- (+ tab_vehiculos si ind_vehiculo = TRUE).
-- Cambio de aridad (25 → 28): DROP explícito de la firma vieja (Bug 20).
DROP FUNCTION IF EXISTS fun_registrar_instructor(
    NUMERIC, VARCHAR, VARCHAR, VARCHAR, VARCHAR, DATE,
    NUMERIC, NUMERIC, NUMERIC, VARCHAR,
    VARCHAR, VARCHAR, VARCHAR,
    NUMERIC, NUMERIC, VARCHAR, NUMERIC,
    BOOLEAN, NUMERIC, NUMERIC,
    BOOLEAN, BOOLEAN, BOOLEAN, NUMERIC, TEXT
);

CREATE OR REPLACE FUNCTION fun_registrar_instructor(
    wid_persona                 tab_personas.id_persona%TYPE,
    wid_tipo_docum              tab_personas.id_tipo_docum%TYPE,
    wnom_persona                tab_personas.nom_persona%TYPE,
    wape_persona                tab_personas.ape_persona%TYPE,
    wmail_persona               tab_personas.mail_persona%TYPE,
    wfec_nacimiento             tab_personas.fec_nacimiento%TYPE,
    wind_genero                 tab_personas.ind_genero%TYPE,
    wind_est_civil              tab_instructores.ind_est_civil%TYPE,
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
    wid_centro                  tab_instructores.id_centro%TYPE,
    wid_red                     tab_instructores.id_red%TYPE,
    wind_tipo_contrato          tab_instructores.ind_tipo_contrato%TYPE,
    wind_contratado_actual      tab_instructores.ind_contratado_actual%TYPE,
    wind_disponibilidad         tab_instructores.ind_disponibilidad%TYPE,
    wind_estado                 tab_instructores.ind_estado%TYPE,
    wind_vehiculo               tab_instructores.ind_vehiculo%TYPE,
    wid_vehiculo                tab_vehiculos.id_vehiculo%TYPE,
    wind_tipovehiculo           tab_vehiculos.ind_tipovehiculo%TYPE,
    wusr                        tab_personas.usr_insert%TYPE
) RETURNS TEXT AS $$
DECLARE
    wid_tipo_instructor CONSTANT DECIMAL(2,0) := 3;
    w_ind_vehiculo      BOOLEAN;
    w_placa             TEXT;
    w_exc_state         TEXT;
    w_exc_msg           TEXT;
    w_exc_detail        TEXT;
    w_exc_hint          TEXT;
BEGIN
    IF wid_persona IS NULL OR wid_persona <= 20000000 THEN
        PERFORM smartcset_raise_validacion(
            'El documento del instructor debe ser mayor a 20.000.000.',
            'id_persona=' || COALESCE(wid_persona::TEXT, 'NULL')
        );
    END IF;

    IF wid_tipo_docum IS NULL OR TRIM(wid_tipo_docum) = '' THEN
        PERFORM smartcset_raise_validacion('Seleccione el tipo de documento.');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM tab_tipos_docum WHERE id_tipo_docum = wid_tipo_docum) THEN
        PERFORM smartcset_raise_validacion(
            'El tipo de documento no está registrado en el sistema.',
            'id_tipo_docum=' || wid_tipo_docum
        );
    END IF;

    IF LENGTH(TRIM(wnom_persona)) < 3 OR LENGTH(TRIM(wape_persona)) < 2 THEN
        PERFORM smartcset_raise_validacion(
            'Nombres (mín. 3 caracteres) y apellidos (mín. 2) son obligatorios.'
        );
    END IF;

    IF wmail_persona IS NULL OR TRIM(wmail_persona::TEXT) = '' THEN
        PERFORM smartcset_raise_validacion('El correo electrónico es obligatorio.');
    END IF;

    IF wfec_nacimiento IS NULL THEN
        PERFORM smartcset_raise_validacion('La fecha de nacimiento es obligatoria.');
    END IF;

    IF wind_genero IS NULL OR wind_genero NOT IN (1, 2, 4) THEN
        PERFORM smartcset_raise_validacion(
            'Seleccione un género válido (Femenino, Masculino o Trans).',
            'ind_genero=' || COALESCE(wind_genero::TEXT, 'NULL')
        );
    END IF;

    IF wind_est_civil IS NULL OR wind_est_civil < 0 OR wind_est_civil > 9 THEN
        PERFORM smartcset_raise_validacion('Seleccione un estado civil válido.');
    END IF;

    IF wid_nivel_estudio IS NULL OR NOT EXISTS (
        SELECT 1 FROM tab_niveles_estudio WHERE id_nivel_estudio = wid_nivel_estudio
    ) THEN
        PERFORM smartcset_raise_validacion('El nivel de estudio seleccionado no es válido.');
    END IF;

    IF wid_profesion IS NULL OR TRIM(wid_profesion) = '' OR NOT EXISTS (
        SELECT 1 FROM tab_profesiones WHERE id_profesion = wid_profesion
    ) THEN
        PERFORM smartcset_raise_validacion('La profesión seleccionada no es válida.');
    END IF;

    IF wid_dpto_reside IS NULL OR TRIM(wid_dpto_reside) = '' OR NOT EXISTS (
        SELECT 1 FROM tab_dptos WHERE id_dpto = wid_dpto_reside
    ) THEN
        PERFORM smartcset_raise_validacion('El departamento de residencia no es válido.');
    END IF;

    IF wid_ciudad_reside IS NULL OR TRIM(wid_ciudad_reside) = '' OR NOT EXISTS (
        SELECT 1 FROM tab_ciudades
        WHERE id_ciudad = wid_ciudad_reside AND id_dpto = wid_dpto_reside
    ) THEN
        PERFORM smartcset_raise_validacion(
            'La ciudad no corresponde al departamento seleccionado.',
            'id_ciudad=' || COALESCE(wid_ciudad_reside, 'NULL'),
            'id_dpto=' || COALESCE(wid_dpto_reside, 'NULL')
        );
    END IF;

    IF wdir_ciudad_reside IS NULL OR LENGTH(TRIM(wdir_ciudad_reside)) < 10 THEN
        PERFORM smartcset_raise_validacion(
            'La dirección debe tener al menos 10 caracteres.'
        );
    END IF;

    IF wtel_persona_fijo IS NULL OR wtel_persona_movil IS NULL
       OR wtel_contacto_emergencias IS NULL THEN
        PERFORM smartcset_raise_validacion('Los teléfonos son obligatorios y deben ser válidos.');
    END IF;

    IF wnom_contacto_emergencias IS NULL OR LENGTH(TRIM(wnom_contacto_emergencias)) < 5 THEN
        PERFORM smartcset_raise_validacion(
            'El contacto de emergencias debe tener al menos 5 caracteres.'
        );
    END IF;

    IF wid_centro IS NULL OR NOT EXISTS (
        SELECT 1 FROM tab_centros WHERE id_centro = wid_centro
    ) THEN
        PERFORM smartcset_raise_validacion(
            'El centro de formación seleccionado no existe.',
            'id_centro=' || COALESCE(wid_centro::TEXT, 'NULL')
        );
    END IF;

    IF wid_red IS NULL OR NOT EXISTS (
        SELECT 1 FROM tab_redes WHERE id_red = wid_red
    ) THEN
        PERFORM smartcset_raise_validacion(
            'La red de conocimiento seleccionada no existe.',
            'id_red=' || COALESCE(wid_red::TEXT, 'NULL')
        );
    END IF;

    IF wind_estado IS NULL OR wind_estado < 0 OR wind_estado > 9 THEN
        PERFORM smartcset_raise_validacion('El estado del instructor no es válido.');
    END IF;

    IF wusr IS NULL OR LENGTH(TRIM(wusr)) < 3 THEN
        PERFORM smartcset_raise_validacion('Usuario de auditoría no válido.');
    END IF;

    w_ind_vehiculo := COALESCE(wind_vehiculo, FALSE);

    IF w_ind_vehiculo THEN
        w_placa := UPPER(TRIM(COALESCE(wid_vehiculo, '')));
        IF w_placa = '' OR LENGTH(w_placa) < 5 OR LENGTH(w_placa) > 8 THEN
            PERFORM smartcset_raise_validacion(
                'La placa del vehículo es obligatoria (5 a 8 caracteres).'
            );
        END IF;

        IF w_placa !~ '^[A-Z0-9]+$' THEN
            PERFORM smartcset_raise_validacion(
                'La placa solo puede contener letras y números.'
            );
        END IF;

        IF wind_tipovehiculo IS NULL OR wind_tipovehiculo NOT IN (1, 2, 3) THEN
            PERFORM smartcset_raise_validacion(
                'Seleccione un tipo de vehículo válido (Automóvil, Moto o Bicicleta).'
            );
        END IF;

        IF EXISTS (SELECT 1 FROM tab_vehiculos WHERE id_vehiculo = w_placa) THEN
            PERFORM smartcset_raise_negocio(
                'Ya existe un vehículo registrado con esa placa.',
                'id_vehiculo=' || w_placa
            );
        END IF;
    ELSE
        w_placa := NULL;
    END IF;

    IF EXISTS (SELECT 1 FROM tab_instructores WHERE id_instructor = wid_persona) THEN
        PERFORM smartcset_raise_negocio(
            'Ya existe un instructor registrado con ese número de documento.',
            'id_instructor=' || wid_persona::TEXT
        );
    END IF;

    IF EXISTS (SELECT 1 FROM tab_personas WHERE id_persona = wid_persona) THEN
        PERFORM smartcset_raise_negocio(
            'Ya existe una persona registrada con ese documento.',
            'id_persona=' || wid_persona::TEXT
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
        wid_persona, wid_tipo_docum, wid_tipo_instructor,
        TRIM(wnom_persona), TRIM(wape_persona), TRIM(wmail_persona::TEXT)::mail_personal,
        wfec_nacimiento, wind_genero,
        CURRENT_TIMESTAMP, CURRENT_TIMESTAMP,
        wid_nivel_estudio, wid_profesion,
        wid_dpto_reside, wid_ciudad_reside, TRIM(wdir_ciudad_reside),
        wtel_persona_fijo, wtel_persona_movil,
        TRIM(wnom_contacto_emergencias), wtel_contacto_emergencias,
        COALESCE(wind_envio_correo, TRUE), TRUE,
        wusr, CURRENT_TIMESTAMP
    );

    INSERT INTO tab_instructores (
        id_instructor, id_centro,
        ind_tipo_contrato, ind_contratado_actual,
        ind_genero, ind_est_civil,
        id_nivel_estudio, ind_vehiculo, id_profesion, id_red,
        ind_disponibilidad, ind_estado,
        usr_insert, fec_insert
    ) VALUES (
        wid_persona, wid_centro,
        COALESCE(wind_tipo_contrato, TRUE), COALESCE(wind_contratado_actual, TRUE),
        wind_genero, wind_est_civil,
        wid_nivel_estudio, w_ind_vehiculo, wid_profesion, wid_red,
        COALESCE(wind_disponibilidad, TRUE), wind_estado,
        wusr, CURRENT_TIMESTAMP
    );

    IF w_ind_vehiculo THEN
        INSERT INTO tab_vehiculos (
            id_vehiculo, ind_tipovehiculo, id_propietario,
            usr_insert, fec_insert
        ) VALUES (
            w_placa, wind_tipovehiculo, wid_persona,
            wusr, CURRENT_TIMESTAMP
        );
    END IF;

    RETURN 'OK';
EXCEPTION
    WHEN SQLSTATE 'P0001' THEN
        RAISE;
    WHEN unique_violation THEN
        PERFORM smartcset_raise_negocio('Ya existe un registro con esos datos.');
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            w_exc_state  = RETURNED_SQLSTATE,
            w_exc_msg    = MESSAGE_TEXT,
            w_exc_detail = PG_EXCEPTION_DETAIL,
            w_exc_hint   = PG_EXCEPTION_HINT;
        PERFORM smartcset_handle_sql_error(w_exc_state, w_exc_msg, w_exc_detail, w_exc_hint);
END;
$$ LANGUAGE plpgsql;
