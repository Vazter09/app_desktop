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

    public const INGRESO_SESION = 'SELECT fun_ingreso_sesion(?::TEXT)';
}
