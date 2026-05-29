-- Logo institucional SENA por defecto (reemplaza img/logo_empresa.png).
UPDATE tab_config_sistema
SET path_logo = 'img/logo-sena.png',
    usr_update = 'migration',
    fec_update = NOW()
WHERE id_config = 1
  AND path_logo IN ('img/logo_empresa.png', '../img/logo_empresa.png');
