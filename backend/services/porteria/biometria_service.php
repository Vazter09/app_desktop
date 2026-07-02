<?php
/**
 * Enrolamiento e identificación biométrica facial (portería, app desktop dedicada).
 * Escritura/lectura vía funciones PostgreSQL
 * (prepare.php → $stmt_fun_guardar_biometria, $stmt_fun_identificar_rostro).
 */
require_once __DIR__ . '/foto_service.php';

/** Distancia coseno máxima aceptada como coincidencia (Facenet512, empírico). */
const BIOMETRIA_UMBRAL_DISTANCIA = 0.35;

/**
 * @param float[] $vector 512 componentes (Facenet512)
 */
function biometriaVectorToPgArray(array $vector): string
{
    if (count($vector) !== 512) {
        throw new Exception('El vector facial debe tener 512 dimensiones.');
    }

    return '[' . implode(',', array_map(static fn(float $v): string => (string) $v, $vector)) . ']';
}

/**
 * Guarda la foto de enrolamiento reusando el redimensionado de
 * backend/services/porteria/foto_service.php (requerido previamente).
 * Devuelve la ruta relativa a guardar en tab_biometria_facial.uri_foto.
 */
function biometriaGuardarFoto(int $idPersona, string $dataUrl): ?string
{
    $dataUrl = trim($dataUrl);
    if ($dataUrl === '' || $idPersona < 1) {
        return null;
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

    $dir = smartcsetStoragePorteriaAbs('biometria', (string) $idPersona);
    if (!is_dir($dir) && !mkdir($dir, 0755, true) && !is_dir($dir)) {
        throw new Exception('No se pudo crear la carpeta de almacenamiento de fotos.');
    }

    $nombre = 'rostro_' . date('YmdHis') . '.jpg';
    $rutaAbs = $dir . '/' . $nombre;
    if (file_put_contents($rutaAbs, $bin) === false) {
        throw new Exception('No se pudo guardar la foto en el servidor.');
    }

    return 'storage/porteria/biometria/' . $idPersona . '/' . $nombre;
}

/**
 * Enrola (o reemplaza) la biometría facial de una persona ya existente en tab_personas.
 */
function biometriaEnrolar(
    PDOStatement $stmtGuardar,
    int $idPersona,
    array $vector,
    ?string $uriFoto,
    float $calidadFacial
): void {
    if ($idPersona < 1) {
        throw new Exception('Documento inválido.');
    }

    $stmtGuardar->execute([
        $idPersona,
        biometriaVectorToPgArray($vector),
        $uriFoto,
        $calidadFacial,
    ]);
}

/**
 * Identifica a la persona más parecida al vector recibido.
 * Aplica el umbral de distancia coseno; si no hay coincidencia suficientemente
 * cercana, devuelve null (no se considera identificado).
 *
 * @return array{id_persona: int, distancia: float}|null
 */
function biometriaIdentificar(PDOStatement $stmtIdentificar, array $vector): ?array
{
    $stmtIdentificar->execute([biometriaVectorToPgArray($vector)]);
    $fila = $stmtIdentificar->fetch(PDO::FETCH_ASSOC);

    if ($fila === false || $fila['id_persona_encontrado'] === null) {
        return null;
    }

    $distancia = (float) $fila['distancia_calculada'];
    if ($distancia > BIOMETRIA_UMBRAL_DISTANCIA) {
        return null;
    }

    return [
        'id_persona' => (int) $fila['id_persona_encontrado'],
        'distancia' => $distancia,
    ];
}
