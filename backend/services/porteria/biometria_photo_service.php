<?php
declare(strict_types=1);

/**
 * BiometriaPhotoService — Gestión de fotos de enrolamiento facial
 *
 * Fotos en filesystem (BIOMETRIA_FOTO_PATH / smartcsetBiometriaFotoAbs()):
 *   Producción: /var/www/html/desktop-smartcset/src/frontend/img/biometria/{id}/{id}.jpg
 *   Dev default: frontend/web/public/uploads/biometria/{id}/{id}.jpg
 *
 * En BD (tab_personas.ruta_foto_facial) se guarda ruta relativa al storage:
 *   {id_persona}/{id_persona}.jpg
 * Compat: también lee rutas legacy uploads/biometria/...
 *
 * MSPI + FASE 0-1:
 * - E2: Cifrado en reposo (fotos en filesystem, no en BD BYTEA)
 * - E6: Validación de uploads (finfo, whitelist MIME)
 * - E10: Auditoría (ruta guardada en tab_personas.ruta_foto_facial)
 */
class BiometriaPhotoService
{
    /** Prefijo legacy (document root public/). */
    private const LEGACY_UPLOAD_BASE = 'uploads/biometria';

    /**
     * Prefijo legacy de producción (.111): relativo a SMARTCSET_ROOT.
     * Ej. BD: src/frontend/img/biometria/{id}/{id}_nombre.jpg
     */
    private const LEGACY_SRC_IMG_BASE = 'src/frontend/img/biometria';

    /**
     * Árbol live .111: SMARTCSET_ROOT ya es .../smartcset/src.
     * Las fotos reales están en frontend/img/biometria (no src/src/...).
     */
    private const LIVE_SRC_IMG_BASE = 'frontend/img/biometria';

    /** Ruta absoluta de fotos en el servidor live (.111). */
    private const LIVE_ABS_IMG_BASE = '/var/www/html/desktop-smartcset/src/frontend/img/biometria';

    /**
     * Raíz absoluta de almacenamiento (configurable vía .env).
     */
    public static function storageRoot(): string
    {
        if (is_dir(self::LIVE_ABS_IMG_BASE) && is_readable(self::LIVE_ABS_IMG_BASE)) {
            return self::LIVE_ABS_IMG_BASE;
        }
        if (function_exists('smartcsetBiometriaFotoAbs')) {
            return smartcsetBiometriaFotoAbs();
        }

        // Fallback si config.php no cargó el helper (tests aislados).
        return dirname(__DIR__, 3) . '/frontend/web/public/uploads/biometria';
    }

    /**
     * Document root legacy (solo lectura de rutas antiguas).
     */
    public static function documentRoot(): string
    {
        return dirname(__DIR__, 3) . '/frontend/web/public';
    }

