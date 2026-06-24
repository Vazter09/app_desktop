<?php
declare(strict_types=1);

/**
 * Catálogo de reportes SENA (vistas de solo lectura sobre las tablas tab_temp_*).
 * Cada entrada define: tabla origen, columnas a mostrar (key+label), columnas de
 * búsqueda y orden. Los identificadores provienen de aquí (no del usuario), pero
 * reportesFetch() los valida igualmente con whitelist.
 */

/** @return array<string, array<string, mixed>> */
function reportesCatalogo(): array
{
    return [
        'df49' => [
            'titulo' => 'DF-49 · Resumen de fichas',
            'tabla' => 'tab_temp_df49',
            'orden' => 'id_ficha',
            'buscar' => ['id_ficha', 'nom_programa', 'nom_centro'],
            'columnas' => [
                ['key' => 'id_ficha', 'label' => 'Ficha'],
                ['key' => 'nom_programa', 'label' => 'Programa', 'truncate' => 220],
                ['key' => 'nom_centro', 'label' => 'Centro', 'truncate' => 160],
                ['key' => 'num_aprend_matric', 'label' => 'Matric.', 'td_class' => 'py-2 text-end'],
                ['key' => 'num_aprend_certif', 'label' => 'Certif.', 'td_class' => 'py-2 text-end'],
                ['key' => 'num_aprend_sincer', 'label' => 'Sin certif.', 'td_class' => 'py-2 text-end'],
                ['key' => 'num_aprend_sinjui', 'label' => 'Sin juicio', 'td_class' => 'py-2 text-end'],
                ['key' => 'num_aprend_noapro', 'label' => 'No aprob.', 'td_class' => 'py-2 text-end'],
            ],
        ],
        'df51' => [
            'titulo' => 'DF-51 · Aprendices por ruta',
            'tabla' => 'tab_temp_df51',
            'orden' => 'id_ficha',
            'buscar' => ['id_ficha', 'tipo_formacion'],
            'columnas' => [
                ['key' => 'id_ficha', 'label' => 'Ficha'],
                ['key' => 'tipo_formacion', 'label' => 'Tipo formación'],
                ['key' => 'estado_ficha', 'label' => 'Estado'],
                ['key' => 'num_cupo', 'label' => 'Cupo', 'td_class' => 'py-2 text-end'],
                ['key' => 'aprendices_activos', 'label' => 'Activos', 'td_class' => 'py-2 text-end'],
                ['key' => 'activos_con_ruta', 'label' => 'Con ruta', 'td_class' => 'py-2 text-end'],
                ['key' => 'activos_sin_ruta', 'label' => 'Sin ruta', 'td_class' => 'py-2 text-end'],
                ['key' => 'apren_sin_ruta_con_noved', 'label' => 'Sin ruta c/nov.', 'td_class' => 'py-2 text-end'],
            ],
        ],
        'df53' => [
            'titulo' => 'DF-53 · Fichas y empresas',
            'tabla' => 'tab_temp_df53',
            'orden' => 'id_ficha',
            'buscar' => ['id_ficha', 'nombre_programa', 'nom_centro', 'nombre_empresa'],
            'columnas' => [
                ['key' => 'id_ficha', 'label' => 'Ficha'],
                ['key' => 'nombre_programa', 'label' => 'Programa', 'truncate' => 220],
                ['key' => 'nom_centro', 'label' => 'Centro', 'truncate' => 160],
                ['key' => 'tipo_formacion', 'label' => 'Tipo'],
                ['key' => 'estado_ficha', 'label' => 'Estado'],
                ['key' => 'aprendices_activos', 'label' => 'Activos', 'td_class' => 'py-2 text-end'],
                ['key' => 'nombre_empresa', 'label' => 'Empresa', 'truncate' => 200],
            ],
        ],
        'df14a' => [
            'titulo' => 'DF-14A · Estado de fichas',
            'tabla' => 'tab_temp_df14a',
            'orden' => 'id_ficha',
            'buscar' => ['id_ficha', 'nom_programa', 'nom_centro'],
            'columnas' => [
                ['key' => 'id_ficha', 'label' => 'Ficha'],
                ['key' => 'nom_programa', 'label' => 'Programa', 'truncate' => 220],
                ['key' => 'nom_centro', 'label' => 'Centro', 'truncate' => 160],
                ['key' => 'niv_formacion', 'label' => 'Nivel'],
                ['key' => 'num_cupo', 'label' => 'Cupo', 'td_class' => 'py-2 text-end'],
                ['key' => 'estado_ficha', 'label' => 'Estado'],
                ['key' => 'ind_certificado', 'label' => 'Certificados', 'td_class' => 'py-2 text-end'],
                ['key' => 'ind_por_certif', 'label' => 'Por certificar', 'td_class' => 'py-2 text-end'],
            ],
        ],
        'pe04' => [
            'titulo' => 'PE-04 · Fichas detalladas',
            'tabla' => 'tab_temp_pe04',
            'orden' => 'id_ficha',
            'buscar' => ['id_ficha', 'nom_programa', 'nom_empresa'],
            'columnas' => [
                ['key' => 'id_ficha', 'label' => 'Ficha'],
                ['key' => 'nom_programa', 'label' => 'Programa', 'truncate' => 220],
                ['key' => 'nom_nivel_forma', 'label' => 'Nivel'],
                ['key' => 'nom_jornada', 'label' => 'Jornada'],
                ['key' => 'num_tot_aprend', 'label' => 'Aprendices', 'td_class' => 'py-2 text-end'],
                ['key' => 'nom_empresa', 'label' => 'Empresa', 'truncate' => 200],
                ['key' => 'nom_municipio', 'label' => 'Municipio'],
            ],
        ],
        'aprendices' => [
            'titulo' => 'Aprendices (reporte)',
            'tabla' => 'tab_temp_aprendices',
            'orden' => 'ape_aprendiz',
            'buscar' => ['num_documento', 'nom_aprendiz', 'ape_aprendiz', 'id_ficha'],
            'columnas' => [
                ['key' => 'id_ficha', 'label' => 'Ficha'],
                ['key' => 'nom_aprendiz', 'label' => 'Nombres'],
                ['key' => 'ape_aprendiz', 'label' => 'Apellidos'],
                ['key' => 'num_documento', 'label' => 'Documento'],
                ['key' => 'nom_movil', 'label' => 'Celular'],
                ['key' => 'val_correo', 'label' => 'Correo', 'truncate' => 200],
                ['key' => 'ind_estado_aprendiz', 'label' => 'Estado'],
            ],
        ],
        'fichas_creadas' => [
            'titulo' => 'Fichas creadas',
            'tabla' => 'tab_temp_fichas_creadas',
            'orden' => 'cod_ficha',
            'buscar' => ['cod_ficha', 'nom_programa', 'nombre_instructor', 'apellido_instructor'],
            'columnas' => [
                ['key' => 'cod_ficha', 'label' => 'Ficha'],
                ['key' => 'nom_programa', 'label' => 'Programa', 'truncate' => 220],
                ['key' => 'fec_inicio', 'label' => 'Inicio'],
                ['key' => 'fec_fin', 'label' => 'Fin'],
                ['key' => 'estado_ficha', 'label' => 'Estado'],
                ['key' => 'cantidad_aprendices', 'label' => 'Aprendices', 'td_class' => 'py-2 text-end'],
                ['key' => 'nombre_instructor', 'label' => 'Instructor'],
            ],
        ],
        'juicios' => [
            'titulo' => 'Juicios de evaluación',
            'tabla' => 'tab_temp_juicios',
            'orden' => 'id_ficha',
            'buscar' => ['id_ficha', 'num_docume', 'nom_aprendiz', 'ape_aprendiz'],
            'columnas' => [
                ['key' => 'id_ficha', 'label' => 'Ficha'],
                ['key' => 'nom_aprendiz', 'label' => 'Nombres'],
                ['key' => 'ape_aprendiz', 'label' => 'Apellidos'],
                ['key' => 'nom_competencia', 'label' => 'Competencia', 'truncate' => 220],
                ['key' => 'val_juicio', 'label' => 'Juicio'],
                ['key' => 'fec_juicio', 'label' => 'Fecha'],
                ['key' => 'nom_instructor', 'label' => 'Instructor', 'truncate' => 180],
            ],
        ],
    ];
}

/** Devuelve la configuración de un reporte por su clave, o null si no existe. */
function reportesGet(string $key): ?array
{
    $cat = reportesCatalogo();

    return $cat[$key] ?? null;
}
