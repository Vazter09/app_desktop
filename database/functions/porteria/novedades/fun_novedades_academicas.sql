CREATE OR REPLACE FUNCTION fun_novedades_academicas(
    wid_tipo_novedad  tab_novedades_academicas.id_tipo_novedad%TYPE,
    wid_aprendiz      tab_novedades_academicas.id_aprendiz%TYPE,
    wid_ficha         tab_novedades_academicas.id_ficha%TYPE,
    wid_causa_novedad tab_novedades_academicas.id_causa_novedad%TYPE,
    wruta_evidencia   tab_novedades_academicas.ruta_evidencia%TYPE,
    wid_instructor    tab_novedades_academicas.id_instructor%TYPE,
    wind_procesado    tab_novedades_academicas.ind_procesado%TYPE
) RETURNS BOOLEAN AS
$$
    DECLARE
        wid_afectado tab_novedades_academicas.id_consecutivo%TYPE;
    BEGIN
-- Intentamos insertar. Si hay conflicto en la llave única, actualizamos.
        INSERT INTO tab_novedades_academicas VALUES(CURRENT_DATE,wid_tipo_novedad,wid_aprendiz,wid_ficha,
                    wid_causa_novedad,wruta_evidencia,wid_instructor,wind_procesado)
        ON CONFLICT (id_aprendiz, id_tipo_novedad, fec_novedad) DO UPDATE 
        SET fec_novedad      = EXCLUDED.fec_novedad,
            id_tipo_novedad  = EXCLUDED.id_tipo_novedad,
            id_aprendiz      = EXCLUDED.id_ficha,
            id_ficha         = EXCLUDED.id_ficha
            id_causa_novedad = EXCLUDED.id_causa_novedad,
            ruta_evidencia   = EXCLUDED.ruta_evidencia,
            id_instructor    = EXCLUDED.id_instructor,
            ind_procesado    = EXCLUDED.ind_procesado RETURNING id_consecutivo INTO wid_afectado;
        RETURN TRUE;

    EXCEPTION
-- Mantenemos las capturas de errores críticos de negocio e integridad
        
        WHEN datetime_field_overflow THEN      
            RAISE NOTICE 'El año, o el mes, o el período no corresponden al de PMTROS... Arréglelo Bestia';
            RETURN FALSE;

        WHEN not_null_violation THEN           
            RAISE NOTICE 'Está mandando un NULO en un campo obligatorio... Sea serio';
            RETURN FALSE;

        WHEN foreign_key_violation THEN        
            RAISE NOTICE 'Un ID referenciado (Tipo Novedad, Aprendiz, Ficha, etc.) no existe... Créelo y vuelva';
            RETURN FALSE;

        WHEN string_data_right_truncation THEN 
            RAISE NOTICE 'El texto supera la longitud permitida.. Es de su abuelita?';
            RETURN FALSE;

    END;
$$
LANGUAGE PLPGSQL;