-- Configuración global de apariencia y módulo de registro de personas (una fila por instalación).

CREATE TABLE IF NOT EXISTS tab_config_sistema (
    id_config                     SMALLINT PRIMARY KEY DEFAULT 1 CHECK (id_config = 1),
    ind_modulo_registro           BOOLEAN NOT NULL DEFAULT TRUE,
    ind_login_registro_standalone BOOLEAN NOT NULL DEFAULT FALSE,
    nom_sistema                   VARCHAR(80) NOT NULL DEFAULT 'SmartCSET',
    path_logo                     VARCHAR(255) NOT NULL DEFAULT 'public/uploads/logos/logo.png',
    color_primario                VARCHAR(7) NOT NULL DEFAULT '#2E4731',
    color_secundario              VARCHAR(7) NOT NULL DEFAULT '#6B8E23',
    theme_bg_deep                 VARCHAR(32) NOT NULL DEFAULT '#020917',
    theme_bg_card                 VARCHAR(32) NOT NULL DEFAULT '#060f24',
    theme_bg_panel                VARCHAR(64) NOT NULL DEFAULT 'rgba(6, 15, 36, 0.85)',
    theme_accent                  VARCHAR(32) NOT NULL DEFAULT '#00e5b0',
    theme_accent_dim              VARCHAR(64) NOT NULL DEFAULT 'rgba(0, 245, 255, 0.15)',
    theme_blue                    VARCHAR(32) NOT NULL DEFAULT '#4a9eff',
    theme_purple                  VARCHAR(32) NOT NULL DEFAULT '#9b6dff',
    theme_orange                  VARCHAR(32) NOT NULL DEFAULT '#ff7b2e',
    theme_text_primary            VARCHAR(32) NOT NULL DEFAULT '#e8f4ff',
    theme_text_muted              VARCHAR(128) NOT NULL DEFAULT 'rgba(150,180,220,0.7)',
    theme_border                  VARCHAR(64) NOT NULL DEFAULT 'rgba(0,245,255,0.2)',
    theme_error                   VARCHAR(32) NOT NULL DEFAULT '#ff3c6e',
    theme_success                 VARCHAR(32) NOT NULL DEFAULT '#00e5b0',
    theme_font_display            VARCHAR(120) NOT NULL DEFAULT 'Orbitron',
    theme_font_body               VARCHAR(120) NOT NULL DEFAULT 'Rajdhani',
    theme_light_bg_deep           VARCHAR(32) NOT NULL DEFAULT '#f5f7fb',
    theme_light_bg_card           VARCHAR(32) NOT NULL DEFAULT '#ffffff',
    theme_light_accent            VARCHAR(32) NOT NULL DEFAULT '#0b74c7',
    theme_light_text_primary      VARCHAR(32) NOT NULL DEFAULT '#111827',
    theme_light_text_muted        VARCHAR(128) NOT NULL DEFAULT 'rgba(55,65,81,0.8)',
    usr_registro                  VARCHAR(40),
    pass_registro_hash            VARCHAR(255),
    usr_insert                    VARCHAR NOT NULL DEFAULT 'migration',
    fec_insert                    TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT NOW(),
    usr_update                    VARCHAR,
    fec_update                    TIMESTAMP WITHOUT TIME ZONE
);

INSERT INTO tab_config_sistema (
    id_config,
    ind_modulo_registro,
    ind_login_registro_standalone,
    nom_sistema,
    path_logo,
    color_primario,
    color_secundario,
    usr_registro,
    pass_registro_hash,
    usr_insert,
    fec_insert
) VALUES (
    1,
    TRUE,
    FALSE,
    'SmartCSET',
    'img/logo-sena.png',
    '#2E4731',
    '#6B8E23',
    'usuariocset',
    NULL,
    'migration',
    NOW()
) ON CONFLICT (id_config) DO NOTHING;

-- Hash por defecto para usuariocset / usuariocset (solo si standalone se activa después)
-- Se actualiza en setup con PHP si está disponible.
