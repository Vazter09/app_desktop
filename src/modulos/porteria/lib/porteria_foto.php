<?php
/**
 * Guarda foto opcional de portería vinculada a un registro en tab_log_ingresos.
 */

const PORTERIA_FOTO_MAX_BYTES = 512000;
const PORTERIA_FOTO_MAX_EDGE = 800;

/**
 * @param 'ingreso'|'salida' $contexto
 */
function porteriaGuardarFotoRegistro(
    PDO $pdo,
    int $idIngreso,
    string $contexto,
    string $dataUrl
): void {
    $dataUrl = trim($dataUrl);
    if ($dataUrl === '' || $idIngreso < 1) {
        return;
    }

    if (!preg_match('#^data:image/(jpeg|jpg|png|webp);base64,(.+)$#i', $dataUrl, $m)) {
        throw new Exception('El formato de la foto no es válido.');
    }

    $bin = base64_decode($m[2], true);
    if ($bin === false || strlen($bin) < 100) {
        throw new Exception('No se pudo leer la imagen.');
    }
    if (strlen($bin) > PORTERIA_FOTO_MAX_BYTES * 2) {
        throw new Exception('La imagen es demasiado grande. Use una resolución menor.');
    }

    $bin = porteriaFotoRedimensionar($bin, $m[1]);
    if (strlen($bin) > PORTERIA_FOTO_MAX_BYTES) {
        throw new Exception('La imagen supera el tamaño permitido (500 KB).');
    }

    $root = dirname(__DIR__, 4);
    $subdir = $contexto === 'salida' ? 'salidas' : 'ingresos';
    $fechaDir = date('Y-m-d');
    $dir = $root . '/storage/porteria/' . $subdir . '/' . $fechaDir;
    if (!is_dir($dir) && !mkdir($dir, 0755, true) && !is_dir($dir)) {
        throw new Exception('No se pudo crear la carpeta de almacenamiento de fotos.');
    }

    $nombre = $idIngreso . '_' . date('His') . '.jpg';
    $rutaAbs = $dir . '/' . $nombre;
    if (file_put_contents($rutaAbs, $bin) === false) {
        throw new Exception('No se pudo guardar la foto en el servidor.');
    }

    $rutaRel = 'storage/porteria/' . $subdir . '/' . $fechaDir . '/' . $nombre;

    $stmt = $pdo->prepare(
        "UPDATE tab_log_ingresos
            SET val_datos_origen = COALESCE(val_datos_origen, '{}'::jsonb)
                || jsonb_build_object(
                    'foto_registro', TRUE,
                    'foto_contexto', ?::TEXT,
                    'foto_ruta', ?::TEXT,
                    'foto_fec', to_char(NOW(), 'YYYY-MM-DD HH24:MI:SS')
                )
          WHERE id_ingreso = ?::INTEGER"
    );
    $stmt->execute([$contexto, $rutaRel, $idIngreso]);
}

function porteriaFotoRedimensionar(string $bin, string $mime): string
{
    if (!function_exists('imagecreatefromstring')) {
        return $bin;
    }

    $src = @imagecreatefromstring($bin);
    if ($src === false) {
        return $bin;
    }

    $w = imagesx($src);
    $h = imagesy($src);
    $max = PORTERIA_FOTO_MAX_EDGE;
    $scale = min(1, $max / max($w, $h));

    if ($scale < 1) {
        $nw = (int) round($w * $scale);
        $nh = (int) round($h * $scale);
        $dst = imagecreatetruecolor($nw, $nh);
        imagecopyresampled($dst, $src, 0, 0, 0, 0, $nw, $nh, $w, $h);
        imagedestroy($src);
        $src = $dst;
    }

    ob_start();
    imagejpeg($src, null, 82);
    imagedestroy($src);
    $out = ob_get_clean();

    return is_string($out) && $out !== '' ? $out : $bin;
}
