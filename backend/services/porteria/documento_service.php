<?php
/**
 * Validación de documento compartida (ingreso y salida portería).
 */

/**
 * @return numeric-string
 */
function accesoNormalizarDocumento(string $raw): string
{
    $digits = preg_replace('/\D/', '', $raw) ?? '';
    $len = strlen($digits);
    if ($digits === '' || $len < 8 || $len > 10) {
        throw new Exception(
            'El número de documento no es válido (entre 8 y 10 dígitos).'
        );
    }
    return $digits;
}
