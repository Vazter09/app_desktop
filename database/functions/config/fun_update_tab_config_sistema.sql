-- La auditoría (usr_update) la gestiona el trigger fun_act_tabla().
CREATE OR REPLACE FUNCTION fun_update_tab_config_sistema(
    wind_modulo_registro           BOOLEAN,
    wind_login_registro_standalone BOOLEAN,
    wnom_sistema                   VARCHAR,
    wpath_logo                     VARCHAR,
    wcolor_primario                VARCHAR,
    wcolor_secundario              VARCHAR,
    wtheme_bg_deep                 VARCHAR,
    wtheme_bg_card                 VARCHAR,
    wtheme_bg_panel                VARCHAR,
    wtheme_accent                  VARCHAR,
    wtheme_accent_dim              VARCHAR,
    wtheme_blue                    VARCHAR,
    wtheme_purple                  VARCHAR,
    wtheme_orange                  VARCHAR,
    wtheme_text_primary            VARCHAR,
    wtheme_text_muted              VARCHAR,
    wtheme_border                  VARCHAR,
    wtheme_error                   VARCHAR,
    wtheme_success                 VARCHAR,
    wtheme_font_display            VARCHAR,
    wtheme_font_body               VARCHAR,
    wtheme_light_bg_deep           VARCHAR,
    wtheme_light_bg_card           VARCHAR,
    wtheme_light_accent            VARCHAR,
    wtheme_light_text_primary      VARCHAR,
    wtheme_light_text_muted        VARCHAR,
    wusr_registro                  VARCHAR,
    wpass_registro_hash            VARCHAR
) RETURNS TEXT AS $$
DECLARE
    w_exc_state  TEXT;
    w_exc_msg    TEXT;
    w_exc_detail TEXT;
    w_exc_hint   TEXT;
BEGIN
    IF wcolor_primario !~ '^#[0-9A-Fa-f]{6}$' OR wcolor_secundario !~ '^#[0-9A-Fa-f]{6}$' THEN
        PERFORM smartcset_raise_validacion('Los colores primario y secundario deben ser hex de 6 dígitos (#RRGGBB).');
    END IF;

    IF LENGTH(TRIM(wnom_sistema)) < 2 THEN
        PERFORM smartcset_raise_validacion('El nombre del sistema es obligatorio.');
    END IF;

    UPDATE tab_config_sistema
    SET ind_modulo_registro           = wind_modulo_registro,
        ind_login_registro_standalone = wind_login_registro_standalone,
        nom_sistema                   = TRIM(wnom_sistema),
        path_logo                     = TRIM(wpath_logo),
        color_primario                = wcolor_primario,
        color_secundario              = wcolor_secundario,
        theme_bg_deep                 = wtheme_bg_deep,
        theme_bg_card                 = wtheme_bg_card,
        theme_bg_panel                = wtheme_bg_panel,
        theme_accent                  = wtheme_accent,
        theme_accent_dim              = wtheme_accent_dim,
        theme_blue                    = wtheme_blue,
        theme_purple                  = wtheme_purple,
        theme_orange                  = wtheme_orange,
        theme_text_primary            = wtheme_text_primary,
        theme_text_muted              = wtheme_text_muted,
        theme_border                  = wtheme_border,
        theme_error                   = wtheme_error,
        theme_success                 = wtheme_success,
        theme_font_display            = TRIM(wtheme_font_display),
        theme_font_body               = TRIM(wtheme_font_body),
        theme_light_bg_deep           = wtheme_light_bg_deep,
        theme_light_bg_card           = wtheme_light_bg_card,
        theme_light_accent            = wtheme_light_accent,
        theme_light_text_primary      = wtheme_light_text_primary,
        theme_light_text_muted        = wtheme_light_text_muted,
        usr_registro                  = NULLIF(TRIM(wusr_registro), ''),
        pass_registro_hash            = CASE
            WHEN wpass_registro_hash IS NULL OR TRIM(wpass_registro_hash) = '' THEN pass_registro_hash
            ELSE wpass_registro_hash
        END
    WHERE id_config = 1;

    IF NOT FOUND THEN
        PERFORM smartcset_raise_no_encontrado('No existe configuración del sistema (id_config=1).');
    END IF;

    RETURN 'OK';
EXCEPTION
    WHEN SQLSTATE 'P0001' THEN
        RAISE;
    WHEN OTHERS THEN
        GET STACKED DIAGNOSTICS
            w_exc_state  = RETURNED_SQLSTATE,
            w_exc_msg    = MESSAGE_TEXT,
            w_exc_detail = PG_EXCEPTION_DETAIL,
            w_exc_hint   = PG_EXCEPTION_HINT;
        PERFORM smartcset_handle_sql_error(w_exc_state, w_exc_msg, w_exc_detail, w_exc_hint);
END;
$$ LANGUAGE plpgsql;
