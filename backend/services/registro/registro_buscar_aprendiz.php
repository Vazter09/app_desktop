<?php
declare(strict_types=1);

/** id_tipo_persona para Aprendiz en tab_personas. */
const REGISTRO_TIPO_PERSONA_APRENDIZ = 2;

/**
 * Normaliza número de documento: solo dígitos, máximo 10.
 */
function registroNormalizarDocumentoAprendiz(string $idPersona): string
{
    $digits = preg_replace('/\D/', '', $idPersona) ?? '';
    if (strlen($digits) > 10) {
        $digits = substr($digits, 0, 10);
    }

    return $digits;
}

/**
 * Busca aprendiz por documento y devuelve datos del formulario o null si no existe la persona.
 *
 * @return array{status: string, message?: string, data: array<string, mixed>}|null
 */
function registroBuscarAprendizPorDocumento(PDO $pdo, string $idPersona, ?string $idTipoDocum): ?array
{
    $doc = registroNormalizarDocumentoAprendiz($idPersona);
    if ($doc === '' || strlen($doc) < 6) {
        return null;
    }

    $tipoDocum = $idTipoDocum !== null ? trim($idTipoDocum) : '';
    $tipoDocum = $tipoDocum === '' ? null : $tipoDocum;

    $sql = "
        SELECT
            p.id_persona,
            p.id_tipo_docum,
            p.id_tipo_persona,
            p.nom_persona,
            p.ape_persona,
            p.mail_persona,
            p.fec_nacimiento,
            p.ind_genero,
            p.id_nivel_estudio,
            p.id_profesion,
            p.id_dpto_reside,
            p.id_ciudad_reside,
            p.dir_ciudad_reside,
            p.tel_persona_fijo,
            p.tel_persona_movil,
            p.nom_contacto_emergencias,
            p.tel_contacto_emergencias,
            p.ind_envio_correo,
            a.ind_etdo_formacion,
            (a.datos_aprendiz).tel_alterno       AS tel_alterno,
            (a.datos_aprendiz).tel_sede          AS tel_sede,
            (a.datos_aprendiz).ext_sede          AS ext_sede,
            (a.datos_aprendiz).tel_padre_fijo    AS tel_padre_fijo,
            (a.datos_aprendiz).tel_padre_movil   AS tel_padre_movil,
            (a.datos_aprendiz).val_mail_institucional AS val_mail_institucional,
            f.id_ficha
        FROM tab_personas p
        LEFT JOIN tab_aprendices a ON a.id_aprendiz = p.id_persona
        LEFT JOIN LATERAL (
            SELECT af.id_ficha
              FROM tab_aprendices_fichas af
             WHERE af.id_aprendiz = p.id_persona
             ORDER BY af.fec_insert DESC NULLS LAST, af.id_ficha DESC
             LIMIT 1
        ) f ON TRUE
        WHERE p.id_persona = :id_persona::NUMERIC
    ";

    $params = [':id_persona' => $doc];

    if ($tipoDocum !== null) {
        $sql .= ' AND p.id_tipo_docum = :id_tipo_docum::TEXT';
        $params[':id_tipo_docum'] = $tipoDocum;
    }

    $sql .= ' LIMIT 1';

    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);

    if ($row === false) {
        return null;
    }

    $data = registroMapAprendizFormRow($row);
    $tipoPersona = (int) ($row['id_tipo_persona'] ?? 0);
    $esAprendiz = $tipoPersona === REGISTRO_TIPO_PERSONA_APRENDIZ;
    $tieneAprendiz = $row['ind_etdo_formacion'] !== null;

    if (!$esAprendiz) {
        return [
            'status'  => 'partial',
            'message' => 'La persona existe en el sistema pero no está registrada como aprendiz.',
            'data'    => $data,
        ];
    }

    if (!$tieneAprendiz) {
        return [
            'status'  => 'partial',
            'message' => 'La persona está marcada como aprendiz, pero faltan datos en tab_aprendices.',
            'data'    => $data,
        ];
    }

    return [
        'status' => 'ok',
        'data'   => $data,
    ];
}

