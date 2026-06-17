-- Inserción atómica de menú (V.1.3: incluye nom_programa).
CREATE OR REPLACE FUNCTION fun_insert_tab_menus(
    wid_menu      tab_menus.id_menu%TYPE,
    wnom_menu     tab_menus.nom_menu%TYPE,
    wid_padre     tab_menus.ind_id_padre%TYPE,
    wnom_programa tab_menus.nom_programa%TYPE
) RETURNS TEXT AS $$
DECLARE
    v_nom_len INTEGER;
BEGIN
    IF wid_menu IS NULL OR TRIM(wid_menu) = '' THEN
        PERFORM smartcset_raise_validacion('El ID del menú es obligatorio.');
    END IF;

    IF EXISTS (SELECT 1 FROM tab_menus WHERE id_menu = wid_menu) THEN
        PERFORM smartcset_raise_negocio(
            format('El menú %s ya existe.', wid_menu),
            NULL,
            'Use otro código o edite el menú existente.'
        );
    END IF;

    v_nom_len := LENGTH(TRIM(wnom_menu));
    IF v_nom_len < 3 OR v_nom_len > 25 THEN
        PERFORM smartcset_raise_validacion(
            format('El nombre del menú debe tener entre 3 y 25 caracteres (actual: %s).', v_nom_len)
        );
    END IF;

    IF wid_padre IS NULL THEN
        PERFORM smartcset_raise_validacion('El menú padre es obligatorio (use 00 para raíz).');
    END IF;

    IF wid_padre NOT IN ('00', '0') AND NOT EXISTS (SELECT 1 FROM tab_menus WHERE id_menu = wid_padre) THEN
        PERFORM smartcset_raise_validacion(
            format('El menú padre %s no existe.', wid_padre),
            NULL,
            'Cree primero el menú padre o use 00 como raíz.'
        );
    END IF;

    INSERT INTO tab_menus (id_menu, nom_menu, ind_id_padre, nom_programa)
    VALUES (
        wid_menu,
        TRIM(wnom_menu),
        wid_padre,
        COALESCE(NULLIF(TRIM(wnom_programa), ''), 'no_aplica')
    );

    RETURN 'OK';
EXCEPTION
    WHEN SQLSTATE 'P0001' THEN
        RAISE;
    WHEN OTHERS THEN
        PERFORM smartcset_handle_sql_error();
END;
$$ LANGUAGE plpgsql;
