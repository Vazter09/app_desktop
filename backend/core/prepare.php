<?php
/**
 * CENTRAL DE INSTRUCCIONES PREPARADAS - SmartCSET
 * BD: PostgreSQL (db_smartcset) — esquema database/schema/script_BD_SMARTCSET V.1.5.sql
 * Lógica delegada al motor PostgreSQL mediante funciones con casting explícito.
 */
require_once __DIR__ . '/config.php';
require_once __DIR__ . '/SecurityMiddleware.php';
require_once __DIR__ . '/Db.php';
require_once __DIR__ . '/AppConfig.php';
require_once __DIR__ . '/ConfigSistemaDefaults.php';
require_once __DIR__ . '/PrepareAuthSql.php';
require_once __DIR__ . '/lib/acceso_sesion.php';

try {
    $pdo = Db::connect();

    AppConfig::boot($pdo);

    // --- CONFIGURACIÓN DEL SISTEMA ---
    $sql_fun_upd_config = "SELECT fun_update_tab_config_sistema(
        ?::BOOLEAN, ?::BOOLEAN, ?::VARCHAR, ?::VARCHAR, ?::VARCHAR, ?::VARCHAR,
        ?::VARCHAR, ?::VARCHAR, ?::VARCHAR, ?::VARCHAR, ?::VARCHAR, ?::VARCHAR,
        ?::VARCHAR, ?::VARCHAR, ?::VARCHAR, ?::VARCHAR, ?::VARCHAR, ?::VARCHAR,
        ?::VARCHAR, ?::VARCHAR, ?::VARCHAR, ?::VARCHAR, ?::VARCHAR, ?::VARCHAR,
        ?::VARCHAR, ?::VARCHAR, ?::VARCHAR, ?::VARCHAR, ?::VARCHAR
    )";
    $stmt_fun_upd_config = $pdo->prepare($sql_fun_upd_config);

    // Sin pass_registro_hash ni columnas de auditoría (formularios admin no exponen el hash).
    $sql_get_config = ConfigSistemaDefaults::sqlSelectConfig(false);
    $stmt_get_config = null;
    try {
        $stmt_get_config = $pdo->prepare($sql_get_config);
    } catch (PDOException $e) {
        // Tabla aún no migrada; AppConfig usará .env
    }

    // --- 1. SECCIÓN DE AUTENTICACIÓN Y LOGIN ---
    $stmt_login = $pdo->prepare(PrepareAuthSql::LOGIN);

    // --- 2. SECCIÓN DE MAESTRO DE USUARIOS (ATOMICIDAD) ---
    $sql_fun_ins_user = "SELECT fun_insert_tab_usuarios(?::TEXT, ?::TEXT, ?::TEXT, ?::TEXT, ?::BOOLEAN, ?::BOOLEAN)";
    $stmt_fun_ins_user = $pdo->prepare($sql_fun_ins_user);

    $sql_fun_upd_user = "SELECT fun_update_tab_usuarios(?::TEXT, ?::TEXT, ?::TEXT, ?::TEXT, ?::BOOLEAN, ?::BOOLEAN)";
    $stmt_fun_upd_user = $pdo->prepare($sql_fun_upd_user);

    $sql_list_users = "SELECT id_usuario, nom_usuario, mail_usuario, ind_usuario, ind_estado FROM tab_usuarios ORDER BY id_usuario ASC";
    $stmt_list_users = $pdo->prepare($sql_list_users);

    // --- 3. SECCIÓN DE RECUPERACIÓN DE CONTRASEÑA ---
    $sql_valida_mail = "SELECT mail_usuario FROM tab_usuarios WHERE id_usuario = ? AND mail_usuario = ?";
    $stmt_valida_mail = $pdo->prepare($sql_valida_mail);

    $sql_temp_pass = "UPDATE tab_usuarios SET pass_usuario = ?::TEXT WHERE id_usuario = ?::TEXT";
    $stmt_upd_pass = $pdo->prepare($sql_temp_pass);

    // --- 4. SECCIÓN DE NAVEGACIÓN Y MENÚS (CRUD ATÓMICO V.1.3) ---
    // V.1.3: nom_programa ahora está en tab_menus, no en tab_menu_usuarios
    $sql_menu = "SELECT m.id_menu, m.nom_menu, m.ind_id_padre, m.nom_programa 
                 FROM tab_menu_usuarios mu INNER JOIN tab_menus m ON mu.id_menu = m.id_menu
                 WHERE mu.id_usuario = CAST(? AS TEXT) ORDER BY m.id_menu ASC";
    $stmt_menu = $pdo->prepare($sql_menu);

    $sql_list_todos_menus = "SELECT id_menu, nom_menu, ind_id_padre, nom_programa FROM tab_menus ORDER BY id_menu ASC";
    $stmt_list_todos_menus = $pdo->prepare($sql_list_todos_menus);

    // V.1.3: Las funciones ahora incluyen nom_programa
    $sql_fun_ins_menu = "SELECT fun_insert_tab_menus(?::TEXT, ?::TEXT, ?::TEXT, ?::TEXT)";
    $stmt_ins_menu = $pdo->prepare($sql_fun_ins_menu);

    $sql_fun_upd_menu = "SELECT fun_update_tab_menus(?::TEXT, ?::TEXT, ?::TEXT, ?::TEXT)";
    $stmt_upd_menu = $pdo->prepare($sql_fun_upd_menu);

    $sql_fun_del_menu = "SELECT fun_delete_tab_menus(?::TEXT)";
    $stmt_del_menu = $pdo->prepare($sql_fun_del_menu);


    // --- 5. SECCIÓN DE SESIONES (escritura/validación: funciones PL/pgSQL; listado: SELECT) ---
    $stmt_fun_ingreso_sesion = $pdo->prepare(PrepareAuthSql::INGRESO_SESION);
    $stmt_fun_salida_sesion = $pdo->prepare(PrepareAuthSql::SALIDA_SESION);
    $stmt_fun_touch_sesion = $pdo->prepare(PrepareAuthSql::TOUCH_SESION);
    $stmt_fun_validar_sesion_activa = $pdo->prepare(PrepareAuthSql::VALIDAR_SESION_ACTIVA);
    $stmt_sesion_ip_activa = $pdo->prepare(PrepareAuthSql::SESION_IP_ACTIVA);

    $sql_list_sesiones_activas = "SELECT s.id_sesion, s.id_usuario, u.nom_usuario, u.mail_usuario,
                                        u.ind_usuario, s.fec_inicio, s.ult_actividad,
                                        s.ult_ruta, s.ult_menu_id, s.ip_cliente
                                 FROM tab_sesiones s
                                 INNER JOIN tab_usuarios u ON u.id_usuario = s.id_usuario
                                 WHERE s.fec_fin IS NULL
                                 ORDER BY s.ult_actividad DESC";
    $stmt_list_sesiones_activas = $pdo->prepare($sql_list_sesiones_activas);

    // --- 6. SECCIÓN CSET - ENTRADAS AL CENTRO (tab_entradas_centro V.1.5: id_centro, id_sede) ---
    $sql_list_entradas = "SELECT e.id_entrada_centro AS id_entrada,
                                 e.nom_entrada_centro AS nom_entrada,
                                 e.id_centro,
                                 e.id_sede,
                                 COALESCE(c.nom_centro, '') AS nom_centro,
                                 COALESCE(s.nom_sede, '') AS nom_sede
                          FROM tab_entradas_centro e
                          INNER JOIN tab_sedes s
                                  ON s.id_centro = e.id_centro AND s.id_sede = e.id_sede
                          INNER JOIN tab_centros c ON c.id_centro = e.id_centro
                          ORDER BY e.id_entrada_centro ASC";
    $stmt_list_entradas = $pdo->prepare($sql_list_entradas);

    $sql_fun_upsert_entrada = 'SELECT fun_upsert_tab_entradas_centro(?::NUMERIC, ?::VARCHAR, ?::NUMERIC, ?::NUMERIC, ?::TEXT)';
    $stmt_fun_upsert_entrada = $pdo->prepare($sql_fun_upsert_entrada);

    $sql_fun_delete_entrada = 'SELECT fun_delete_tab_entradas_centro(?::NUMERIC)';
    $stmt_fun_delete_entrada = $pdo->prepare($sql_fun_delete_entrada);

    // --- 6b. REGISTRO DE INGRESOS (portería → tab_log_ingresos) ---
    $stmt_list_tipos_doc = $pdo->prepare(
        "SELECT id_tipo_docum, nom_tipo_docum FROM tab_tipos_docum ORDER BY id_tipo_docum"
    );
    $stmt_list_tipos_persona = $pdo->prepare(
        "SELECT id_tipo_persona, nom_tipo_persona
         FROM tab_tipos_persona
         WHERE id_tipo_persona <> 99
         ORDER BY id_tipo_persona"
    );
    $stmt_list_ingresos_hoy = $pdo->prepare(
        "SELECT l.id_ingreso, l.fec_ingreso, l.val_observaciones,
                p.id_persona, p.id_tipo_docum, p.nom_persona, p.ape_persona,
                p.id_tipo_persona, tp.nom_tipo_persona,
                e.id_entrada_centro, e.nom_entrada_centro
         FROM tab_log_ingresos l
         INNER JOIN tab_personas p ON l.id_visitante = p.id_persona
         INNER JOIN tab_tipos_persona tp ON p.id_tipo_persona = tp.id_tipo_persona
         INNER JOIN tab_entradas_centro e ON l.id_entrada_centro = e.id_entrada_centro
         WHERE l.fec_ingreso::date = CURRENT_DATE
         ORDER BY l.fec_ingreso DESC"
    );
    $stmt_buscar_persona_doc = $pdo->prepare(
        "SELECT p.id_persona, p.id_tipo_docum, p.nom_persona, p.ape_persona,
                p.id_tipo_persona, tp.nom_tipo_persona
         FROM tab_personas p
         INNER JOIN tab_tipos_persona tp ON p.id_tipo_persona = tp.id_tipo_persona
         WHERE p.id_persona = ?::NUMERIC AND p.id_tipo_docum = ?::VARCHAR"
    );

    $sql_fun_registrar_ingreso = "SELECT fun_registrar_ingreso_manual(
        ?::NUMERIC, ?::VARCHAR, ?::NUMERIC, ?::VARCHAR, ?::VARCHAR,
        ?::NUMERIC, ?::TEXT, ?::VARCHAR, ?::DECIMAL, ?::BOOLEAN
    )";
    $stmt_fun_registrar_ingreso = $pdo->prepare($sql_fun_registrar_ingreso);

    // --- 6c. REGISTRO DE SALIDAS (portería → tab_log_ingresos.fec_salida) ---
    $stmt_list_salidas_hoy = $pdo->prepare(
        "SELECT l.id_ingreso, l.fec_ingreso, l.fec_salida, l.val_observaciones,
                p.id_persona, p.id_tipo_docum, p.nom_persona, p.ape_persona,
                p.id_tipo_persona, tp.nom_tipo_persona,
                e.id_entrada_centro, e.nom_entrada_centro
         FROM tab_log_ingresos l
         INNER JOIN tab_personas p ON l.id_visitante = p.id_persona
         INNER JOIN tab_tipos_persona tp ON p.id_tipo_persona = tp.id_tipo_persona
         INNER JOIN tab_entradas_centro e ON l.id_entrada_centro = e.id_entrada_centro
         WHERE l.fec_salida::date = CURRENT_DATE
           AND l.fec_salida > l.fec_ingreso
         ORDER BY l.fec_salida DESC"
    );
    $stmt_buscar_ingreso_abierto = $pdo->prepare(
        "SELECT l.id_ingreso, l.fec_ingreso, l.id_entrada_centro, e.nom_entrada_centro,
                p.id_persona, p.id_tipo_docum, p.nom_persona, p.ape_persona,
                p.id_tipo_persona, tp.nom_tipo_persona
         FROM tab_log_ingresos l
         INNER JOIN tab_personas p ON l.id_visitante = p.id_persona
         INNER JOIN tab_tipos_persona tp ON p.id_tipo_persona = tp.id_tipo_persona
         INNER JOIN tab_entradas_centro e ON l.id_entrada_centro = e.id_entrada_centro
         WHERE l.id_visitante = ?::NUMERIC
           AND l.fec_salida = l.fec_ingreso
         ORDER BY l.fec_ingreso DESC
         LIMIT 1"
    );
    $sql_fun_registrar_salida = "SELECT fun_registrar_salida_manual(
        ?::NUMERIC, ?::VARCHAR, ?::TEXT, ?::VARCHAR
    )";
    $stmt_fun_registrar_salida = $pdo->prepare($sql_fun_registrar_salida);

    // --- 6d. REGISTRO DE PERSONAS (módulo registro → tab_personas) ---
    $sql_fun_registrar_persona = "SELECT fun_registrar_persona(
        ?::NUMERIC, ?::VARCHAR, ?::NUMERIC, ?::VARCHAR, ?::VARCHAR,
        ?::VARCHAR, ?::DATE, ?::NUMERIC,
        ?::NUMERIC, ?::VARCHAR, ?::VARCHAR, ?::VARCHAR, ?::VARCHAR,
        ?::NUMERIC, ?::NUMERIC, ?::VARCHAR, ?::NUMERIC,
        ?::BOOLEAN, ?::BOOLEAN, ?::VARCHAR
    )";
    $stmt_fun_registrar_persona = $pdo->prepare($sql_fun_registrar_persona);

    $sql_fun_registrar_contratista = "SELECT fun_registrar_contratista(
        ?::NUMERIC, ?::VARCHAR, ?::VARCHAR, ?::VARCHAR, ?::VARCHAR, ?::DATE, ?::NUMERIC,
        ?::NUMERIC, ?::VARCHAR, ?::VARCHAR, ?::VARCHAR, ?::VARCHAR,
        ?::NUMERIC, ?::NUMERIC, ?::VARCHAR, ?::NUMERIC, ?::BOOLEAN, ?::VARCHAR
    )";
    $stmt_fun_registrar_contratista = $pdo->prepare($sql_fun_registrar_contratista);

    $sql_fun_registrar_aprendiz = "SELECT fun_registrar_aprendiz(
        ?::NUMERIC, ?::VARCHAR, ?::VARCHAR, ?::VARCHAR, ?::VARCHAR,
        ?::DATE, ?::NUMERIC, ?::NUMERIC, ?::VARCHAR,
        ?::VARCHAR, ?::VARCHAR, ?::VARCHAR,
        ?::NUMERIC, ?::NUMERIC, ?::VARCHAR, ?::NUMERIC,
        ?::BOOLEAN,
        ?::NUMERIC, ?::NUMERIC, ?::NUMERIC, ?::NUMERIC, ?::NUMERIC,
        ?::VARCHAR, ?::NUMERIC, ?::TEXT, ?::NUMERIC
    )";
    $stmt_fun_registrar_aprendiz = $pdo->prepare($sql_fun_registrar_aprendiz);

    $sql_fun_actualizar_aprendiz = "SELECT fun_actualizar_aprendiz(
        ?::NUMERIC, ?::VARCHAR, ?::VARCHAR, ?::VARCHAR, ?::VARCHAR,
        ?::DATE, ?::NUMERIC, ?::NUMERIC, ?::VARCHAR,
        ?::VARCHAR, ?::VARCHAR, ?::VARCHAR,
        ?::NUMERIC, ?::NUMERIC, ?::VARCHAR, ?::NUMERIC,
        ?::BOOLEAN,
        ?::NUMERIC, ?::NUMERIC, ?::NUMERIC, ?::NUMERIC, ?::NUMERIC,
        ?::VARCHAR, ?::NUMERIC, ?::TEXT, ?::NUMERIC
    )";
    $stmt_fun_actualizar_aprendiz = $pdo->prepare($sql_fun_actualizar_aprendiz);


    $sql_fun_registrar_instructor = "SELECT fun_registrar_instructor(
        ?::NUMERIC, ?::VARCHAR, ?::VARCHAR, ?::VARCHAR, ?::VARCHAR, ?::DATE,
        ?::NUMERIC, ?::NUMERIC, ?::NUMERIC, ?::VARCHAR,
        ?::VARCHAR, ?::VARCHAR, ?::VARCHAR,
        ?::NUMERIC, ?::NUMERIC, ?::VARCHAR, ?::NUMERIC,
        ?::BOOLEAN, ?::NUMERIC, ?::NUMERIC,
        ?::BOOLEAN, ?::BOOLEAN, ?::BOOLEAN, ?::NUMERIC, ?::TEXT
    )";
    $stmt_fun_registrar_instructor = $pdo->prepare($sql_fun_registrar_instructor);

    $sql_fun_registrar_funcionario = "SELECT fun_registrar_funcionario(
        ?::NUMERIC, ?::VARCHAR, ?::VARCHAR, ?::VARCHAR, ?::VARCHAR,
        ?::DATE, ?::NUMERIC, ?::NUMERIC, ?::VARCHAR,
        ?::VARCHAR, ?::VARCHAR, ?::VARCHAR,
        ?::NUMERIC, ?::NUMERIC, ?::VARCHAR, ?::NUMERIC,
        ?::BOOLEAN,
        ?::NUMERIC, ?::NUMERIC, ?::VARCHAR, ?::DATE,
        ?::NUMERIC, ?::VARCHAR
    )";
    $stmt_fun_registrar_funcionario = $pdo->prepare($sql_fun_registrar_funcionario);

    // --- 7. SECCIÓN PERFILES (tab_menu_usuarios V.1.3) ---
