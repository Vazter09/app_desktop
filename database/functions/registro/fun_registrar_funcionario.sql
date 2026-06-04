-- Registro atómico: tab_personas (tipo Funcionario) + tab_funcionarios.
-- Delega validaciones e inserción de persona en fun_registrar_persona.
CREATE OR REPLACE FUNCTION fun_registrar_funcionario(
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
    wid_area                    tab_funcionarios.id_area%TYPE,
    wid_cargo                   tab_funcionarios.id_cargo%TYPE,
    wval_grado                  tab_funcionarios.val_grado%TYPE,
    wfec_ingreso_planta         tab_funcionarios.id_fec_ingreso_planta%TYPE,
    wid_centro                  tab_areas.id_centro%TYPE,
    wusr                        tab_personas.usr_insert%TYPE
) RETURNS TEXT AS $$
DECLARE
    wtipo_funcionario CONSTANT DECIMAL(2,0) := 4;
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM tab_tipos_persona WHERE id_tipo_persona = wtipo_funcionario
    ) THEN
        PERFORM smartcset_raise_core(
            'El catálogo de tipos de persona no incluye Funcionario (id 4). Ejecute los seeds de desarrollo.'
        );
    END IF;

    IF wid_area IS NULL THEN
        PERFORM smartcset_raise_validacion('Seleccione el área de trabajo.');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM tab_areas WHERE id_area = wid_area) THEN
        PERFORM smartcset_raise_validacion('El área seleccionada no está registrada en el sistema.');
    END IF;

    IF wid_centro IS NOT NULL AND NOT EXISTS (
        SELECT 1 FROM tab_areas WHERE id_area = wid_area AND id_centro = wid_centro
    ) THEN
        PERFORM smartcset_raise_validacion(
            'El área no pertenece al centro de adscripción seleccionado.'
        );
    END IF;

    IF wid_cargo IS NULL THEN
        PERFORM smartcset_raise_validacion('Seleccione el cargo.');
    END IF;

    IF NOT EXISTS (SELECT 1 FROM tab_cargos WHERE id_cargo = wid_cargo) THEN
        PERFORM smartcset_raise_validacion('El cargo seleccionado no está registrado en el sistema.');
    END IF;

    IF wval_grado IS NULL OR LENGTH(TRIM(wval_grado)) < 1 THEN
        PERFORM smartcset_raise_validacion('Indique el grado del funcionario.');
    END IF;

    IF wfec_ingreso_planta IS NULL THEN
        PERFORM smartcset_raise_validacion('Indique la fecha de ingreso a planta.');
    END IF;

    IF wfec_ingreso_planta > CURRENT_DATE THEN
        PERFORM smartcset_raise_validacion('La fecha de ingreso a planta no puede ser futura.');
    END IF;

    PERFORM fun_registrar_persona(
        wid_persona,
        wid_tipo_docum,
        wtipo_funcionario,
        wnom_persona,
        wape_persona,
        wmail_persona,
        wfec_nacimiento,
        wind_genero,
        wid_nivel_estudio,
        wid_profesion,
        wid_dpto_reside,
        wid_ciudad_reside,
        wdir_ciudad_reside,
        wtel_persona_fijo,
        wtel_persona_movil,
        wnom_contacto_emergencias,
        wtel_contacto_emergencias,
        wind_envio_correo,
        TRUE,
        wusr
    );

    INSERT INTO tab_funcionarios (
        id_funcionario, id_area, id_cargo, val_grado, id_fec_ingreso_planta,
        usr_insert, fec_insert
    ) VALUES (
        wid_persona, wid_area, wid_cargo, TRIM(wval_grado), wfec_ingreso_planta,
        TRIM(wusr), CURRENT_TIMESTAMP
    );

    RETURN 'OK';
EXCEPTION
    WHEN SQLSTATE 'P0001' THEN
        RAISE;
    WHEN unique_violation THEN
        PERFORM smartcset_raise_negocio('Ya existe un funcionario registrado con ese documento.');
    WHEN foreign_key_violation THEN
        PERFORM smartcset_raise_validacion(
            'Revise los catálogos seleccionados (área o cargo).'
        );
    WHEN OTHERS THEN
        PERFORM smartcset_handle_sql_error();
END;
$$ LANGUAGE plpgsql;
