<?php
declare(strict_types=1);

class ApiPayload
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
            ApiResponse::fail('JSON inválido.');
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
     * @param array<string, mixed>|null $persona
     * @return array<string, mixed>|null
     */
    public static function formatPersona(?array $persona): ?array
    {
        if ($persona === null) {
            return null;
        }

        return [
            'id_persona' => (int) ($persona['id_persona'] ?? 0),
            'tipo_doc' => (string) ($persona['id_tipo_docum'] ?? $persona['id_tipo_doc'] ?? ''),
            'documento' => (string) ($persona['id_persona'] ?? ''),
            'nombres' => (string) ($persona['nom_persona'] ?? ''),
            'apellidos' => (string) ($persona['ape_persona'] ?? $persona['apellidos'] ?? ''),
            'tipo_persona' => (int) ($persona['id_tipo_persona'] ?? 0),
            'nom_tipo_persona' => (string) ($persona['nom_tipo_persona'] ?? ''),
        ];
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
