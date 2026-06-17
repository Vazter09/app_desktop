-- =====================================================================
-- Migración: actualizar nom_programa en tab_menus a nuevas rutas
-- =====================================================================
-- Contexto:
--   src/ fue reorganizado en subcarpetas: core/, auth/, menu/, usuarios/, modulos/
--   El campo tab_menus.nom_programa guarda la ruta relativa que renderiza
--   menu_principal.php (ubicado en src/menu/). Las rutas son relativas a
--   ese archivo, por lo tanto:
--     - hermano (en src/menu/)        -> 'nombre.php'
--     - en otra subcarpeta            -> '../<carpeta>/nombre.php'
--
-- Aplicar UNA SOLA VEZ después de poblar tab_menus con los valores viejos.
-- Si la BD aún no tiene datos, usar este archivo como referencia para los
-- INSERTs iniciales de tab_menus.
-- =====================================================================

BEGIN;

-- ── Módulo Menús (src/menu/) - hermanos de menu_principal.php ──
UPDATE tab_menus SET nom_programa = 'menus.php'                WHERE nom_programa = 'menus.php';
UPDATE tab_menus SET nom_programa = 'menu_usuarios.php'        WHERE nom_programa = 'menu_usuarios.php';
UPDATE tab_menus SET nom_programa = 'copiar_menu_usuarios.php' WHERE nom_programa = 'copiar_menu_usuarios.php';
UPDATE tab_menus SET nom_programa = 'menu_principal.php'       WHERE nom_programa = 'menu_principal.php';

-- ── Módulo Autenticación (src/auth/) ──
UPDATE tab_menus SET nom_programa = '../auth/cambiar_clave.php' WHERE nom_programa = 'cambiar_clave.php';
UPDATE tab_menus SET nom_programa = '../auth/logout.php'        WHERE nom_programa IN ('logout.php', 'Exit', 'EXIT');
UPDATE tab_menus SET nom_programa = '../auth/recuperar.php'     WHERE nom_programa = 'recuperar.php';

-- ── Módulo Usuarios (src/usuarios/) ──
UPDATE tab_menus SET nom_programa = '../usuarios/usuarios.php'  WHERE nom_programa = 'usuarios.php';

-- ── Módulos CSET (src/modulos/) ──
UPDATE tab_menus SET nom_programa = '../modulos/entradas.php'   WHERE nom_programa = 'entradas.php';

-- =====================================================================
-- Referencia rápida para INSERTs nuevos en tab_menus.nom_programa:
--
--   menu_principal.php                  -> 'menu_principal.php'
--   menus.php                           -> 'menus.php'
--   menu_usuarios.php                   -> 'menu_usuarios.php'
--   copiar_menu_usuarios.php            -> 'copiar_menu_usuarios.php'
--   cambiar_clave.php                   -> '../auth/cambiar_clave.php'
--   logout.php                          -> '../auth/logout.php'
--   recuperar.php                       -> '../auth/recuperar.php'
--   usuarios.php                        -> '../usuarios/usuarios.php'
--   entradas.php                        -> '../modulos/entradas.php'
-- =====================================================================

COMMIT;