    /**
     * Guarda foto base64 en filesystem.
     *
     * Nombre estable: {id_persona}.jpg|png|webp
     * Si ya existe el archivo, lo sobrescribe (update).
     *
     * @return string Ruta relativa a storage (ej: 123/123.jpg) para ruta_foto_facial
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

        $carpetaBase = self::storageRoot();
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

        $rutaRelativa = $idPersona . '/' . $nombreArchivo;
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
        $rutaCompleta = self::resolverRutaCompleta($rutaRelativa);
        if ($rutaCompleta === null) {
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
     * Busca la imagen más reciente en {storage}/{id_persona}/.
     */
    public static function buscarFotoEnCarpetaPersona(int $idPersona): ?string
    {
        if ($idPersona < 1) {
            return null;
        }

        $dirs = [
            self::LIVE_ABS_IMG_BASE . '/' . $idPersona,
            self::storageRoot() . '/' . $idPersona,
            self::documentRoot() . '/' . self::LEGACY_UPLOAD_BASE . '/' . $idPersona,
        ];
        $projectRoot = defined('SMARTCSET_ROOT') ? SMARTCSET_ROOT : dirname(__DIR__, 3);
        $dirs[] = $projectRoot . '/' . self::LIVE_SRC_IMG_BASE . '/' . $idPersona;
        $dirs[] = $projectRoot . '/' . self::LEGACY_SRC_IMG_BASE . '/' . $idPersona;

        $candidatos = [];
        foreach ($dirs as $dir) {
            if (!is_dir($dir)) {
                continue;
            }
            foreach (['jpg', 'jpeg', 'png', 'webp'] as $ext) {
                foreach (glob($dir . '/*.' . $ext) ?: [] as $path) {
                    if (is_file($path) && is_readable($path)) {
                        $candidatos[] = $path;
                    }
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
        return self::resolverRutaCompleta((string) $rutaRelativa) !== null;
    }

    /**
     * Elimina foto del filesystem (si se requiere).
     */
    public static function eliminarFoto(string $rutaRelativa): bool
    {
        $rutaCompleta = self::resolverRutaCompleta($rutaRelativa);
        if ($rutaCompleta === null) {
            return false;
        }

        return unlink($rutaCompleta);
    }

    /**
     * Ruta relativa segura bajo el storage de biometría (sin path traversal).
     * Acepta: {id}/{archivo}, uploads/biometria/...,
     * frontend/img/biometria/... y src/frontend/img/biometria/...
     */
    public static function esRutaFotoValida(string $rutaRelativa): bool
    {
        $ruta = str_replace('\\', '/', trim($rutaRelativa));
        if ($ruta === '' || str_contains($ruta, '..')) {
            return false;
        }

        if (str_starts_with($ruta, self::LEGACY_UPLOAD_BASE . '/')) {
            return true;
        }

        foreach ([self::LIVE_SRC_IMG_BASE, self::LEGACY_SRC_IMG_BASE] as $base) {
            if (str_starts_with($ruta, $base . '/')) {
                $resto = substr($ruta, strlen($base . '/'));
                return (bool) preg_match(
                    '#^[0-9]+/[0-9A-Za-z._-]+\.(jpe?g|png|webp)$#i',
                    $resto
                );
            }
        }

        // Nuevo / relativo a storage: 123456/123456.jpg (también *_nombre legacy)
        return (bool) preg_match(
            '#^[0-9]+/[0-9A-Za-z._-]+\.(jpe?g|png|webp)$#i',
            $ruta
        );
    }

    /**
     * Resuelve ruta de BD a archivo físico (nuevo storage o legacy).
     */
    private static function resolverRutaCompleta(string $rutaRelativa): ?string
    {
        if (!self::esRutaFotoValida($rutaRelativa)) {
            return null;
        }

        $ruta = str_replace('\\', '/', trim($rutaRelativa));

        if (str_starts_with($ruta, self::LEGACY_UPLOAD_BASE . '/')) {
            $legacy = self::documentRoot() . '/' . $ruta;
            if (is_file($legacy) && is_readable($legacy)) {
                return $legacy;
            }
            // Misma ruta relativa bajo el storage nuevo (por si se movieron archivos).
            $relativaNueva = substr($ruta, strlen(self::LEGACY_UPLOAD_BASE . '/'));
            $nueva = self::storageRoot() . '/' . $relativaNueva;
            if (is_file($nueva) && is_readable($nueva)) {
                return $nueva;
            }

            return null;
        }

        $projectRoot = defined('SMARTCSET_ROOT') ? SMARTCSET_ROOT : dirname(__DIR__, 3);

        foreach ([self::LIVE_SRC_IMG_BASE, self::LEGACY_SRC_IMG_BASE] as $base) {
            if (!str_starts_with($ruta, $base . '/')) {
                continue;
            }
            $desdeRoot = $projectRoot . '/' . $ruta;
            if (is_file($desdeRoot) && is_readable($desdeRoot)) {
                return $desdeRoot;
            }
            $relativaNueva = substr($ruta, strlen($base . '/'));
            $desdeLive = $projectRoot . '/' . self::LIVE_SRC_IMG_BASE . '/' . $relativaNueva;
            if (is_file($desdeLive) && is_readable($desdeLive)) {
                return $desdeLive;
            }
            $desdeStorage = self::storageRoot() . '/' . $relativaNueva;
            if (is_file($desdeStorage) && is_readable($desdeStorage)) {
                return $desdeStorage;
            }

            return null;
        }

        $completa = self::storageRoot() . '/' . $ruta;
        if (is_file($completa) && is_readable($completa)) {
            return $completa;
        }

        $desdeAbs = self::LIVE_ABS_IMG_BASE . '/' . $ruta;
        if (is_file($desdeAbs) && is_readable($desdeAbs)) {
            return $desdeAbs;
        }

        $desdeLiveRel = $projectRoot . '/' . self::LIVE_SRC_IMG_BASE . '/' . $ruta;
        if (is_file($desdeLiveRel) && is_readable($desdeLiveRel)) {
            return $desdeLiveRel;
        }

        return null;
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
