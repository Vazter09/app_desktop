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
 * - E10: Auditoría (ruta guardada en tab_personas.ruta_foto_facial)
 */
class BiometriaPhotoService
{
    // Carpeta base para fotos (relativa a document root)
    private const UPLOAD_BASE = 'uploads/biometria';

    /**
     * Document root físico (frontend/web/public).
     */
    public static function documentRoot(): string
    {
        return dirname(__DIR__, 3) . '/frontend/web/public';
    }

    /**
     * Guarda foto base64 en filesystem.
     *
     * Nombre estable: {id_persona}.jpg|png|webp (evita desfaces
     * franz vs franzanderson cuando cambia el parser del nombre).
     *
     * @return string Ruta relativa (ej: uploads/biometria/123/123.jpg)
     * @throws InvalidArgumentException Si validación o escritura falla
     */
    public static function guardarFoto(int $idPersona, string $nombrePersona, string $fotoBase64): ?string
    {
        unset($nombrePersona); // compat firma; el nombre de archivo es el id.

        if ($idPersona < 1) {
            throw new InvalidArgumentException('id_persona inválido para guardar foto.');
        }
        if (empty($fotoBase64)) {
            throw new InvalidArgumentException('Foto en base64 no puede estar vacía.');
        }

        $fotoBase64 = self::normalizarBase64($fotoBase64);
        $fotoBinaria = base64_decode($fotoBase64, true);
        if ($fotoBinaria === false || $fotoBinaria === '') {
            throw new InvalidArgumentException('Foto base64 inválida — no se pudo decodificar.');
        }

        $finfo = new finfo(FILEINFO_MIME_TYPE);
        $mimeType = $finfo->buffer($fotoBinaria);
        $mimeValido = in_array($mimeType, ['image/jpeg', 'image/png', 'image/webp'], true);
        if (!$mimeValido) {
            throw new InvalidArgumentException(
                "Tipo MIME no válido: $mimeType. Se espera: image/jpeg, image/png, image/webp"
            );
        }

        $docRoot = self::documentRoot();
        $carpetaBase = $docRoot . '/' . self::UPLOAD_BASE;
        $carpetaPersona = $carpetaBase . '/' . $idPersona;

        self::asegurarDirectorioEscribible($carpetaBase, 'base de enrolamiento biométrico');
        self::asegurarDirectorioEscribible($carpetaPersona, 'carpeta de enrolamiento de la persona');

        $extension = match ($mimeType) {
            'image/jpeg' => 'jpg',
            'image/png' => 'png',
            'image/webp' => 'webp',
            default => 'jpg',
        };

        $nombreArchivo = $idPersona . '.' . $extension;
        $rutaCompleta = $carpetaPersona . '/' . $nombreArchivo;

        $bytes = @file_put_contents($rutaCompleta, $fotoBinaria);
        if ($bytes === false || !is_file($rutaCompleta) || !is_readable($rutaCompleta)) {
            throw new InvalidArgumentException(
                'No se pudo guardar foto en: ' . $rutaCompleta
                . self::detalleErrorFs()
            );
        }

        $rutaRelativa = self::UPLOAD_BASE . '/' . $idPersona . '/' . $nombreArchivo;
        if (!self::esRutaFotoValida($rutaRelativa)) {
            throw new InvalidArgumentException('Ruta de foto generada no es válida.');
        }

        return $rutaRelativa;
    }

    /**
     * Lee foto desde filesystem y retorna en base64.
     */
    public static function leerFoto(string $rutaRelativa): ?string
    {
        if (!self::esRutaFotoValida($rutaRelativa)) {
            return null;
        }

        $rutaCompleta = self::documentRoot() . '/' . str_replace('\\', '/', trim($rutaRelativa));
        if (!is_file($rutaCompleta) || !is_readable($rutaCompleta)) {
            return null;
        }

        $fotoBinaria = file_get_contents($rutaCompleta);
        if ($fotoBinaria === false || $fotoBinaria === '') {
            return null;
        }

        return base64_encode($fotoBinaria);
    }

    /**
     * Foto de enrolamiento: ruta en BD, o cualquier imagen en la carpeta
     * de la persona (recuperación si el nombre de archivo divergió).
     */
    public static function resolverFotoBase64(?string $rutaRelativa, int $idPersona): ?string
    {
        $ruta = trim((string) $rutaRelativa);
        if ($ruta !== '') {
            $foto = self::leerFoto($ruta);
            if ($foto !== null) {
                return $foto;
            }
        }

        return self::buscarFotoEnCarpetaPersona($idPersona);
    }

    /**
     * Busca la imagen más reciente en uploads/biometria/{id_persona}/.
     */
    public static function buscarFotoEnCarpetaPersona(int $idPersona): ?string
    {
        if ($idPersona < 1) {
            return null;
        }

        $dir = self::documentRoot() . '/' . self::UPLOAD_BASE . '/' . $idPersona;
        if (!is_dir($dir)) {
            return null;
        }

        $candidatos = [];
        foreach (['jpg', 'jpeg', 'png', 'webp'] as $ext) {
            foreach (glob($dir . '/*.' . $ext) ?: [] as $path) {
                if (is_file($path) && is_readable($path)) {
                    $candidatos[] = $path;
                }
            }
        }
        if ($candidatos === []) {
            return null;
        }

        usort(
            $candidatos,
            static fn(string $a, string $b): int => (filemtime($b) ?: 0) <=> (filemtime($a) ?: 0)
        );

        $fotoBinaria = file_get_contents($candidatos[0]);
        if ($fotoBinaria === false || $fotoBinaria === '') {
            return null;
        }

        return base64_encode($fotoBinaria);
    }

    /**
     * True si la ruta de BD apunta a un archivo legible en disco.
     */
    public static function archivoExiste(?string $rutaRelativa): bool
    {
        $ruta = trim((string) $rutaRelativa);
        if ($ruta === '' || !self::esRutaFotoValida($ruta)) {
            return false;
        }
        $completa = self::documentRoot() . '/' . str_replace('\\', '/', $ruta);

        return is_file($completa) && is_readable($completa);
    }

    /**
     * Elimina foto del filesystem (si se requiere).
     */
    public static function eliminarFoto(string $rutaRelativa): bool
    {
        if (!self::esRutaFotoValida($rutaRelativa)) {
            return false;
        }

        $rutaCompleta = self::documentRoot() . '/' . str_replace('\\', '/', trim($rutaRelativa));
        if (!is_file($rutaCompleta)) {
            return false;
        }

        return unlink($rutaCompleta);
    }

    /**
     * Ruta relativa segura bajo uploads/biometria/ (sin path traversal).
     */
    public static function esRutaFotoValida(string $rutaRelativa): bool
    {
        $ruta = str_replace('\\', '/', trim($rutaRelativa));
        if ($ruta === '' || str_contains($ruta, '..')) {
            return false;
        }

        return str_starts_with($ruta, self::UPLOAD_BASE . '/');
    }

    private static function normalizarBase64(string $fotoBase64): string
    {
        $fotoBase64 = trim($fotoBase64);
        if (preg_match('#^data:image/[a-zA-Z0-9.+-]+;base64,(.+)$#s', $fotoBase64, $m) === 1) {
            return trim($m[1]);
        }

        return $fotoBase64;
    }

    /**
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
