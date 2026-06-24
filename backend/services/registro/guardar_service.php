<?php
declare(strict_types=1);

require_once __DIR__ . '/registro_persistencia.php';
require_once __DIR__ . '/access.php';

/**
 * @param array<string, mixed> $post
 */
function registroGuardarFormulario(PDO $pdo, string $tipo, array $post): array
{
    global $stmt_fun_actualizar_aprendiz, $stmt_fun_registrar_persona,
        $stmt_fun_registrar_instructor, $stmt_fun_registrar_funcionario,
        $stmt_fun_registrar_contratista;

    $tipo = strtolower(trim($tipo));
    $usr = registroDisplayUsername();

    switch ($tipo) {
        case 'aprendiz':
            $postOrNull = static function (string $key) use ($post): ?string {
                $v = $post[$key] ?? '';
                $v = is_string($v) ? trim($v) : '';
                return $v === '' ? null : $v;
            };

            $params = [
                $post['id_persona'] ?? null,
                $post['id_tipo_docum'] ?? null,
                $post['nom_persona'] ?? null,
                $post['ape_persona'] ?? null,
                $post['mail_persona'] ?? null,
                $post['fec_nacimiento'] ?? null,
                (int) ($post['ind_genero'] ?? 0),
                $post['id_nivel_estudio'] ?? null,
                $post['id_profesion'] ?? null,
                $post['id_dpto_reside'] ?? null,
                $post['id_ciudad_reside'] ?? null,
                $post['dir_ciudad_reside'] ?? null,
                (int) ($post['tel_persona_fijo'] ?? 0),
                (int) ($post['tel_persona_movil'] ?? 0),
                $post['nom_contacto_emergencias'] ?? null,
                (int) ($post['tel_contacto_emergencias'] ?? 0),
                isset($post['ind_envio_correo']) ? 'true' : 'false',
                $postOrNull('tel_alterno') !== null ? (int) $postOrNull('tel_alterno') : null,
                $postOrNull('tel_sede') !== null ? (int) $postOrNull('tel_sede') : null,
                $postOrNull('ext_sede') !== null ? (int) $postOrNull('ext_sede') : null,
                $postOrNull('tel_padre_fijo') !== null ? (int) $postOrNull('tel_padre_fijo') : null,
                $postOrNull('tel_padre_movil') !== null ? (int) $postOrNull('tel_padre_movil') : null,
                $postOrNull('val_mail_institucional'),
                (int) ($post['ind_etdo_formacion'] ?? 0),
                $usr,
                $post['id_ficha'] ?? null,
            ];

            $stmt_fun_actualizar_aprendiz->execute($params);
            $idRegistrado = $stmt_fun_actualizar_aprendiz->fetchColumn();
            if ($idRegistrado === false || trim((string) $idRegistrado) === '') {
                throw new RuntimeException('No se pudo actualizar los datos del aprendiz.');
            }

            return ['message' => 'Datos del aprendiz actualizados correctamente.'];

        case 'persona':
            $stmt_fun_registrar_persona->execute([
                $post['id_persona'] ?? null,
                $post['id_tipo_docum'] ?? null,
                $post['id_tipo_persona'] ?? null,
                $post['nom_persona'] ?? null,
                $post['ape_persona'] ?? null,
                $post['mail_persona'] ?? null,
                $post['fec_nacimiento'] ?? null,
                $post['ind_genero'] ?? null,
                $post['id_nivel_estudio'] ?? null,
                $post['id_profesion'] ?? null,
                $post['id_dpto_reside'] ?? null,
                $post['id_ciudad_reside'] ?? null,
                $post['dir_ciudad_reside'] ?? null,
                $post['tel_persona_fijo'] ?? null,
                $post['tel_persona_movil'] ?? null,
                $post['nom_contacto_emergencias'] ?? null,
                $post['tel_contacto_emergencias'] ?? null,
                isset($post['ind_envio_correo']),
                isset($post['ind_estado']),
                $usr,
            ]);
            $stmt_fun_registrar_persona->fetchColumn();

            return ['message' => 'Persona registrada correctamente.'];

        case 'instructor':
            $stmt_fun_registrar_instructor->execute([
                $post['id_persona'] ?? null,
                $post['id_tipo_docum'] ?? null,
                $post['nom_persona'] ?? null,
                $post['ape_persona'] ?? null,
                $post['mail_persona'] ?? null,
                $post['fec_nacimiento'] ?? null,
                $post['ind_genero'] ?? null,
                $post['ind_est_civil'] ?? null,
                $post['id_nivel_estudio'] ?? null,
                $post['id_profesion'] ?? null,
                $post['id_dpto_reside'] ?? null,
                $post['id_ciudad_reside'] ?? null,
                $post['dir_ciudad_reside'] ?? null,
                $post['tel_persona_fijo'] ?? null,
                $post['tel_persona_movil'] ?? null,
                $post['nom_contacto_emergencias'] ?? null,
                $post['tel_contacto_emergencias'] ?? null,
                isset($post['ind_envio_correo']) ? 'true' : 'false',
                $post['id_centro'] ?? null,
                $post['id_red'] ?? null,
                isset($post['ind_tipo_contrato']) ? 'true' : 'false',
                isset($post['ind_contratado_actual']) ? 'true' : 'false',
                isset($post['ind_disponibilidad']) ? 'true' : 'false',
                $post['ind_estado'] ?? null,
                $usr,
            ]);
            $resultado = (string) $stmt_fun_registrar_instructor->fetchColumn();
            if ($resultado !== 'OK') {
                throw new RuntimeException('No se pudo registrar el instructor.');
            }

            return ['message' => 'Instructor registrado correctamente.'];

        case 'funcionario':
            $idCentro = isset($post['id_centro']) && $post['id_centro'] !== ''
                ? $post['id_centro']
                : null;

            $stmt_fun_registrar_funcionario->execute([
                $post['id_persona'] ?? null,
                $post['id_tipo_docum'] ?? null,
                $post['nom_persona'] ?? null,
                $post['ape_persona'] ?? null,
                $post['mail_persona'] ?? null,
                $post['fec_nacimiento'] ?? null,
                $post['ind_genero'] ?? null,
                $post['id_nivel_estudio'] ?? null,
                $post['id_profesion'] ?? null,
                $post['id_dpto_reside'] ?? null,
                $post['id_ciudad_reside'] ?? null,
                $post['dir_ciudad_reside'] ?? null,
                $post['tel_persona_fijo'] ?? null,
                $post['tel_persona_movil'] ?? null,
                $post['nom_contacto_emergencias'] ?? null,
                $post['tel_contacto_emergencias'] ?? null,
                isset($post['ind_envio_correo']) ? 'true' : 'false',
                $post['id_area'] ?? null,
                $post['id_cargo'] ?? null,
                $post['val_grado'] ?? null,
                $post['fec_ingreso_planta'] ?? null,
                $idCentro,
                $usr,
            ]);
            $resultado = (string) $stmt_fun_registrar_funcionario->fetchColumn();
            if ($resultado !== 'OK') {
                throw new RuntimeException('No se pudo registrar el funcionario.');
            }

            return ['message' => 'Funcionario registrado correctamente.'];

        case 'contratista':
            $stmt_fun_registrar_contratista->execute([
                $post['id_persona'] ?? null,
                $post['id_tipo_docum'] ?? null,
                $post['nom_persona'] ?? null,
                $post['ape_persona'] ?? null,
                $post['mail_persona'] ?? null,
                $post['fec_nacimiento'] ?? null,
                $post['ind_genero'] ?? null,
                $post['id_nivel_estudio'] ?? null,
                $post['id_profesion'] ?? null,
                $post['id_dpto_reside'] ?? null,
                $post['id_ciudad_reside'] ?? null,
                $post['dir_ciudad_reside'] ?? null,
                $post['tel_persona_fijo'] ?? null,
                $post['tel_persona_movil'] ?? null,
                $post['nom_contacto_emergencias'] ?? null,
                $post['tel_contacto_emergencias'] ?? null,
                isset($post['ind_envio_correo']) ? 'true' : 'false',
                $usr,
            ]);
            $stmt_fun_registrar_contratista->fetchColumn();

            return ['message' => 'Contratista registrado correctamente.'];

        default:
            throw new InvalidArgumentException('Tipo de formulario no válido.');
    }
}
