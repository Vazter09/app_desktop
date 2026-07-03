-- Enlaza menús placeholder con páginas «en construcción».

UPDATE tab_menus SET nom_programa = v.nom_programa
FROM (VALUES
    ('104',     'pages/modulos/en_construccion/estadisticos.php'),
    ('20102',   'pages/modulos/en_construccion/contratos.php'),
    ('20103',   'pages/modulos/en_construccion/disciplinario_instructor.php'),
    ('20104',   'pages/modulos/en_construccion/gestion_tiempos.php'),
    ('20105',   'pages/modulos/en_construccion/portafolios_instructor.php'),
    ('20202',   'pages/modulos/en_construccion/certificaciones.php'),
    ('20203',   'pages/modulos/en_construccion/disciplinario_aprendiz.php'),
    ('20206',   'pages/modulos/en_construccion/portafolio_aprendiz.php'),
    ('20207',   'pages/modulos/en_construccion/caprendizaje.php'),
    ('20301',   'pages/modulos/en_construccion/rutas_consulta.php'),
    ('20302',   'pages/modulos/en_construccion/rutas_crud.php'),
    ('204',     'pages/modulos/en_construccion/programas.php'),
    ('20501',   'pages/modulos/en_construccion/llamados.php'),
    ('20502',   'pages/modulos/en_construccion/comites.php'),
    ('301',     'pages/modulos/en_construccion/biblioteca.php'),
    ('302',     'pages/modulos/en_construccion/gimnasio.php'),
    ('303',     'pages/modulos/en_construccion/bienestar.php')
) AS v(id_menu, nom_programa)
WHERE tab_menus.id_menu = v.id_menu;
