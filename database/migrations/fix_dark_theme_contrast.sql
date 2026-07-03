-- Corrige tema oscuro legacy (azul sci-fi / negro puro) por paleta verde legible.
UPDATE tab_config_sistema
SET
    theme_bg_deep      = '#131e15',
    theme_bg_card      = '#1b2a1d',
    theme_bg_panel     = 'rgba(27, 42, 29, 0.92)',
    theme_text_muted   = 'rgba(186, 203, 175, 0.88)',
    theme_border       = 'rgba(107, 142, 35, 0.38)',
    fec_update         = CURRENT_TIMESTAMP
WHERE id_config = 1
  AND (
    lower(trim(theme_bg_deep)) IN (
        '#020917', '#060f24', '#0b1420', '#091826', '#081622',
        '#040604', '#060a07', '#0d1810', '#142218'
    )
    OR lower(trim(theme_bg_card)) IN (
        '#020917', '#060f24', '#0b1420', '#091826', '#081622',
        '#040604', '#060a07', '#0d1810', '#142218'
    )
    OR theme_text_muted ILIKE '%150,180,220%'
    OR theme_text_muted ILIKE '%0,245,255%'
    OR theme_border ILIKE '%0,245,255%'
  );