/**
 * @param array<string, mixed> $row
 * @return array<string, mixed>
 */
function registroMapAprendizFormRow(array $row): array
{
    $fecNac = $row['fec_nacimiento'] ?? '';
    if ($fecNac instanceof DateTimeInterface) {
        $fecNac = $fecNac->format('Y-m-d');
    } else {
        $fecNac = trim((string) $fecNac);
        if ($fecNac !== '' && strlen($fecNac) >= 10) {
            $fecNac = substr($fecNac, 0, 10);
        }
    }

    $mailInst = registroNullableFormScalar($row['val_mail_institucional'] ?? null);
    if ($mailInst === 'Sin Correo') {
        $mailInst = '';
    }

    $mailPersona = registroNullableFormScalar($row['mail_persona'] ?? null);
    if ($mailPersona === 'Sin Correo') {
        $mailPersona = '';
    }

    return [
        'id_persona'                => registroFormatNumericField($row['id_persona'] ?? ''),
        'id_tipo_docum'             => registroNullableFormScalar($row['id_tipo_docum'] ?? null),
        'nom_persona'               => registroNullableFormScalar($row['nom_persona'] ?? null),
        'ape_persona'               => registroNullableFormScalar($row['ape_persona'] ?? null),
        'mail_persona'              => $mailPersona,
        'fec_nacimiento'            => $fecNac,
        'ind_genero'                => registroFormatNumericField($row['ind_genero'] ?? ''),
        'id_nivel_estudio'          => registroFormatNumericField($row['id_nivel_estudio'] ?? ''),
        'id_profesion'              => registroNullableFormScalar($row['id_profesion'] ?? null),
        'id_dpto_reside'            => registroNullableFormScalar($row['id_dpto_reside'] ?? null),
        'id_ciudad_reside'          => registroNullableFormScalar($row['id_ciudad_reside'] ?? null),
        'dir_ciudad_reside'         => registroNullableFormScalar($row['dir_ciudad_reside'] ?? null),
        'tel_persona_fijo'          => registroNullableFormScalar($row['tel_persona_fijo'] ?? null),
        'tel_persona_movil'         => registroNullableFormScalar($row['tel_persona_movil'] ?? null),
        'nom_contacto_emergencias'  => registroNullableFormScalar($row['nom_contacto_emergencias'] ?? null),
        'tel_contacto_emergencias'  => registroNullableFormScalar($row['tel_contacto_emergencias'] ?? null),
        'ind_envio_correo'          => filter_var($row['ind_envio_correo'] ?? false, FILTER_VALIDATE_BOOLEAN),
        'ind_etdo_formacion'        => registroFormatNumericField($row['ind_etdo_formacion'] ?? ''),
        'tel_alterno'               => registroNullableFormScalar($row['tel_alterno'] ?? null),
        'tel_sede'                  => registroNullableFormScalar($row['tel_sede'] ?? null),
        'ext_sede'                  => registroNullableFormScalar($row['ext_sede'] ?? null),
        'tel_padre_fijo'            => registroNullableFormScalar($row['tel_padre_fijo'] ?? null),
        'tel_padre_movil'           => registroNullableFormScalar($row['tel_padre_movil'] ?? null),
        'val_mail_institucional'    => $mailInst,
        'id_ficha'                  => registroFormatNumericField($row['id_ficha'] ?? ''),
    ];
}

function registroNullableFormScalar(mixed $value): string
{
    if ($value === null) {
        return '';
    }

    $text = trim((string) $value);

    return $text;
}

function registroFormatNumericField(mixed $value): string
{
    if ($value === null || $value === '') {
        return '';
    }

    if (is_numeric($value)) {
        $num = (float) $value;
        if ($num == (int) $num) {
            return (string) (int) $num;
        }
    }

    return trim((string) $value);
}
