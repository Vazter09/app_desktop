-- Registro de contratista: solo tab_personas con id_tipo_persona = 5 (Contratista).
-- V.1.7 no incluye tab_contratistas; número de contrato, vigencias, objeto contractual
-- y centro de adscripción quedan para un módulo/schema futuro (p. ej. tab_contratos_*).
-- Delega validaciones e inserción en fun_registrar_persona.
CREATE OR REPLACE FUNCTION fun_registrar_contratista(
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
    wusr                        tab_personas.usr_insert%TYPE
) RETURNS TEXT AS $$
DECLARE
    wtipo_contratista CONSTANT DECIMAL(2,0) := 5;
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM tab_tipos_persona WHERE id_tipo_persona = wtipo_contratista
    ) THEN
        PERFORM smartcset_raise_core(
            'El catálogo de tipos de persona no incluye Contratista (id 5). Ejecute los seeds de desarrollo.'
        );
    END IF;

    RETURN fun_registrar_persona(
        wid_persona,
        wid_tipo_docum,
        wtipo_contratista,
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
EXCEPTION
    WHEN SQLSTATE 'P0001' THEN
        RAISE;
    WHEN OTHERS THEN
        PERFORM smartcset_handle_sql_error();
END;
$$ LANGUAGE plpgsql;
