<?php
declare(strict_types=1);

/**
 * Subida del logo institucional → public/uploads/logos/
 * Devuelve ruta relativa desde la raíz del proyecto (para path_logo en BD).
 */
class LogoUpload
{
    private const MAX_BYTES = 5 * 1024 * 1024;
    private const RELATIVE_DIR = 'public/uploads/logos';

    /** @var array<string, string> */
    private const MIME_TO_EXT = [
        'image/png'  => 'png',
        'image/jpeg' => 'jpg',
        'image/gif'  => 'gif',
        'image/webp' => 'webp',
    ];

    public static function projectRoot(): string
    {
        return dirname(__DIR__, 2);
    }

    public static function absoluteDir(): string
    {
        return self::projectRoot() . '/' . self::RELATIVE_DIR;
    }

    /**
     * @param array{name?: string, type?: string, tmp_name?: string, error?: int, size?: int} $file
     */
    public static function store(array $file): string
    {
        $error = (int) ($file['error'] ?? UPLOAD_ERR_NO_FILE);
        if ($error === UPLOAD_ERR_NO_FILE) {
            throw new InvalidArgumentException('No se seleccionó ningún archivo.');
        }
        if ($error !== UPLOAD_ERR_OK) {
            throw new RuntimeException('Error al subir el archivo (código ' . $error . ').');
        }

        $tmp = (string) ($file['tmp_name'] ?? '');
        if ($tmp === '' || !is_uploaded_file($tmp)) {
            throw new RuntimeException('Archivo de subida no válido.');
        }

        $size = (int) ($file['size'] ?? 0);
        if ($size <= 0 || $size > self::MAX_BYTES) {
            throw new InvalidArgumentException('El logo debe pesar entre 1 byte y 5 MB.');
        }

        $finfo = new finfo(FILEINFO_MIME_TYPE);
        $mime = $finfo->file($tmp) ?: '';
        if (!isset(self::MIME_TO_EXT[$mime])) {
            throw new InvalidArgumentException('Formato no permitido. Use PNG, JPG, GIF o WebP.');
        }

        $ext = self::MIME_TO_EXT[$mime];
        $dir = self::absoluteDir();
        if (!is_dir($dir) && !mkdir($dir, 0755, true) && !is_dir($dir)) {
            throw new RuntimeException('No se pudo crear el directorio de logos.');
        }

        foreach (glob($dir . '/logo.*') ?: [] as $old) {
            if (is_file($old)) {
                @unlink($old);
            }
        }

        $filename = 'logo.' . $ext;
        $dest = $dir . '/' . $filename;
        if (!move_uploaded_file($tmp, $dest)) {
            throw new RuntimeException('No se pudo guardar el logo en el servidor.');
        }

        @chmod($dest, 0644);

        return self::RELATIVE_DIR . '/' . $filename;
    }
}
