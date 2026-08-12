<?php
/**
 * Parseo de captura de documento (PDF417 cédula CO, manual).
 * Convención PDF417 (@): [0]=NUIP, [1]=apellido1, [2]=apellido2, [3]=nombre1, [4]=nombre2.
 */
require_once __DIR__ . '/documento_service.php';

const ACCESO_METODO_MANUAL = 1;
const ACCESO_METODO_QR = 2;
const ACCESO_METODO_BARRAS = 3;
const ACCESO_METODO_BIOMETRICO = 4;
const ACCESO_METODO_HUELLA = 5;
const ACCESO_PDF417_MIN_LEN = 40;

/**
 * @return array{documento: string, nombres: string, apellidos: string, origen: string, tipo_doc: string, id_metodo_aut: int, captura_raw: string}
 */
function accesoParseCaptura(string $raw): array
{
    $trimmed = str_replace("\t", '@', trim($raw));
    if ($trimmed === '') {
        return accesoCapturaVacia('');
    }

    if (str_contains($trimmed, '@') && strlen($trimmed) >= ACCESO_PDF417_MIN_LEN) {
        return accesoParsePdf417Colombia($trimmed);
    }

    $documento = preg_replace('/\D/', '', $trimmed) ?? '';

    return [
        'documento' => substr($documento, 0, 10),
        'nombres' => '',
        'apellidos' => '',
        'origen' => 'manual',
        'tipo_doc' => 'CC',
        'id_metodo_aut' => ACCESO_METODO_MANUAL,
        'captura_raw' => $trimmed,
    ];
}

/**
 * @return array{documento: string, nombres: string, apellidos: string, origen: string, tipo_doc: string, id_metodo_aut: int, captura_raw: string}
 */
function accesoCapturaVacia(string $raw): array
{
    return [
        'documento' => '',
        'nombres' => '',
        'apellidos' => '',
        'origen' => 'manual',
        'tipo_doc' => 'CC',
        'id_metodo_aut' => ACCESO_METODO_MANUAL,
        'captura_raw' => $raw,
    ];
}

/**
 * @return array{documento: string, nombres: string, apellidos: string, origen: string, tipo_doc: string, id_metodo_aut: int, captura_raw: string}
 */
function accesoParsePdf417Colombia(string $raw): array
{
    $parts = array_map('trim', explode('@', str_replace("\t", '@', $raw)));
    $documento = '';

    foreach ($parts as $part) {
        $digits = preg_replace('/\D/', '', $part) ?? '';
        if (strlen($digits) >= 8 && strlen($digits) <= 10 && !accesoPareceFechaDdmmyyyy($digits)) {
            $documento = $digits;
            break;
        }
    }
    if ($documento === '' && isset($parts[0])) {
        $digits0 = substr(preg_replace('/\D/', '', $parts[0]) ?? '', 0, 10);
        if (
            strlen($digits0) >= 8
            && strlen($digits0) <= 10
            && !accesoPareceFechaDdmmyyyy($digits0)
        ) {
            $documento = $digits0;
        }
    }

    $apellidos = accesoJoinNameParts($parts[1] ?? '', $parts[2] ?? '');
    $nombres = accesoJoinNameParts($parts[3] ?? '', $parts[4] ?? '');

    return [
        'documento' => $documento,
        'nombres' => $nombres,
        'apellidos' => $apellidos,
        'origen' => 'pdf417',
        'tipo_doc' => 'CC',
        'id_metodo_aut' => ACCESO_METODO_BARRAS,
        'captura_raw' => $raw,
    ];
}

function accesoPareceFechaDdmmyyyy(string $digits): bool
{
    if (strlen($digits) !== 8 || !ctype_digit($digits)) {
        return false;
    }
    $dia = (int) substr($digits, 0, 2);
    $mes = (int) substr($digits, 2, 2);
    $anio = (int) substr($digits, 4, 4);

    return $dia >= 1 && $dia <= 31 && $mes >= 1 && $mes <= 12 && $anio >= 1900 && $anio <= 2100;
}

function accesoJoinNameParts(string ...$segments): string
{
    $out = [];
    foreach ($segments as $s) {
        $s = trim($s);
        if ($s === '' || preg_match('/^\d+$/', $s)) {
            continue;
        }
        // Omite sexo (M/F) y RH (A+/B+/O-/RH O+…) del PDF417.
        if (
            preg_match('/^[MF]$/i', $s)
            || preg_match('/^(?:RH\s*)?[ABO]\s*[+-]?$/i', $s)
        ) {
            continue;
        }
        $out[] = $s;
    }

    return trim(implode(' ', $out));
}

/**
 * Normaliza documento y nombres desde POST de portería.
 *
 * @return array{documento: string, nombres: string, apellidos: string, origen: string, tipo_doc: string, id_metodo_aut: int, captura_raw: string}
 */
function accesoDocumentoDesdePost(array $post): array
{
    $rawCaptura = trim($post['hid_captura_raw'] ?? '');
    $rawDoc = trim($post['txt_documento'] ?? '');
    $raw = $rawCaptura !== '' ? $rawCaptura : $rawDoc;

    $parsed = accesoParseCaptura($raw);

    if ($parsed['documento'] === '' && $rawDoc !== '') {
        $parsed = accesoParseCaptura($rawDoc);
    }

    $parsed['documento'] = accesoNormalizarDocumento($parsed['documento']);

    $tipoPost = trim($post['sel_tipo_doc'] ?? '');
    if ($tipoPost !== '') {
        $parsed['tipo_doc'] = $tipoPost;
    }

    $metodoPost = (int) ($post['hid_metodo_aut'] ?? 0);
    if (
        $metodoPost === ACCESO_METODO_QR
        || $metodoPost === ACCESO_METODO_BARRAS
        || $metodoPost === ACCESO_METODO_MANUAL
        || $metodoPost === ACCESO_METODO_BIOMETRICO
        || $metodoPost === ACCESO_METODO_HUELLA
    ) {
        $parsed['id_metodo_aut'] = $metodoPost;
    } elseif ($parsed['origen'] === 'pdf417') {
        $parsed['id_metodo_aut'] = ACCESO_METODO_BARRAS;
    } else {
        $parsed['id_metodo_aut'] = ACCESO_METODO_MANUAL;
    }

    $nomPost = strtoupper(trim($post['txt_nombres'] ?? ''));
    $apePost = strtoupper(trim($post['txt_apellidos'] ?? ''));
    if ($nomPost !== '') {
        $parsed['nombres'] = $nomPost;
    } elseif ($parsed['nombres'] !== '') {
        $parsed['nombres'] = strtoupper($parsed['nombres']);
    }
    if ($apePost !== '') {
        $parsed['apellidos'] = $apePost;
    } elseif ($parsed['apellidos'] !== '') {
        $parsed['apellidos'] = strtoupper($parsed['apellidos']);
    }

    return $parsed;
}
