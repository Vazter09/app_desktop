<?php

declare(strict_types=1);

/**
 * Enrolamiento e identificación por huella dactilar.
 * Plantilla maestra: tab_personas.val_huella_digital (BYTEA).
 * Match exacto del BYTEA (SDK del vendor puede normalizar antes de enviar).
 */

/** Tamaño mínimo aceptable de plantilla (bytes). */
const BIOMETRIA_HUELLA_MIN_BYTES = 16;

/** Tamaño máximo (defensa — evita payloads enormes). */
const BIOMETRIA_HUELLA_MAX_BYTES = 8192;

/**
 * Decodifica plantilla desde base64 (cliente desktop/app).
 *
 * @throws InvalidArgumentException
 */
function biometriaHuellaDesdeBase64(string $templateB64): string
{
    $raw = base64_decode(trim($templateB64), true);
    if ($raw === false) {
        throw new InvalidArgumentException('La plantilla de huella no es base64 válido.');
    }
    biometriaHuellaValidarRaw($raw);

    return $raw;
}

/**
 * @throws InvalidArgumentException
 */
function biometriaHuellaValidarRaw(string $raw): void
{
    $len = strlen($raw);
    if ($len < BIOMETRIA_HUELLA_MIN_BYTES) {
        throw new InvalidArgumentException(
            'La plantilla de huella es demasiado corta (mín. '
            . BIOMETRIA_HUELLA_MIN_BYTES . ' bytes).'
        );
    }
    if ($len > BIOMETRIA_HUELLA_MAX_BYTES) {
        throw new InvalidArgumentException(
            'La plantilla de huella excede el tamaño máximo permitido.'
        );
    }
}

/**
 * Literal PostgreSQL hex BYTEA: \xdeadbeef
 */
function biometriaHuellaAByteaLiteral(string $raw): string
{
    biometriaHuellaValidarRaw($raw);

    return '\\x' . bin2hex($raw);
}

/**
 * Enrola huella para persona ya registrada.
 *
 * @return int id_persona
 */
function biometriaHuellaGuardarEnrolamiento(
    PDOStatement $stmtGuardar,
    int $idPersona,
    string $templateRaw,
    ?float $calidadHuella = null
): int {
    $bytea = biometriaHuellaAByteaLiteral($templateRaw);
    $stmtGuardar->execute([$idPersona, $bytea, $calidadHuella]);
    $id = $stmtGuardar->fetchColumn();

    return $id !== false ? (int) $id : $idPersona;
}

/**
 * Identifica persona por plantilla (match exacto en BD).
 *
 * @return int|null id_persona
 */
function biometriaHuellaIdentificarPersona(
    PDOStatement $stmtIdentificar,
    string $templateRaw
): ?int {
    $bytea = biometriaHuellaAByteaLiteral($templateRaw);
    $stmtIdentificar->execute([$bytea]);
    $resultado = $stmtIdentificar->fetchColumn();

    return $resultado !== null && $resultado !== false ? (int) $resultado : null;
}
