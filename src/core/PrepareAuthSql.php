<?php
declare(strict_types=1);

/** SQL compartido entre prepare.php y prepare_login.php (una sola definición). */
final class PrepareAuthSql
{
    public const LOGIN = <<<'SQL'
SELECT id_usuario, nom_usuario, pass_usuario, mail_usuario, ind_usuario, ind_estado
FROM tab_usuarios
WHERE id_usuario = ?::TEXT
SQL;

    /** Escritura / reglas de negocio → funciones PL/pgSQL (retorno TEXT). */
    public const INGRESO_SESION = 'SELECT fun_ingreso_sesion(?::TEXT, ?::TEXT)';

    public const SALIDA_SESION = 'SELECT fun_salida_sesion(?::INTEGER, ?::TEXT, ?::TEXT)';

    public const TOUCH_SESION = 'SELECT fun_actualizar_sesion_actividad(?::INTEGER, ?::TEXT, ?::TEXT)';

    /** NULL = sesión inválida; TEXT = ult_actividad de la sesión activa. */
    public const VALIDAR_SESION_ACTIVA = 'SELECT fun_validar_sesion_activa(?::INTEGER, ?::TEXT)';

    public const SESION_IP_ACTIVA = <<<'SQL'
SELECT ip_cliente FROM tab_sesiones
WHERE id_sesion = ?::INTEGER AND id_usuario = ?::TEXT AND fec_fin IS NULL
SQL;
}
