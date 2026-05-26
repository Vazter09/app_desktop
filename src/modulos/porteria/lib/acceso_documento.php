<?php
/**
 * Validación de documento compartida (ingreso y salida portería).
 */

/**
 * @return numeric-string
 */
function accesoNormalizarDocumento(string $raw): string
{
    $digits = preg_replace('/\D/', '', $raw);
    if ($digits === '' || strlen($digits) > 10) {
        throw new Exception('El número de documento no es válido (máximo 10 dígitos).');
    }
    return $digits;
}
