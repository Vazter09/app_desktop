<?php
declare(strict_types=1);

require_once dirname(__DIR__, 3) . '/core/RouterResponse.php';

class PorteriaRouterPayload
{
    /**
     * @return array<string, mixed>
     */
    public static function readJsonBody(): array
    {
        $raw = file_get_contents('php://input');
        if ($raw === false || trim($raw) === '') {
            return [];
        }
        $decoded = json_decode($raw, true);
        if (!is_array($decoded)) {
            RouterResponse::fail('JSON inválido.');
        }

        return $decoded;
    }

    /**
     * @param array<string, mixed> $json
     * @return array<string, mixed>
     */
    public static function ingresoToPost(array $json): array
    {
        return [
            'sel_tipo_doc' => trim((string) ($json['tipo_doc'] ?? 'CC')),
            'txt_documento' => trim((string) ($json['documento'] ?? '')),
            'hid_captura_raw' => trim((string) ($json['captura_raw'] ?? '')),
            'sel_tipo_persona' => (int) ($json['tipo_persona'] ?? 0),
            'txt_nombres' => trim((string) ($json['nombres'] ?? '')),
            'txt_apellidos' => trim((string) ($json['apellidos'] ?? '')),
            'sel_entrada' => (int) ($json['id_entrada'] ?? 0),
            'txt_observaciones' => trim((string) ($json['observaciones'] ?? '')),
            'hid_metodo_aut' => (int) ($json['metodo_aut'] ?? 1),
            'hid_foto_data' => trim((string) ($json['foto_base64'] ?? '')),
        ];
    }

    /**
     * @param array<string, mixed> $json
     * @return array<string, mixed>
     */
    public static function salidaToPost(array $json): array
    {
        return [
            'sel_tipo_doc' => trim((string) ($json['tipo_doc'] ?? 'CC')),
            'txt_documento' => trim((string) ($json['documento'] ?? '')),
            'hid_captura_raw' => trim((string) ($json['captura_raw'] ?? '')),
            'txt_observaciones' => trim((string) ($json['observaciones'] ?? '')),
            'hid_metodo_aut' => (int) ($json['metodo_aut'] ?? 1),
            'hid_foto_data' => trim((string) ($json['foto_base64'] ?? '')),
        ];
    }

    /**
     * @param mixed $value
     */
    private static function toNullableBool(mixed $value): ?bool
    {
        if ($value === null || $value === '') {
            return null;
        }
        if (is_bool($value)) {
            return $value;
        }
        $s = strtolower(trim((string) $value));
        if (in_array($s, ['t', 'true', '1', 'yes'], true)) {
            return true;
        }
        if (in_array($s, ['f', 'false', '0', 'no'], true)) {
            return false;
        }

        return null;
    }

    /**
     * Campos de tab_instructores (NULL si la persona no tiene fila de instructor).
     *
     * @param array<string, mixed> $persona
     * @return array{ind_estado_instructor: ?int, ind_tipo_contrato: ?bool}
     */
    private static function formatCamposInstructor(array $persona): array
    {
        $estado = $persona['ind_estado_instructor'] ?? null;

        return [
            'ind_estado_instructor' => $estado !== null && $estado !== ''
                ? (int) $estado
                : null,
            'ind_tipo_contrato' => self::toNullableBool($persona['ind_tipo_contrato'] ?? null),
        ];
    }

    /**
     * @param array<string, mixed>|null $persona
     * @return array<string, mixed>|null
     */
    public static function formatPersona(?array $persona): ?array
    {
        if ($persona === null) {
            return null;
        }

        return array_merge([
            'id_persona' => (int) ($persona['id_persona'] ?? 0),
            'tipo_doc' => (string) ($persona['id_tipo_docum'] ?? $persona['id_tipo_doc'] ?? ''),
            'documento' => (string) ($persona['id_persona'] ?? ''),
            'nombres' => (string) ($persona['nom_persona'] ?? ''),
            'apellidos' => (string) ($persona['ape_persona'] ?? $persona['apellidos'] ?? ''),
            'tipo_persona' => (int) ($persona['id_tipo_persona'] ?? 0),
            'nom_tipo_persona' => (string) ($persona['nom_tipo_persona'] ?? ''),
        ], self::formatCamposInstructor($persona));
    }

