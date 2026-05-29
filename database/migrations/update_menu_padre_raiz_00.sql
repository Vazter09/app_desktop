-- Menú raíz: ind_id_padre '00' (CHECK LENGTH >= 2). Migra valores legacy '0'.
UPDATE tab_menus SET ind_id_padre = '00' WHERE ind_id_padre = '0';
