<?php
declare(strict_types=1);

/**
 * Fragmento AJAX/full: requiere $listadoShellConfig (array para listadoRenderShell).
 */

if (!isset($listadoShellConfig) || !is_array($listadoShellConfig)) {
    return;
}

require_once dirname(__DIR__, 3) . '/core/listado_ui.php';

listadoRenderShell($listadoShellConfig);