    /**
     * Ficha completa de una persona para el modal de confirmación de
     * biometría facial (2026-07-09) — a diferencia de formatPersona(),
     * expone todos los campos personales asignados en tab_personas más
     * los de aprendiz/ficha/programa cuando aplica (NULL si no aplica).
     *
     * @param array<string, mixed>|null $persona
     * @return array<string, mixed>|null
     */
    public static function formatPersonaCompleta(?array $persona): ?array
    {
        if ($persona === null) {
            return null;
        }

        return array_merge([
            'id_persona' => (int) ($persona['id_persona'] ?? 0),
            'tipo_doc' => (string) ($persona['id_tipo_docum'] ?? ''),
            'nom_tipo_docum' => (string) ($persona['nom_tipo_docum'] ?? ''),
            'documento' => (string) ($persona['id_persona'] ?? ''),
            'nombres' => (string) ($persona['nom_persona'] ?? ''),
            'apellidos' => (string) ($persona['ape_persona'] ?? ''),
            'correo' => (string) ($persona['mail_persona'] ?? ''),
            'fec_nacimiento' => (string) ($persona['fec_nacimiento'] ?? ''),
            'genero' => (int) ($persona['ind_genero'] ?? 99),
            'tel_fijo' => (string) ($persona['tel_persona_fijo'] ?? ''),
            'tel_movil' => (string) ($persona['tel_persona_movil'] ?? ''),
            'direccion' => (string) ($persona['dir_ciudad_reside'] ?? ''),
            'ciudad' => (string) ($persona['nom_ciudad'] ?? ''),
            'departamento' => (string) ($persona['nom_dpto'] ?? ''),
            'contacto_emergencia' => (string) ($persona['nom_contacto_emergencias'] ?? ''),
            'tel_contacto_emergencia' => (string) ($persona['tel_contacto_emergencias'] ?? ''),
            'num_visitas' => (int) ($persona['num_visitas'] ?? 0),
            'fec_ultima_entrada' => (string) ($persona['fec_ultima_entrada'] ?? ''),
            'fec_ultima_salida' => (string) ($persona['fec_ultima_salida'] ?? ''),
            'activo' => (bool) ($persona['ind_estado'] ?? true),
            'tipo_persona' => (int) ($persona['id_tipo_persona'] ?? 0),
            'nom_tipo_persona' => (string) ($persona['nom_tipo_persona'] ?? ''),
            'id_ficha' => isset($persona['id_ficha']) ? (int) $persona['id_ficha'] : null,
            'estado_formacion' => isset($persona['ind_etdo_formacion'])
                ? (int) $persona['ind_etdo_formacion'] : null,
            'num_llamados' => isset($persona['num_llamados']) ? (int) $persona['num_llamados'] : null,
            'id_jornada' => isset($persona['id_jornada']) ? (int) $persona['id_jornada'] : null,
            'ind_modalidad' => isset($persona['ind_modalidad']) ? (int) $persona['ind_modalidad'] : null,
            'id_programa' => isset($persona['id_programa']) ? (int) $persona['id_programa'] : null,
            'nom_programa' => (string) ($persona['nom_programa'] ?? ''),
        ], self::formatCamposInstructor($persona));
    }

    /**
     * @param array<string, mixed>|null $ingreso
     * @return array<string, mixed>|null
     */
    public static function formatIngresoAbierto(?array $ingreso): ?array
    {
        if ($ingreso === null) {
            return null;
        }

        return [
            'id_ingreso' => (int) ($ingreso['id_ingreso'] ?? 0),
            'fec_ingreso' => (string) ($ingreso['fec_ingreso'] ?? ''),
            'id_entrada' => (int) ($ingreso['id_entrada_centro'] ?? 0),
            'nom_entrada' => (string) ($ingreso['nom_entrada_centro'] ?? ''),
            'tipo_persona' => (int) ($ingreso['id_tipo_persona'] ?? 0),
            'nom_tipo_persona' => (string) ($ingreso['nom_tipo_persona'] ?? ''),
            'nombres' => (string) ($ingreso['nom_persona'] ?? ''),
            'apellidos' => (string) ($ingreso['ape_persona'] ?? ''),
        ];
    }
}