// V.1.3: La función ahora solo necesita 2 parámetros (sin nom_programa)
    $sql_ins_perfil = "SELECT fun_insert_menu_usuarios(?::VARCHAR, ?::VARCHAR)";
    $stmt_ins_perfil = $pdo->prepare($sql_ins_perfil);

    $sql_del_perfil = "SELECT fun_delete_perfil_usuario(?::VARCHAR)";
    $stmt_del_perfil = $pdo->prepare($sql_del_perfil);

    // Consultas para llenar la interfaz
    $stmt_list_usuarios = $pdo->prepare(
        "SELECT id_usuario, nom_usuario, ind_usuario FROM tab_usuarios ORDER BY nom_usuario"
    );
    $stmt_list_menus = $pdo->prepare("SELECT id_menu, nom_menu, ind_id_padre, nom_programa FROM tab_menus ORDER BY id_menu ASC");

    // --- 8. INSTRUCTOR — Mis fichas / asistencia ---
    $sql_fun_listar_fichas_instructor = 'SELECT * FROM fun_listar_fichas_instructor(?::NUMERIC)';
    $stmt_fun_listar_fichas_instructor = $pdo->prepare($sql_fun_listar_fichas_instructor);

    $sql_fun_listar_asistencia_ficha = 'SELECT * FROM fun_listar_asistencia_ficha(?::NUMERIC, ?::NUMERIC, ?::DATE, ?::DATE)';
    $stmt_fun_listar_asistencia_ficha = $pdo->prepare($sql_fun_listar_asistencia_ficha);

    $sql_fun_listar_fichas_admin = 'SELECT * FROM fun_listar_fichas_admin()';
    $stmt_fun_listar_fichas_admin = $pdo->prepare($sql_fun_listar_fichas_admin);

    $sql_fun_listar_asistencia_ficha_admin = 'SELECT * FROM fun_listar_asistencia_ficha_admin(?::NUMERIC, ?::DATE, ?::DATE)';
    $stmt_fun_listar_asistencia_ficha_admin = $pdo->prepare($sql_fun_listar_asistencia_ficha_admin);

    $sql_fun_guardar_asistencia_manual = 'SELECT fun_guardar_asistencia_manual(?::NUMERIC, ?::NUMERIC, ?::NUMERIC, ?::DATE, ?::TEXT, ?::TEXT, ?::BOOLEAN)';
    $stmt_fun_guardar_asistencia_manual = $pdo->prepare($sql_fun_guardar_asistencia_manual);

    if (session_status() === PHP_SESSION_NONE && !headers_sent()) {
        session_start();
    }

    if (session_status() === PHP_SESSION_ACTIVE && !empty($_SESSION['id_usuario'])) {
        require_once __DIR__ . '/helpers.php';

        $estadoSesion = Db::gestionarSesionEnRequest(
            $stmt_fun_validar_sesion_activa,
            $stmt_fun_salida_sesion,
            $stmt_fun_touch_sesion,
            SESSION_TIMEOUT,
            $stmt_sesion_ip_activa
        );

        if ($estadoSesion !== Db::SESION_OK) {
            $_SESSION = [];
            if (session_status() === PHP_SESSION_ACTIVE) {
                session_destroy();
            }
            $sesionQuery = $estadoSesion === Db::SESION_IP_MISMATCH ? 'ip' : 'invalida';
            header('Location: ' . smartcsetLoginUrl() . '?sesion=' . $sesionQuery);
            exit();
        }

        smartcsetSincronizarSesionUsuario($pdo);
    }

} catch (PDOException $e) {
    die('Error crítico en prepare.php: ' . Db::connectionErrorMessage($e));
}
?>