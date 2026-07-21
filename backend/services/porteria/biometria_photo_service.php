<?php
declare(strict_types=1);

/**
 * BiometriaPhotoService — Gestión de fotos de enrolamiento facial
 *
 * Guardar y recuperar fotos base64 del enrolamiento biométrico.
 * Fotos se almacenan en filesystem: frontend/web/public/uploads/biometria/
 *
 * MSPI + FASE 0-1:
 * - E2: Cifrado en reposo (fotos en filesystem, no en BD BYTEA)
 * - E6: Validación de uploads (finfo, whitelist MIME)
 * - E10: Auditoría (ruta guardada en tab_enrolamiento_facial para trazabilidad)
 */
class BiometriaPhotoService
{
    // Carpeta base para fotos (relativa a document root)
    private const UPLOAD_BASE = 'uploads/biometria';

    /**
     * Guarda foto base64 en filesystem
     *
     * @param int $idPersona ID de la persona
     * @param string $nombrePersona Primer nombre de la persona (para nomenclatura)
     * @param string $fotoBase64 Foto en formato base64
     * @return string|null Ruta relativa guardada o NULL si falla
     *                     Ej: "uploads/biometria/12345/12345_juan.jpg"
     * @throws InvalidArgumentException Si validación falla
     */
    public static function guardarFoto(int $idPersona, string $nombrePersona, string $fotoBase64): ?string
    {
        // 1. Validar que sea base64 válido
        if (empty($fotoBase64)) {
            throw new InvalidArgumentException('Foto en base64 no puede estar vacía.');
        }

        // Decodificar base64
        $fotoBinaria = base64_decode($fotoBase64, true);
        if ($fotoBinaria === false) {
            throw new InvalidArgumentException('Foto base64 inválida — no se pudo decodificar.');
        }

        // 2. Validar que sea imagen (usar finfo)
        $finfo = new finfo(FILEINFO_MIME_TYPE);
        $mimeType = $finfo->buffer($fotoBinaria);

        $mimeValido = in_array($mimeType, ['image/jpeg', 'image/png', 'image/webp'], true);
        if (!$mimeValido) {
            throw new InvalidArgumentException(
                "Tipo MIME no válido: $mimeType. Se espera: image/jpeg, image/png, image/webp"
            );
        }

        // 3. Crear carpeta base + persona: uploads/biometria/{id_persona}/
        $docRoot = dirname(__DIR__, 3) . '/frontend/web/public';
        $carpetaBase = $docRoot . '/' . self::UPLOAD_BASE;
        $carpetaPersona = $carpetaBase . '/' . $idPersona;

        self::asegurarDirectorioEscribible($carpetaBase, 'base de enrolamiento biométrico');
        self::asegurarDirectorioEscribible($carpetaPersona, 'carpeta de enrolamiento de la persona');

        // 4. Nombrar archivo: {id_persona}_{primer_nombre}.jpg
        $nombreLimpio = preg_replace('/[^a-z0-9]/i', '', strtolower($nombrePersona));
        if (empty($nombreLimpio)) {
            $nombreLimpio = 'persona';
        }

        // Determinar extensión según MIME
        $extension = match ($mimeType) {
            'image/jpeg' => 'jpg',
            'image/png' => 'png',
            'image/webp' => 'webp',
            default => 'jpg',
        };

        $nombreArchivo = "{$idPersona}_{$nombreLimpio}.{$extension}";
        $rutaCompleta = "$carpetaPersona/$nombreArchivo";

        // 5. Guardar archivo
        $bytes = @file_put_contents($rutaCompleta, $fotoBinaria);
        if ($bytes === false) {
            throw new InvalidArgumentException(
                'No se pudo guardar foto en: ' . $rutaCompleta
                . self::detalleErrorFs()
            );
        }

        // 6. Retornar ruta relativa (para guardar en BD)
        return self::UPLOAD_BASE . "/$idPersona/$nombreArchivo";
    }

    /**
     * Lee foto desde filesystem y retorna en base64
     *
     * @param string $rutaRelativa Ruta relativa guardada (ej: "uploads/biometria/12345/12345_juan.jpg")
     * @return string|null Foto en base64 o NULL si no existe
     */
    public static function leerFoto(string $rutaRelativa): ?string
    {
        $docRoot = dirname(__DIR__, 3) . '/frontend/web/public';
        $rutaCompleta = "$docRoot/$rutaRelativa";

        if (!file_exists($rutaCompleta)) {
            return null;
        }

        if (!is_readable($rutaCompleta)) {
            return null;
        }

        $fotoBinaria = file_get_contents($rutaCompleta);
        if ($fotoBinaria === false) {
            return null;
        }

        return base64_encode($fotoBinaria);
    }

    /**
     * Elimina foto del filesystem (si se requiere)
     *
     * @param string $rutaRelativa Ruta relativa
     * @return bool True si se eliminó, false si no existe o error
     */
    public static function eliminarFoto(string $rutaRelativa): bool
    {
        $docRoot = dirname(__DIR__, 3) . '/frontend/web/public';
        $rutaCompleta = "$docRoot/$rutaRelativa";

        if (!file_exists($rutaCompleta)) {
            return false;
        }

        return unlink($rutaCompleta);
    }

    /**
     * Crea el directorio si no existe y verifica que sea escribible.
     *
     * @throws InvalidArgumentException
     */
    private static function asegurarDirectorioEscribible(string $ruta, string $etiqueta): void
    {
        if (!is_dir($ruta)) {
            if (!@mkdir($ruta, 0755, true) && !is_dir($ruta)) {
                throw new InvalidArgumentException(
                    "No se pudo crear {$etiqueta}: {$ruta}"
                    . self::detalleErrorFs()
                );
            }
        }

        if (!is_writable($ruta)) {
            throw new InvalidArgumentException(
                "El directorio de {$etiqueta} no es escribible por el proceso PHP: {$ruta}"
                . ' (revise ownership/permisos, p. ej. www-data y chmod 775).'
                . self::detalleErrorFs()
            );
        }
    }

    private static function detalleErrorFs(): string
    {
        $ultimo = error_get_last();
        if (!is_array($ultimo) || empty($ultimo['message'])) {
            return '';
        }

        return ' [' . (string) $ultimo['message'] . ']';
    }
}
